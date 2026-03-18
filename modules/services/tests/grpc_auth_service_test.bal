import ballerina/test;
import ballerina/grpc;

final AuthServiceClient testGrpcClient = check new ("http://localhost:9092");

@test:Config {}
function testGrpcRegisterSuccess() returns error? {
    RegisterRequest req = {
        username: "grpctestuser",
        email: "grpc@test.com",
        password: "password123"
    };

    RegisterResponse result = check testGrpcClient->Register(req);
    test:assertEquals(result.username, "grpctestuser");
    test:assertEquals(result.email, "grpc@test.com");
}

@test:Config { dependsOn: [testGrpcRegisterSuccess] }
function testGrpcLoginSuccess() returns error? {
    LoginRequest req = {
        username: "grpctestuser",
        password: "password123"
    };

    LoginResponse result = check testGrpcClient->Login(req);
    test:assertTrue(result.token != "", "Token should not be empty");
}

@test:Config {}
function testGrpcLoginFailure() returns error? {
    LoginRequest req = {
        username: "nonexistent",
        password: "wrongpassword"
    };

    LoginResponse|grpc:Error response = testGrpcClient->Login(req);
    test:assertTrue(response is grpc:Error, "Expected an error");
}
