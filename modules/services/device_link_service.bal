import ballerina/http;
import ballerina/websocket;
import ballerina/jwt;
import ballerina/uuid;
import ballegram.devices;
import ballegram.auth;

type InitMessage record {|
    string action; // Should be "INIT"
    string publicKey;
|};

type ApprovePayload record {|
    string encryptedPayload;
|};

// WebSocket Service for New Devices to listen for approval
service /devices/link on new websocket:Listener(9093) {
    resource function get . () returns websocket:Service {
        return new DeviceLinkWsService();
    }
}

service class DeviceLinkWsService {
    *websocket:Service;

    remote function onMessage(websocket:Caller caller, string text) returns error? {
        json|error payload = text.fromJsonString();
        if payload is error {
            check caller->writeMessage("Error: Invalid JSON");
            return;
        }

        InitMessage|error msg = payload.cloneWithType(InitMessage);
        if msg is error {
            check caller->writeMessage("Error: Invalid message format");
            return;
        }

        if msg.action == "INIT" {
            string linkId = uuid:createType4AsString();
            devices:linkManager.addSession(linkId, msg.publicKey, caller);

            json response = {
                action: "INIT_SUCCESS",
                linkId: linkId
            };
            check caller->writeMessage(response.toString());
        } else {
            check caller->writeMessage("Error: Unknown action");
        }
    }

    remote function onClose(websocket:Caller caller, int statusCode, string reason) returns error? {
        devices:linkManager.removeSessionByCaller(caller);
    }
}


// HTTP API Service for Existing Authenticated Devices to approve links
service /devices on ep {

    isolated resource function get link/info/[string linkId](http:Request req) returns json|http:Unauthorized|http:NotFound {
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
            return <http:Unauthorized> { body: "Invalid token" };
        }

        string? publicKey = devices:linkManager.getPublicKey(linkId);
        if publicKey is () {
            return <http:NotFound> { body: "Link request not found" };
        }

        return { publicKey: publicKey };
    }

    isolated resource function post link/approve/[string linkId](http:Request req, @http:Payload ApprovePayload approvePayload) returns http:Ok|http:Unauthorized|http:NotFound|http:InternalServerError {
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
            return <http:Unauthorized> { body: "Invalid token" };
        }

        websocket:Caller? caller = devices:linkManager.getCaller(linkId);
        if caller is () {
            return <http:NotFound> { body: "Link request not found or disconnected" };
        }

        json approvedMessage = {
            action: "APPROVED",
            payload: approvePayload.encryptedPayload
        };

        error? sendErr = caller->writeMessage(approvedMessage.toString());
        if sendErr is error {
            return <http:InternalServerError> { body: "Failed to send payload to new device" };
        }

        devices:linkManager.removeSession(linkId);

        return <http:Ok> { body: "Linked successfully" };
    }
}
