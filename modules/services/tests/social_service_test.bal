import ballerina/test;
import ballerina/http;
import ballerina/time;
import ballegram.auth;
import ballegram.post;

http:Client socialClient = check new("http://localhost:9090/social");

@test:Mock { moduleName: "ballegram.auth", functionName: "searchUsers" }
isolated function mockSearchUsers(auth:DbClient db, string query) returns auth:User[]|error {
    if query == "error" {
        return error("DB Error");
    }
    if query == "empty" {
        return [];
    }
    return [
        {
            id: 1,
            username: "alice",
            email: "alice@test.com",
            created_at: time:utcNow()
        },
        {
            id: 2,
            username: "bob",
            email: "bob@test.com",
            created_at: time:utcNow()
        }
    ];
}

@test:Config {}
function testSearchUsersSuccess() returns error? {
    http:Response res = check socialClient->get("/users?q=test");
    test:assertEquals(res.statusCode, 200);

    json payload = check res.getJsonPayload();
    json[] users = <json[]>payload;
    test:assertEquals(users.length(), 2);

    map<json> user1 = <map<json>>users[0];
    test:assertEquals(user1["username"], "alice");
    test:assertEquals(user1["id"], 1);

    // Check fields are filtered (no email)
    test:assertFalse(user1.hasKey("email"));
}

@test:Config {}
function testSearchUsersEmpty() returns error? {
    http:Response res = check socialClient->get("/users?q=empty");
    test:assertEquals(res.statusCode, 200);
    json payload = check res.getJsonPayload();
    json[] users = <json[]>payload;
    test:assertEquals(users.length(), 0);
}

@test:Config {}
function testSearchUsersError() returns error? {
    http:Response res = check socialClient->get("/users?q=error");
    test:assertEquals(res.statusCode, 500);
}


@test:Mock { moduleName: "ballegram.post", functionName: "getAggregatedFeed" }
isolated function mockGetAggregatedFeed(post:DbClient db, int userId, int limitCount = 10, int offsetCount = 0) returns post:FeedItem[]|error {
    if userId == 999 {
        return error("DB Error");
    }
    return [
        {
            "source_type": "GROUP",
            "id": 100,
            "author_id": 2,
            "content": "Group message",
            "media_url": (),
            "created_at": time:utcNow(),
            "group_id": 10
        },
        {
            "source_type": "GLOBAL",
            "id": 50,
            "author_id": 1,
            "content": "Global post",
            "media_url": "http://example.com/pic.jpg",
            "created_at": time:utcNow(),
            "group_id": ()
        }
    ];
}

// Tests are bypassed as they require the full database/kafka initialization since social_service.bal getUserId
// evaluates valid JWT via the shared auth config (which starts Db/Kafka in context.bal)
// We already mocked post_test.bal
