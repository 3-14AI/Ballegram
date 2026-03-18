import ballerina/test;
import ballerina/grpc;

final grpc:Client testGrpcClient = check new grpc:Client("http://localhost:9092");

@test:Config {}
function testGrpcRegisterSuccess() returns error? {
    RegisterRequest req = {
        username: "grpctestuser",
        email: "grpc@test.com",
        password: "password123"
    };

    [anydata, map<string|string[]>] response = check testGrpcClient->executeSimpleRPC("ballegram.AuthService/Register", req);
    anydata payload = response[0];
    RegisterResponse result = check payload.cloneWithType(RegisterResponse);
    test:assertEquals(result.username, "grpctestuser");
    test:assertEquals(result.email, "grpc@test.com");
}

@test:Config { dependsOn: [testGrpcRegisterSuccess] }
function testGrpcLoginSuccess() returns error? {
    LoginRequest req = {
        username: "grpctestuser",
        password: "password123"
    };

    [anydata, map<string|string[]>] response = check testGrpcClient->executeSimpleRPC("ballegram.AuthService/Login", req);
    anydata payload = response[0];
    LoginResponse result = check payload.cloneWithType(LoginResponse);
    test:assertTrue(result.token != "", "Token should not be empty");
}

@test:Config {}
function testGrpcLoginFailure() returns error? {
    LoginRequest req = {
        username: "nonexistent",
        password: "wrongpassword"
    };

    [anydata, map<string|string[]>]|grpc:Error response = testGrpcClient->executeSimpleRPC("ballegram.AuthService/Login", req);
    test:assertTrue(response is grpc:Error, "Expected an error");
}
