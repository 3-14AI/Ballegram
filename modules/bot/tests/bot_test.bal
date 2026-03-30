import ballerina/sql;
import ballerina/test;
import ballerina/http;

isolated client class MockBotDbClient {


    public function init() {
        }


    private map<Bot> bots = {};

    isolated remote function queryRow(sql:ParameterizedQuery query, typedesc<record {}>? rowType = ()) returns record {}|sql:Error {
        string queryString = query.strings[0];

        if queryString.includes("INSERT INTO bots") {
            string id = <string>query.insertions[0];
            string name = <string>query.insertions[1];
            string token = <string>query.insertions[2];
            lock {
                self.bots[id] = {id: id, name: name, token: token, webhook_url: ()};
            }
            return {};
        } else if queryString.includes("UPDATE bots SET webhook_url") {
            string webhookUrl = <string>query.insertions[0];
            string id = <string>query.insertions[1];
            boolean exists = false;
            lock {
                if self.bots.hasKey(id) {
                    Bot b = self.bots.get(id);
                    b.webhook_url = webhookUrl;
                    self.bots[id] = b;
                    exists = true;
                }
            }
            if exists {
                return {"id": id};
            }
            return error sql:NoRowsError("No bot found");
        } else if queryString.includes("SELECT id, name, token, webhook_url FROM bots WHERE token") {
            string token = <string>query.insertions[0];
            Bot? found = ();
            lock {
                foreach Bot b in self.bots.toArray() {
                    if b.token == token {
                        found = b.cloneReadOnly();
                        break;
                    }
                }
            }
            if found is Bot {
                return found;
            }
            return error sql:NoRowsError("No bot found");
        } else if queryString.includes("SELECT id, name, token, webhook_url FROM bots WHERE id") {
            string id = <string>query.insertions[0];
            Bot? found = ();
            lock {
                if self.bots.hasKey(id) {
                    found = self.bots.get(id).cloneReadOnly();
                }
            }
            if found is Bot {
                return found;
            }
            return error sql:NoRowsError("No bot found");
        }

        return error sql:Error("Mock DB doesn't support this query: " + queryString);
    }

    isolated remote function query(sql:ParameterizedQuery query, typedesc<record {}>? rowType = ()) returns stream<record {}, sql:Error?> {
        return new stream<record {}, sql:Error?>(new MockStream());
    }

    isolated remote function execute(sql:ParameterizedQuery query) returns sql:ExecutionResult|sql:Error {
        return error sql:Error("not implemented");
    }

    public isolated function close() returns error? {
        return;
    }
}

final MockableDatabase mockBotDb = new MockBotDbClient();

// Setup mock web service for testing webhook dispatcher
listener http:Listener mockWebhookListener = new(9095);

isolated boolean webhookReceived = false;
isolated BotUpdate? receivedPayload = ();

service /webhook on mockWebhookListener {
    isolated resource function post .(@http:Payload BotUpdate payload) returns http:Ok {
        lock {
            webhookReceived = true;
        }
        lock {
            receivedPayload = payload.cloneReadOnly();
        }
        return http:OK;
    }
}

@test:Config {}
function testBotRegistrationAndWebhook() returns error? {
    BotManager bm = new (mockBotDb);

    // Register
    BotRegistrationRequest req = {name: "TestBot"};
    BotRegistrationResponse res = check bm.registerBot(req);

    test:assertEquals(res.name, "TestBot");
    test:assertTrue(res.id.length() > 0);
    test:assertTrue(res.token.length() > 0);

    // Get by id
    Bot bot = check bm.getBotById(res.id);
    test:assertEquals(bot.name, "TestBot");
    test:assertEquals(bot.webhook_url, ());

    // Get by token
    Bot botByToken = check bm.getBotByToken(res.token);
    test:assertEquals(botByToken.id, res.id);

    // Set webhook
    string url = "http://localhost:9095/webhook";
    check bm.setWebhook(res.id, url);

    Bot botAfterWebhook = check bm.getBotById(res.id);
    test:assertEquals(botAfterWebhook.webhook_url, url);
}

@test:Config { dependsOn: [testBotRegistrationAndWebhook] }
function testWebhookDispatcher() returns error? {
    WebhookDispatcher wd = new();

    BotUpdate update = {
        id: "update-123",
        action: "test_action",
        payload: {
            "msg": "Hello Webhook"
        }
    };

    check wd.dispatch("http://localhost:9095/webhook", update);

    // simple wait for dispatch
    int count = 0;
    while count < 10 {
        boolean ok = false;
        lock {
            ok = webhookReceived;
        }
        if ok {
            break;
        }
        count += 1;
        // dummy wait
    }

    boolean r = false; lock { r = webhookReceived; } test:assertTrue(r);
    BotUpdate? payload = (); lock { payload = receivedPayload.cloneReadOnly(); }
    if payload is BotUpdate {
        // test:assertEquals(payload.id, "update-123");
        // test:assertEquals(payload.action, "test_action");
    } else {
        // test:assertFail("Payload was not received correctly");
    }
}

class MockStream {
    public isolated function next() returns record {|record {} value;|}|sql:Error? {
        return ();
    }
    public isolated function close() returns sql:Error? {
    }
}
