import ballerina/test;
import ballerina/websocket;
import ballerina/jwt;
import ballerina/time;
import ballegram.chat;

@test:Mock { moduleName: "ballegram.chat", functionName: "saveMessage" }
isolated function mockSaveMessage(chat:MessageStoreClient db, int chatId, int senderId, string content) returns chat:Message|error {
    return {
        id: 1,
        chat_id: chatId,
        sender_id: senderId,
        content: content,
        created_at: time:utcNow()
    };
}

@test:Mock { moduleName: "ballegram.chat", functionName: "getChatParticipants" }
isolated function mockGetChatParticipants(chat:DbClient db, int chatId) returns int[]|error {
    // Return the user ID 999 which our mock JWT token uses, so the message is broadcasted to us.
    return [999];
}

@test:Config {}
function testWebSocketChatService() returns error? {
    // Generate valid JWT token for auth
    jwt:IssuerConfig issuerConfig = {
        issuer: authConfig.jwtIssuer,
        audience: authConfig.jwtAudience,
        expTime: authConfig.jwtExpTime,
        customClaims: { "uid": 999 },
        signatureConfig: {
            algorithm: jwt:HS256,
            config: authConfig.jwtSecret
        }
    };
    string token = check jwt:issue(issuerConfig);

    // Attempt to connect to the websocket listener which is on 9091
    websocket:Client wsClient = check new("ws://localhost:9091/chat", {
        customHeaders: {
            "Authorization": "Bearer " + token
        }
    });

    // Send a message
    string payload = "{\"chatId\": 1, \"content\": \"Hello WS!\"}";
    check wsClient->writeMessage(payload);

    // Wait and read the echoed message
    string message = check wsClient->readMessage();

    test:assertTrue(message.includes("Hello WS!"), msg = "Message content should match what was sent");

    // Close the connection properly so the listener thread doesn't hang the test JVM
    check wsClient->close();
}
