import ballerina/http;
import ballerina/grpc;

final AuthServiceClient authGrpcClient = check new ("http://localhost:9092");

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
