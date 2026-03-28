import ballerina/http;
import ballerina/jwt;
import ballegram.push;
import ballerina/log;

type DeviceTokenRequest record {|
    string deviceId;
    string token;
    string provider;
|};

type UnregisterDeviceRequest record {|
    string deviceId;
|};

service /push on ep {

    isolated resource function post register(http:Request req, @http:Payload DeviceTokenRequest payload) returns http:Response|error {
        string|http:HeaderNotFoundError header = req.getHeader("Authorization");
        if header is http:HeaderNotFoundError {
            return error("Missing Authorization header");
        }
        string tokenStr = header;
        if tokenStr.startsWith("Bearer ") {
            tokenStr = tokenStr.substring(7);
        }

        jwt:ValidatorConfig validatorConfig = {
            issuer: authConfig.jwtIssuer,
            audience: authConfig.jwtAudience,
            signatureConfig: { secret: authConfig.jwtSecret }
        };
        jwt:Payload|error jwtPayload = jwt:validate(tokenStr, validatorConfig);
        if jwtPayload is error {
            return error("Invalid token: " + jwtPayload.message());
        }

        var uid = jwtPayload["uid"];
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

        error? result = push:registerDeviceToken(db, userId, payload.deviceId, payload.token, payload.provider);
        if result is error {
            log:printError("Error registering device token", 'error = result);
            return error("Internal server error");
        }

        http:Response res = new;
        res.statusCode = 200;
        res.setJsonPayload({ "status": "success" });
        return res;
    }

    isolated resource function post unregister(http:Request req, @http:Payload UnregisterDeviceRequest payload) returns http:Response|error {
        string|http:HeaderNotFoundError header = req.getHeader("Authorization");
        if header is http:HeaderNotFoundError {
            return error("Missing Authorization header");
        }
        string tokenStr = header;
        if tokenStr.startsWith("Bearer ") {
            tokenStr = tokenStr.substring(7);
        }

        jwt:ValidatorConfig validatorConfig = {
            issuer: authConfig.jwtIssuer,
            audience: authConfig.jwtAudience,
            signatureConfig: { secret: authConfig.jwtSecret }
        };
        jwt:Payload|error jwtPayload = jwt:validate(tokenStr, validatorConfig);
        if jwtPayload is error {
            return error("Invalid token: " + jwtPayload.message());
        }

        var uid = jwtPayload["uid"];
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

        error? result = push:unregisterDeviceToken(db, userId, payload.deviceId);
        if result is error {
            log:printError("Error unregistering device token", 'error = result);
            return error("Internal server error");
        }

        http:Response res = new;
        res.statusCode = 200;
        res.setJsonPayload({ "status": "success" });
        return res;
    }
}
