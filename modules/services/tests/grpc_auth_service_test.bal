import ballerina/test;
import ballerina/grpc;

final grpc:Client ep = check new ("http://localhost:9092");

@test:Config {}
function testGrpcRegisterSuccess() returns error? {
    RegisterRequest req = {
        username: "grpctestuser",
        email: "grpc@test.com",
        password: "password123"
    };

    RegisterResponse result = check ep->executeSimpleRPC("AuthService/Register", req);
    test:assertEquals(result.username, "grpctestuser");
    test:assertEquals(result.email, "grpc@test.com");
}

@test:Config { dependsOn: [testGrpcRegisterSuccess] }
function testGrpcLoginSuccess() returns error? {
    LoginRequest req = {
        username: "grpctestuser",
        password: "password123"
    };

    LoginResponse result = check ep->executeSimpleRPC("AuthService/Login", req);
    test:assertTrue(result.token != "", "Token should not be empty");
}

@test:Config {}
function testGrpcLoginFailure() returns error? {
    LoginRequest req = {
        username: "nonexistent",
        password: "wrongpassword"
    };

    LoginResponse|error result = ep->executeSimpleRPC("AuthService/Login", req);
    test:assertTrue(result is grpc:Error, "Expected an error");
}
