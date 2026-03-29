import ballerina/sql;

public type DbClient client object {
    isolated remote function queryRow(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns record {}|sql:Error;
    isolated remote function query(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns stream<record {}, sql:Error?>;
};

# Creates a new chat.
#
# + db - The database client
# + participantIds - The list of user IDs to include in the chat
# + chatType - The type of chat (DIRECT or GROUP)
# + name - The name of the chat (optional, for groups)
# + return - The created Chat or error
public isolated function createChat(DbClient db, int[] participantIds, ChatType chatType, string? name = ()) returns Chat|error {
    if participantIds.length() == 0 {
        return error("At least one participant is required");
    }

    // Use CTE to insert chat and participants atomically
    sql:ParameterizedQuery query = `
        WITH new_chat AS (
            INSERT INTO chats (name, type)
            VALUES (${name}, ${chatType})
            RETURNING id, name, type, created_at
        ),
        ins_parts AS (
            INSERT INTO chat_participants (chat_id, user_id)
            SELECT id, unnest(${participantIds}) FROM new_chat
        )
        SELECT * FROM new_chat
    `;

    record {} result = check db->queryRow(query);
    return result.cloneWithType(Chat);
}

# Saves a new message in the NoSQL database.
#
# + db - The message store client
# + chatId - The chat ID
# + senderId - The sender's user ID
# + content - The message content
# + return - The created Message or error
public isolated function saveMessage(MessageStoreClient db, int chatId, int senderId, string content) returns Message|error {
    if content.length() > 4000 {
        return error("Message content exceeds 4000 characters limit");
    }
    return db->saveMessage(chatId, senderId, content);
}

# Retrieves chat history from the NoSQL database.
#
# + db - The message store client
# + chatId - The chat ID
# + return - A stream of Messages or error
public isolated function getChatHistory(MessageStoreClient db, int chatId) returns stream<Message, error?>|error {
    return db->getChatHistory(chatId);
}

# Retrieves the list of participants in a chat.
#
# + db - The database client
# + chatId - The chat ID
# + return - A list of user IDs or error
public isolated function getChatParticipants(DbClient db, int chatId) returns int[]|error {
    sql:ParameterizedQuery query = `
        SELECT user_id
        FROM chat_participants
        WHERE chat_id = ${chatId}
    `;

    stream<record {}, sql:Error?> resultStream = db->query(query);
    int[] participantIds = [];

    check from record {} row in resultStream
        do {
            record {| int user_id; |} item = check row.cloneWithType();
            participantIds.push(item.user_id);
        };

    return participantIds;
}

# Retrieves missed chat messages from the NoSQL database.
#
# + db - The message store client
# + chatId - The chat ID
# + lastMessageId - The last known message ID
# + return - A stream of Messages or error
public isolated function getMissedMessages(MessageStoreClient db, int chatId, int lastMessageId) returns stream<Message, error?>|error {
    return db->getMessagesSince(chatId, lastMessageId);
}

# Edits a message in the NoSQL database.
#
# + db - The message store client
# + messageId - The message ID
# + chatId - The chat ID
# + senderId - The sender's user ID
# + content - The new message content
# + version - The current version of the message
# + return - The updated Message or error
public isolated function editMessage(MessageStoreClient db, int messageId, int chatId, int senderId, string content, int version) returns Message|error {
    if content.length() > 4000 {
        return error("Message content exceeds 4000 characters limit");
    }
    return db->editMessage(messageId, chatId, senderId, content, version);
}

# Marks a message as read in the NoSQL database.
#
# + db - The message store client
# + messageId - The message ID
# + userId - The user ID who read the message
# + chatType - The type of chat (DIRECT or GROUP)
# + return - The updated Message or error
public isolated function markMessageAsRead(MessageStoreClient db, int messageId, int userId, ChatType chatType) returns Message|error {
    return db->markMessageAsRead(messageId, userId, chatType);
}

# Retrieves a chat by its ID.
#
# + db - The database client
# + chatId - The chat ID
# + return - The Chat or error
public isolated function getChat(DbClient db, int chatId) returns Chat|error {
    sql:ParameterizedQuery query = `
        SELECT id, name, type, created_at
        FROM chats
        WHERE id = ${chatId}
    `;

    record {} result = check db->queryRow(query);
    return result.cloneWithType(Chat);
}
