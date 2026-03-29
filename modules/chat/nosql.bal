import ballerina/http;
import ballerina/time;

public type MessageStoreClient isolated client object {
    isolated remote function saveMessage(int chatId, int senderId, string content) returns Message|error;
    isolated remote function getChatHistory(int chatId) returns stream<Message, error?>|error;
    isolated remote function markMessageAsRead(int messageId, int userId, ChatType chatType) returns Message|error;
    isolated remote function editMessage(int messageId, int chatId, int senderId, string content, int version) returns Message|error;
    isolated remote function getMessagesSince(int chatId, int lastMessageId) returns stream<Message, error?>|error;
    isolated remote function deleteOldMessages(int retentionSeconds) returns error?;
};

public isolated client class OpenSearchMessageClient {
    *MessageStoreClient;

    private final http:Client osHttp;
    private final string indexName = "messages";

    public isolated function init(string url, string username, string password) returns error? {
        self.osHttp = check new(url, {
            auth: {
                username: username,
                password: password
            },
            secureSocket: {
                enable: false
            }
        });

        // Ensure index exists
        http:Response|error resp = self.osHttp->head("/" + self.indexName);
        if resp is http:Response && resp.statusCode == 404 {
            json mapping = {
                "mappings": {
                    "properties": {
                        "id": { "type": "long" },
                        "chat_id": { "type": "long" },
                        "sender_id": { "type": "long" },
                        "content": { "type": "text" },
                        "created_at_0": { "type": "long" },
                        "created_at_1": { "type": "double" }
                    }
                }
            };
            http:Response putRes = check self.osHttp->put("/" + self.indexName, mapping);
        }
    }

    isolated remote function saveMessage(int chatId, int senderId, string content) returns Message|error {
        time:Utc now = time:utcNow();
        int timestampInt = now[0];
        int fractionInt = <int>(now[1] * 1000000.0d);
        // Generate pseudo-unique int ID for the message
        int messageId = timestampInt % 1000000 * 1000000 + fractionInt;

        Message msg = {
            id: messageId,
            chat_id: chatId,
            sender_id: senderId,
            content: content,
            created_at: now
        };

        // Convert Utc array to a map for JSON serialization
        map<json> doc = {
            "id": messageId,
            "chat_id": chatId,
            "sender_id": senderId,
            "content": content,
            "created_at_0": now[0],
            "created_at_1": now[1]
        };

        http:Response postRes = check self.osHttp->post("/" + self.indexName + "/_doc/" + messageId.toString(), doc);

        return msg;
    }

    isolated remote function getChatHistory(int chatId) returns stream<Message, error?>|error {
        json queryPayload = {
            "size": 1000,
            "query": {
                "term": {
                    "chat_id": chatId
                }
            },
            "sort": [
                { "created_at_0": { "order": "asc" } },
                { "created_at_1": { "order": "asc" } }
            ]
        };

        http:Response resp = check self.osHttp->post("/" + self.indexName + "/_search", queryPayload);
        json resJson = check resp.getJsonPayload();

        Message[] messages = [];

        json hitsWrapper = check resJson.hits;
        json[] hitsArray = check hitsWrapper.hits.ensureType();

        foreach json hit in hitsArray {
            map<json> hitMap = check hit.ensureType();
            map<json> src = check hitMap["_source"].ensureType();

            int id = check int:fromString(src["id"].toString());
            int cId = check int:fromString(src["chat_id"].toString());
            int? sId = ();
            if src["sender_id"] != () {
                sId = check int:fromString(src["sender_id"].toString());
            }
            string content = src["content"].toString();

            int t0 = check int:fromString(src["created_at_0"].toString());
            decimal t1 = check decimal:fromString(src["created_at_1"].toString());
            time:Utc createdAt = [t0, t1];

            messages.push({
                id: id,
                chat_id: cId,
                sender_id: sId,
                content: content,
                created_at: createdAt
            });
        }

        return new stream<Message, error?>(new MessageStream(messages.cloneReadOnly()));
    }

    isolated remote function getMessagesSince(int chatId, int lastMessageId) returns stream<Message, error?>|error {
        json queryPayload = {
            "size": 1000,
            "query": {
                "bool": {
                    "must": [
                        { "term": { "chat_id": chatId } },
                        { "range": { "id": { "gt": lastMessageId } } }
                    ]
                }
            },
            "sort": [
                { "created_at_0": { "order": "asc" } },
                { "created_at_1": { "order": "asc" } }
            ]
        };

        http:Response resp = check self.osHttp->post("/" + self.indexName + "/_search", queryPayload);
        json resJson = check resp.getJsonPayload();

        Message[] messages = [];

        json hitsWrapper = check resJson.hits;
        json[] hitsArray = check hitsWrapper.hits.ensureType();

        foreach json hit in hitsArray {
            map<json> hitMap = check hit.ensureType();
            map<json> src = check hitMap["_source"].ensureType();

            int id = check int:fromString(src["id"].toString());
            int cId = check int:fromString(src["chat_id"].toString());
            int? sId = ();
            if src["sender_id"] != () {
                sId = check int:fromString(src["sender_id"].toString());
            }
            string content = src["content"].toString();

            int t0 = check int:fromString(src["created_at_0"].toString());
            decimal t1 = check decimal:fromString(src["created_at_1"].toString());
            time:Utc createdAt = [t0, t1];

            messages.push({
                id: id,
                chat_id: cId,
                sender_id: sId,
                content: content,
                created_at: createdAt
            });
        }

        return new stream<Message, error?>(new MessageStream(messages.cloneReadOnly()));
    }

    isolated remote function markMessageAsRead(int messageId, int userId, ChatType chatType) returns Message|error {
        json getQueryPayload = {"query": {"term": {"id": messageId}}};
        http:Response getResp = check self.osHttp->post("/" + self.indexName + "/_search", getQueryPayload);
        json resJson = check getResp.getJsonPayload();
        json hitsWrapper = check resJson.hits;
        json[] hitsArray = check hitsWrapper.hits.ensureType();
        if hitsArray.length() == 0 {
            return error("Message not found");
        }
        map<json> hitMap = check hitsArray[0].ensureType();
        map<json> src = check hitMap["_source"].ensureType();

        int[] currentReadBy = [];
        if src.hasKey("read_by") {
            json[] rb = check src["read_by"].ensureType();
            foreach json rbVal in rb {
                currentReadBy.push(check int:fromString(rbVal.toString()));
            }
        }

        int currentReadCount = 0;
        if src.hasKey("read_count") {
             currentReadCount = check int:fromString(src["read_count"].toString());
        }

        boolean currentIsRead = false;
        if src.hasKey("is_read") {
            currentIsRead = check boolean:fromString(src["is_read"].toString());
        }

        foreach int rb in currentReadBy {
            if rb == userId {
                return error("Already read");
            }
        }

        int newReadCount = currentReadCount + 1;
        currentReadBy.push(userId);
        boolean newIsRead = currentIsRead;

        if chatType == DIRECT {
             newIsRead = true;
        } else if chatType == GROUP && newReadCount >= 3 {
             newIsRead = true;
        }

        map<json> doc = {"doc": {"read_by": currentReadBy, "read_count": newReadCount, "is_read": newIsRead}};
        string docId = hitMap["_id"].toString();
        http:Response postRes = check self.osHttp->post("/" + self.indexName + "/_update/" + docId, doc);

        int cId = check int:fromString(src["chat_id"].toString());
        int? sId = ();
        if src["sender_id"] != () {
            sId = check int:fromString(src["sender_id"].toString());
        }
        string content_val = src["content"].toString();
        int t0 = check int:fromString(src["created_at_0"].toString());
        decimal t1 = check decimal:fromString(src["created_at_1"].toString());
        time:Utc createdAt = [t0, t1];
        int ver = 1;
        if src.hasKey("version") {
            ver = check int:fromString(src["version"].toString());
        }

        Message msg = {
            id: messageId,
            chat_id: cId,
            sender_id: sId,
            content: content_val,
            created_at: createdAt,
            version: ver,
            read_by: currentReadBy,
            read_count: newReadCount,
            is_read: newIsRead
        };
        return msg;
    }

    isolated remote function editMessage(int messageId, int chatId, int senderId, string content, int version) returns Message|error {
        json getQueryPayload = {
            "query": {
                "term": {
                    "id": messageId
                }
            }
        };

        http:Response getResp = check self.osHttp->post("/" + self.indexName + "/_search", getQueryPayload);
        json resJson = check getResp.getJsonPayload();

        json hitsWrapper = check resJson.hits;
        json[] hitsArray = check hitsWrapper.hits.ensureType();

        if hitsArray.length() == 0 {
            return error("Message not found");
        }

        map<json> hitMap = check hitsArray[0].ensureType();
        map<json> src = check hitMap["_source"].ensureType();

        int currentVersion = 1;
        if src.hasKey("version") {
            currentVersion = check int:fromString(src["version"].toString());
        }

        if currentVersion > version {
            return error("Message version conflict");
        }

        int sId = check int:fromString(src["sender_id"].toString());
        if sId != senderId {
            return error("Unauthorized");
        }

        int cId = check int:fromString(src["chat_id"].toString());
        if cId != chatId {
            return error("Chat ID mismatch");
        }

        int t0 = check int:fromString(src["created_at_0"].toString());
        decimal t1 = check decimal:fromString(src["created_at_1"].toString());
        time:Utc createdAt = [t0, t1];

        int newVersion = currentVersion + 1;

        map<json> doc = {
            "doc": {
                "content": content,
                "version": newVersion
            }
        };

        string docId = hitMap["_id"].toString();
        http:Response postRes = check self.osHttp->post("/" + self.indexName + "/_update/" + docId, doc);

        Message msg = {
            id: messageId,
            chat_id: chatId,
            sender_id: senderId,
            content: content,
            created_at: createdAt,
            version: newVersion
        };

        return msg;
    }

    isolated remote function deleteOldMessages(int retentionSeconds) returns error? {
        time:Utc now = time:utcNow();
        int currentTimestamp = now[0];
        int targetTimestamp = currentTimestamp - retentionSeconds;

        json queryPayload = {
            "query": {
                "range": {
                    "created_at_0": {
                        "lt": targetTimestamp
                    }
                }
            }
        };

        http:Response resp = check self.osHttp->post("/" + self.indexName + "/_delete_by_query", queryPayload);
        if resp.statusCode >= 400 {
            string payload = check resp.getTextPayload();
            return error("Failed to delete old messages: " + payload);
        }
    }
}

public isolated class MessageStream {
    private final Message[] & readonly messages;
    private int index = 0;

    public isolated function init(Message[] & readonly messages) {
        self.messages = messages;
    }

    public isolated function next() returns record {| Message value; |}|error? {
        Message? m = ();
        lock {
            if self.index < self.messages.length() {
                m = self.messages[self.index];
                self.index += 1;
            }
        }
        if m is Message {
            return { value: m };
        }
        return ();
    }
}
