import ballerina/http;
import ballerina/log;
import ballerina/sql;

public type DbClient client object {
    isolated remote function query(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns stream<record {}, sql:Error?>;
    isolated remote function execute(sql:ParameterizedQuery sqlQuery) returns sql:ExecutionResult|sql:Error;
};

public type DeviceToken record {|
    int user_id;
    string device_id;
    string token;
    string provider;
|};

// Inserts or updates a device token.
public isolated function registerDeviceToken(DbClient db, int userId, string deviceId, string token, string provider) returns error? {
    sql:ParameterizedQuery query = `
        INSERT INTO device_tokens (user_id, device_id, token, provider)
        VALUES (${userId}, ${deviceId}, ${token}, ${provider})
        ON CONFLICT (user_id, device_id) DO UPDATE
        SET token = EXCLUDED.token, provider = EXCLUDED.provider
    `;
    _ = check db->execute(query);
}

// Retrieves all device tokens for a user.
public isolated function getUserTokens(DbClient db, int userId) returns DeviceToken[]|error {
    sql:ParameterizedQuery query = `
        SELECT user_id, device_id, token, provider
        FROM device_tokens
        WHERE user_id = ${userId}
    `;

    stream<record {}, sql:Error?> resultStream = db->query(query);
    DeviceToken[] tokens = [];

    check from record {} row in resultStream
        do {
            DeviceToken item = check row.cloneWithType(DeviceToken);
            tokens.push(item);
        };

    return tokens;
}

// Unregisters a device token.
public isolated function unregisterDeviceToken(DbClient db, int userId, string deviceId) returns error? {
    sql:ParameterizedQuery query = `
        DELETE FROM device_tokens
        WHERE user_id = ${userId} AND device_id = ${deviceId}
    `;
    _ = check db->execute(query);
}

public type PushProvider isolated client object {
    isolated remote function sendNotification(string token, string title, string body) returns error?;
    isolated remote function routeNotification(string providerStr, string token, string title, string body) returns error?;
};

public isolated client class FCMPushProvider {
    *PushProvider;
    private final http:Client fcmClient;
    private final string projectId;
    private final string accessToken;

    public isolated function init(string projectId, string accessToken) returns error? {
        self.projectId = projectId;
        self.accessToken = accessToken;
        self.fcmClient = check new ("https://fcm.googleapis.com");
    }

    isolated remote function sendNotification(string token, string title, string body) returns error? {
        json payload = {
            "message": {
                "token": token,
                "notification": {
                    "title": title,
                    "body": body
                }
            }
        };

        map<string> headers = {
            "Authorization": "Bearer " + self.accessToken,
            "Content-Type": "application/json"
        };

        string path = "/v1/projects/" + self.projectId + "/messages:send";
        http:Response|http:ClientError response = self.fcmClient->post(path, payload, headers);

        if response is http:Response {
            if response.statusCode == 200 {
                log:printInfo("Successfully sent FCM notification to " + token);
            } else {
                log:printError("Failed to send FCM notification. Status: " + response.statusCode.toString());
                return error("Failed to send FCM notification");
            }
        } else {
            log:printError("Error sending FCM notification", 'error = response);
            return response;
        }
    }

    isolated remote function routeNotification(string providerStr, string token, string title, string body) returns error? {
        return self->sendNotification(token, title, body);
    }
}

public isolated client class APNsPushProvider {
    *PushProvider;
    private final http:Client apnsClient;
    private final string bundleId;
    private final string authToken;

    public isolated function init(string apnsEnvUrl, string bundleId, string authToken) returns error? {
        self.bundleId = bundleId;
        self.authToken = authToken;
        self.apnsClient = check new (apnsEnvUrl);
    }

    isolated remote function sendNotification(string token, string title, string body) returns error? {
        json payload = {
            "aps": {
                "alert": {
                    "title": title,
                    "body": body
                }
            }
        };

        map<string> headers = {
            "authorization": "bearer " + self.authToken,
            "apns-topic": self.bundleId,
            "Content-Type": "application/json"
        };

        string path = "/3/device/" + token;
        http:Response|http:ClientError response = self.apnsClient->post(path, payload, headers);

        if response is http:Response {
            if response.statusCode == 200 {
                log:printInfo("Successfully sent APNs notification to " + token);
            } else {
                log:printError("Failed to send APNs notification. Status: " + response.statusCode.toString());
                return error("Failed to send APNs notification");
            }
        } else {
            log:printError("Error sending APNs notification", 'error = response);
            return response;
        }
    }

    isolated remote function routeNotification(string providerStr, string token, string title, string body) returns error? {
        return self->sendNotification(token, title, body);
    }
}

public isolated client class CompositePushProvider {
    private final PushProvider fcmProvider;
    private final PushProvider apnsProvider;

    public isolated function init(PushProvider fcmProvider, PushProvider apnsProvider) {
        self.fcmProvider = fcmProvider;
        self.apnsProvider = apnsProvider;
    }

    isolated remote function sendNotification(string token, string title, string body) returns error? {
        return error("Use routeNotification for CompositePushProvider");
    }

    isolated remote function routeNotification(string providerStr, string token, string title, string body) returns error? {
        if providerStr == "FCM" {
            return self.fcmProvider->sendNotification(token, title, body);
        } else if providerStr == "APNS" {
            return self.apnsProvider->sendNotification(token, title, body);
        } else {
            return error("Unknown push provider: " + providerStr);
        }
    }
}
