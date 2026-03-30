import ballerina/http;
import ballerina/sql;
import ballerina/uuid;
import ballegram.common;

public type Bot record {|
    string id;
    string name;
    string token;
    string? webhook_url;
|};

public type BotRegistrationRequest record {|
    string name;
|};

public type BotRegistrationResponse record {|
    string id;
    string name;
    string token;
|};

public type BotWebhookRequest record {|
    string webhook_url;
|};

public type BotMessageRequest record {|
    string chat_id;
    string content;
|};

public type BotUpdate record {|
    string id;
    string action;
    record {} payload;
|};


public type MockableDatabase isolated client object {
    isolated remote function queryRow(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns record {}|sql:Error;
    isolated remote function query(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns stream<record {}, sql:Error?>;
    isolated remote function execute(sql:ParameterizedQuery sqlQuery) returns sql:ExecutionResult|sql:Error;
};

public isolated class BotManager {
    private final MockableDatabase dbClient;

    public isolated function init(MockableDatabase dbClient) {
        self.dbClient = dbClient;
    }

    public isolated function registerBot(BotRegistrationRequest req) returns BotRegistrationResponse|error {
        string newId = uuid:createType4AsString();
        string newToken = uuid:createType4AsString() + "-" + uuid:createType4AsString(); // Simple token generator

        sql:ParameterizedQuery query = `
            INSERT INTO bots (id, name, token)
            VALUES (${newId}, ${req.name}, ${newToken})
        `;

        _ = check self.dbClient->queryRow(query);

        return {
            id: newId,
            name: req.name,
            token: newToken
        };
    }

    public isolated function setWebhook(string botId, string webhookUrl) returns error? {
        sql:ParameterizedQuery query = `
            UPDATE bots SET webhook_url = ${webhookUrl} WHERE id = ${botId} RETURNING id
        `;

        record{}|sql:Error result = self.dbClient->queryRow(query);
        if result is sql:NoRowsError {
            return error common:NotFoundError("Bot not found");
        } else if result is sql:Error {
            return error common:DatabaseError(result.message());
        }
    }

    public isolated function getBotByToken(string token) returns Bot|error {
        sql:ParameterizedQuery query = `
            SELECT id, name, token, webhook_url FROM bots WHERE token = ${token}
        `;

        record {}|sql:Error result = self.dbClient->queryRow(query, Bot);
        if result is sql:NoRowsError {
            return error common:NotFoundError("Invalid bot token");
        } else if result is sql:Error {
            return error common:DatabaseError(result.message());
        }
        if result is sql:Error { return result; } return result.cloneWithType(Bot);
    }

    public isolated function getBotById(string botId) returns Bot|error {
        sql:ParameterizedQuery query = `
            SELECT id, name, token, webhook_url FROM bots WHERE id = ${botId}
        `;

        record {}|sql:Error result = self.dbClient->queryRow(query, Bot);
        if result is sql:NoRowsError {
            return error common:NotFoundError("Bot not found");
        } else if result is sql:Error {
            return error common:DatabaseError(result.message());
        }
        if result is sql:Error { return result; } return result.cloneWithType(Bot);
    }
}

public isolated class WebhookDispatcher {
    public isolated function dispatch(string webhookUrl, BotUpdate payload) returns error? {
        http:Client webhookClient = check new (webhookUrl);
        http:Response|error res = webhookClient->post("", payload);
        if res is error {
            return error("Failed to dispatch webhook to " + webhookUrl + ": " + res.message());
        }
    }
}
