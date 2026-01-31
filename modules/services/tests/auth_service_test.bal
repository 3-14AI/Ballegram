import ballerina/test;
import ballerina/http;
import ballerina/time;
import ballegram.auth;

// Client to test the auth service
http:Client authClient = check new("http://localhost:9090/auth");

// Mocking the auth:register function
@test:Mock { moduleName: "ballegram.auth", functionName: "register" }
function mockRegister(auth:DbClient db, string username, string email, string password) returns auth:User|error {
    if username == "register_error" {
        return error("Registration failed");
    }
    return {
        id: 1,
        username: username,
        email: email,
        created_at: time:utcNow()
    };
}

// Mocking the auth:login function
@test:Mock { moduleName: "ballegram.auth", functionName: "login" }
function mockLogin(auth:DbClient db, string username, string password, auth:AuthConfig config) returns string|error {
    if username == "login_error" {
        return error("Invalid credentials");
    }
    return "mock_jwt_token";
}

@test:Config {}
function testRegisterSuccess() returns error? {
    var req = { username: "valid_user", email: "test@test.com", password: "password" };
    http:Response res = check authClient->post("/register", req);

    // We expect 201 because mock returns success
    test:assertEquals(res.statusCode, 201);

    json payload = check res.getJsonPayload();
    map<json> pMap = <map<json>>payload;
    test:assertEquals(pMap["username"], "valid_user");
}

@test:Config {}
function testRegisterMissingFields() returns error? {
    var req = { username: "", email: "", password: "" };
    http:Response res = check authClient->post("/register", req);

    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testRegisterError() returns error? {
    // Trigger mock error
    var req = { username: "register_error", email: "test@test.com", password: "password" };
    http:Response res = check authClient->post("/register", req);

    test:assertEquals(res.statusCode, 500);
}

@test:Config {}
function testLoginSuccess() returns error? {
    var req = { username: "valid_user", password: "password" };
    http:Response res = check authClient->post("/login", req);

    test:assertEquals(res.statusCode, 200);
    json payload = check res.getJsonPayload();
    map<json> pMap = <map<json>>payload;
    test:assertEquals(pMap["token"], "mock_jwt_token");
}

@test:Config {}
function testLoginMissingFields() returns error? {
    var req = { username: "", password: "" };
    http:Response res = check authClient->post("/login", req);

    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testLoginError() returns error? {
    var req = { username: "login_error", password: "password" };
    http:Response res = check authClient->post("/login", req);

    test:assertEquals(res.statusCode, 401);
}
