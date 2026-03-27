import ballerina/http;
import ballerina/jwt;
import ballegram.chat;
import ballegram.auth;

service /chat on ep {

    isolated resource function get [int chatId]/messages/since/[int lastMessageId](http:Request req) returns chat:Message[]|http:Unauthorized|http:InternalServerError|http:Forbidden {
        string|http:HeaderNotFoundError header = req.getHeader("Authorization");
        if header is http:HeaderNotFoundError {
            return <http:Unauthorized> { body: "Missing Authorization header" };
        }

        string token = header;
        if token.startsWith("Bearer ") {
            token = token.substring(7);
        }

        jwt:ValidatorConfig validatorConfig = auth:getJwtValidatorConfig(authConfig);
        jwt:Payload|error payload = jwt:validate(token, validatorConfig);
        if payload is error {
            return <http:Unauthorized> { body: "Invalid token: " + payload.message() };
        }

        var uid = payload["uid"];
        int userId;
        if uid is int {
            userId = uid;
        } else {
            return <http:Unauthorized> { body: "Invalid user ID in token" };
        }

        // Verify user is a participant of the chat
        int[]|error participants = chat:getChatParticipants(db, chatId);
        if participants is error {
            return <http:InternalServerError> { body: "Failed to verify participants" };
        }

        boolean isParticipant = false;
        foreach int p in participants {
            if p == userId {
                isParticipant = true;
                break;
            }
        }

        if !isParticipant {
            return <http:Forbidden> { body: "Not a participant of this chat" };
        }

        stream<chat:Message, error?>|error messageStream = chat:getMissedMessages(messageDb, chatId, lastMessageId);
        if messageStream is error {
            return <http:InternalServerError> { body: "Failed to retrieve messages: " + messageStream.message() };
        }

        chat:Message[] messages = [];
        error? e = from chat:Message msg in messageStream do {
            messages.push(msg);
        };

        if e is error {
            return <http:InternalServerError> { body: "Failed to process message stream" };
        }

        return messages;
    }
}
