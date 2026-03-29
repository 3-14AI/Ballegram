import ballerina/http;
import ballegram.bot;
import ballegram.common;

final bot:BotManager botManager = new (db);
final bot:WebhookDispatcher webhookDispatcher = new;

service /bot on ep {

    isolated resource function post register(@http:Payload bot:BotRegistrationRequest req) returns bot:BotRegistrationResponse|http:InternalServerError {
        bot:BotRegistrationResponse|error result = botManager.registerBot(req);
        if result is error {
            http:InternalServerError err = {body: result.message()}; return err;
        }
        return result;
    }

    isolated resource function post [string botId]/webhook(@http:Payload bot:BotWebhookRequest req) returns http:Ok|http:NotFound|http:InternalServerError {
        error? err = botManager.setWebhook(botId, req.webhook_url);
        if err is common:NotFoundError {
            return http:NOT_FOUND;
        } else if err is error {
            http:InternalServerError ie = {body: err.message()}; return ie;
        }
        return http:OK;
    }

    // Endpoint for testing webhook dispatch directly
    isolated resource function post [string botId]/dispatch(@http:Payload bot:BotUpdate payload) returns http:Ok|http:NotFound|http:InternalServerError {
        bot:Bot|error botRec = botManager.getBotById(botId);
        if botRec is common:NotFoundError {
            return http:NOT_FOUND;
        } else if botRec is error {
            http:InternalServerError dbErr = {body: botRec.message()}; return dbErr;
        }

        if botRec is error { return http:INTERNAL_SERVER_ERROR; }
        bot:Bot b = <bot:Bot>botRec;
        string? url = b.webhook_url;
        if url is () {
            http:InternalServerError ie3 = {body: "Webhook URL not set for this bot"}; return ie3;
        }

        error? dispatchErr = webhookDispatcher.dispatch(url, payload);
        if dispatchErr is error {
            http:InternalServerError dispErr = {body: dispatchErr.message()}; return dispErr;
        }

        return http:OK;
    }
}
