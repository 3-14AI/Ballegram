import ballerina/http;
import ballerina/grpc;

public isolated client class AuthServiceClient {
    *grpc:AbstractClientEndpoint;
    private final grpc:Client grpcClient;

    public isolated function init(string url, *grpc:ClientConfiguration config) returns grpc:Error? {
        self.grpcClient = check new (url, config);
        check self.grpcClient.initStub(self, GRPC_AUTH_DESC, {});
    }

    isolated remote function Register(RegisterRequest req) returns RegisterResponse|grpc:Error {
        [anydata, map<string|string[]>]|grpc:Error response = self.grpcClient->executeSimpleRPC("ballegram.AuthService/Register", req);
        if response is grpc:Error {
            return response;
        }
        anydata payload = response[0];
        RegisterResponse|error regResponse = payload.cloneWithType(RegisterResponse);
        if regResponse is error {
            return error grpc:InternalError("Invalid response type from IdP");
        }
        return regResponse;
    }

    isolated remote function Login(LoginRequest req) returns LoginResponse|grpc:Error {
        [anydata, map<string|string[]>]|grpc:Error response = self.grpcClient->executeSimpleRPC("ballegram.AuthService/Login", req);
        if response is grpc:Error {
            return response;
        }
        anydata payload = response[0];
        LoginResponse|error loginResponse = payload.cloneWithType(LoginResponse);
        if loginResponse is error {
            return error grpc:InternalError("Invalid response type from IdP");
        }
        return loginResponse;
    }
}

final AuthServiceClient authGrpcClient = check new ("http://localhost:9092");

type RegisterRequest record {|
    string username;
    string email;
    string password;
|};

type RegisterResponse record {|
    int id;
    string username;
    string? email;
    string created_at;
|};

type LoginRequest record {|
    string username;
    string password;
|};

type LoginResponse record {|
    string token;
|};

service /auth on ep {

    isolated resource function post register(@http:Payload RegisterRequest req) returns http:Created|http:BadRequest|http:InternalServerError {
        if req.username == "" || req.email == "" || req.password == "" {
             return <http:BadRequest> { body: "Missing required fields" };
        }

        RegisterResponse|grpc:Error response = authGrpcClient->Register(req);

        if response is grpc:Error {
            return <http:InternalServerError> { body: response.message() };
        }

        return <http:Created> { body: response };
    }

    isolated resource function post login(@http:Payload LoginRequest req) returns LoginResponse|http:Unauthorized|http:BadRequest|http:InternalServerError {
        if req.username == "" || req.password == "" {
            return <http:BadRequest> { body: "Missing required fields" };
        }

        LoginResponse|grpc:Error response = authGrpcClient->Login(req);

        if response is grpc:Error {
            if response is grpc:UnauthenticatedError {
                return <http:Unauthorized> { body: "Invalid credentials" };
            }
            return <http:InternalServerError> { body: response.message() };
        }

        return response;
    }
}
