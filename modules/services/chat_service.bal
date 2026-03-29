import ballerina/websocket;
import ballerina/http;
import ballerina/jwt;
import ballegram.chat;

final ConnectionManager connectionManager = new;

type IncomingMessage record {|
    int chatId;
    string content;
    boolean is_encrypted = false;
|};

public type ChatEvent record {|
    string eventType;
    int[] participants;
    chat:Message payload;
|};

service /chat on new websocket:Listener(9091) {

    resource function get . (http:Request req) returns websocket:Service|error {
        string|http:HeaderNotFoundError header = req.getHeader("Authorization");
        if header is http:HeaderNotFoundError {
             return error("Missing Authorization header");
        }
        string token = header;
        if token.startsWith("Bearer ") {
            token = token.substring(7);
        }
        jwt:ValidatorConfig validatorConfig = {
            issuer: authConfig.jwtIssuer,
            audience: authConfig.jwtAudience,
            signatureConfig: { secret: authConfig.jwtSecret }
        };
        jwt:Payload|error payload = jwt:validate(token, validatorConfig);
        if payload is error {
            return error("Invalid token: " + payload.message());
        }
        var uid = payload["uid"];
        int userId;
        if uid is int {
             userId = uid;
        } else if uid is float {
             userId = <int>uid;
        } else if uid is decimal {
             userId = <int>uid;
        } else {
             return error("Invalid user ID in token");
        }
        return new ChatService(userId);
    }
}

service class ChatService {
    *websocket:Service;
    private final int userId;

    public isolated function init(int userId) {
        self.userId = userId;
    }

    remote function onOpen(websocket:Caller caller) returns error? {
        connectionManager.addConnection(self.userId, caller);
    }

    remote function onClose(websocket:Caller caller, int statusCode, string reason) returns error? {
        connectionManager.removeConnection(self.userId, caller);
    }

    remote function onMessage(websocket:Caller caller, string text) returns error? {
        json|error jsonVal = text.fromJsonString();
        if jsonVal is error {
             check caller->writeMessage("Error: Invalid JSON");
             return;
        }
        IncomingMessage|error msg = jsonVal.cloneWithType(IncomingMessage);
        if msg is error {
             check caller->writeMessage("Error: Invalid message format");
             return;
        }
        chat:Message|error savedMsg = chat:saveMessage(messageDb, msg.chatId, self.userId, msg.content, msg.is_encrypted);
        if savedMsg is error {
             check caller->writeMessage("Error: Failed to save message");
             return;
        }
        int[]|error participants = chat:getChatParticipants(db, msg.chatId);
        if participants is error {
             check caller->writeMessage("Error: Failed to get participants");
             return;
        }

        ChatEvent event = {
            eventType: "NEW_MESSAGE",
            participants: participants,
            payload: savedMsg
        };
        json eventJson = event.toJson();
        byte[] msgBytes = eventJson.toString().toBytes();

        error? pubErr = eventBroker.publishEvent("events", msgBytes);
        if pubErr is error {
            // fallback if broker is down
            connectionManager.broadcast(participants, savedMsg.cloneReadOnly());
        }
    }
}
