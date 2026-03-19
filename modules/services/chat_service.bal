import ballerina/websocket;
import ballerina/http;
import ballerina/jwt;
import ballegram.chat;

final ConnectionManager connectionManager = new;

type IncomingMessage record {|
    int chatId;
    string content;
|};

service /chat on new websocket:Listener(9091) {

    resource function get . (http:Request req) returns websocket:Service|error {
        // 1. Authenticate
        string|http:HeaderNotFoundError header = req.getHeader("Authorization");
        if header is http:HeaderNotFoundError {
             return error("Missing Authorization header");
        }

        string token = header;
        // Remove "Bearer " prefix if present
        if token.startsWith("Bearer ") {
            token = token.substring(7);
        }

        jwt:ValidatorConfig validatorConfig = {
            issuer: authConfig.jwtIssuer,
            audience: authConfig.jwtAudience,
            signatureConfig: {
                secret: authConfig.jwtSecret
            }
        };

        jwt:Payload|error payload = jwt:validate(token, validatorConfig);

        if payload is error {
            return error("Invalid token: " + payload.message());
        }

        // 2. Extract User ID
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
        // Parse message
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

        // Save message
        chat:Message|error savedMsg = chat:saveMessage(messageDb, msg.chatId, self.userId, msg.content);
        if savedMsg is error {
             check caller->writeMessage("Error: Failed to save message");
             return;
        }

        // Broadcast
        int[]|error participants = chat:getChatParticipants(db, msg.chatId);
        if participants is error {
             check caller->writeMessage("Error: Failed to get participants");
             return;
        }

        connectionManager.broadcast(participants, savedMsg.cloneReadOnly());
    }
}
