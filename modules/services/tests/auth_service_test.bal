import ballerina/test;
import ballerina/http;

// Client to test the auth service
http:Client authClient = check new("http://localhost:9090/auth");

@test:Config {}
function testRegisterAndLogin() returns error? {
    // Define test data
    var regReq = { username: "apitest", email: "api@test.com", password: "password" };

    // Attempt to call register endpoint
    // We use 'check' to ensure the test fails if the request fails (e.g. connection refused)
    // However, in environments without the service running, this will fail.
    // If we want to support "mock" environments, we would need a MockClient.
    // Given the project structure, we assume integration tests run with the service.

    http:Response regRes = check authClient->post("/register", regReq);

    // Assert status code
    test:assertEquals(regRes.statusCode, 201, "Registration should return 201 Created");

    // Attempt to login
    var loginReq = { username: "apitest", password: "password" };
    http:Response loginRes = check authClient->post("/login", loginReq);

    test:assertEquals(loginRes.statusCode, 200, "Login should return 200 OK");

    json payload = check loginRes.getJsonPayload();
    // Verify token exists in response
    map<json> payloadMap = <map<json>>payload;
    test:assertTrue(payloadMap.hasKey("token"), "Response should contain token");
}
