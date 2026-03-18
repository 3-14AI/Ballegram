import ballerina/http;
import ballerina/grpc;

final grpc:Client authGrpcClient = check new grpc:Client("http://localhost:9092");

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

        [anydata, map<string|string[]>]|grpc:Error response = authGrpcClient->executeSimpleRPC("ballegram.AuthService/Register", req);

        if response is grpc:Error {
            return <http:InternalServerError> { body: response.message() };
        }

        anydata payload = response[0];
        RegisterResponse|error regResponse = payload.cloneWithType(RegisterResponse);
        if regResponse is error {
            return <http:InternalServerError> { body: "Invalid response format from IdP" };
        }

        return <http:Created> { body: regResponse };
    }

    isolated resource function post login(@http:Payload LoginRequest req) returns LoginResponse|http:Unauthorized|http:BadRequest|http:InternalServerError {
        if req.username == "" || req.password == "" {
            return <http:BadRequest> { body: "Missing required fields" };
        }

        [anydata, map<string|string[]>]|grpc:Error response = authGrpcClient->executeSimpleRPC("ballegram.AuthService/Login", req);

        if response is grpc:Error {
            if response is grpc:UnauthenticatedError {
                return <http:Unauthorized> { body: "Invalid credentials" };
            }
            return <http:InternalServerError> { body: response.message() };
        }

        anydata payload = response[0];
        LoginResponse|error loginResponse = payload.cloneWithType(LoginResponse);
        if loginResponse is error {
            return <http:InternalServerError> { body: "Invalid response format from IdP" };
        }

        return loginResponse;
    }
}
