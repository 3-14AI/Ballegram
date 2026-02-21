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

# Saves a new message.
#
# + db - The database client
# + chatId - The chat ID
# + senderId - The sender's user ID
# + content - The message content
# + return - The created Message or error
public isolated function saveMessage(DbClient db, int chatId, int senderId, string content) returns Message|error {
    sql:ParameterizedQuery query = `
        INSERT INTO messages (chat_id, sender_id, content)
        VALUES (${chatId}, ${senderId}, ${content})
        RETURNING id, chat_id, sender_id, content, created_at
    `;

    record {} result = check db->queryRow(query);
    return result.cloneWithType(Message);
}

# Retrieves chat history.
#
# + db - The database client
# + chatId - The chat ID
# + return - A stream of Messages or error
public isolated function getChatHistory(DbClient db, int chatId) returns stream<Message, error?> {
    sql:ParameterizedQuery query = `
        SELECT id, chat_id, sender_id, content, created_at
        FROM messages
        WHERE chat_id = ${chatId}
        ORDER BY created_at ASC
    `;

    // We pass the typedesc to the query method to hint the return type implementation
    stream<record {}, sql:Error?> result = db->query(query, Message);

    // Cast to the expected stream type
    return <stream<Message, error?>>result;
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
