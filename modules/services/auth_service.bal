import ballerina/http;
import ballegram.auth;

type RegisterRequest record {|
    string username;
    string email;
    string password;
|};

type LoginRequest record {|
    string username;
    string password;
|};

type LoginResponse record {|
    string token;
|};

service /auth on ep {

    resource function post register(@http:Payload RegisterRequest req) returns http:Created|http:BadRequest|http:InternalServerError {
        if req.username == "" || req.email == "" || req.password == "" {
             return <http:BadRequest> { body: "Missing required fields" };
        }

        auth:User|error user = auth:register(db, req.username, req.email, req.password);
        if user is error {
            // In a real app, check for unique constraint violation
            return <http:InternalServerError> { body: user.message() };
        }
        return <http:Created> { body: user };
    }

    resource function post login(@http:Payload LoginRequest req) returns LoginResponse|http:Unauthorized|http:BadRequest {
        if req.username == "" || req.password == "" {
            return <http:BadRequest> { body: "Missing required fields" };
        }

        string|error token = auth:login(db, req.username, req.password, authConfig);
        if token is error {
            return <http:Unauthorized> { body: "Invalid credentials" };
        }

        return { token: token };
    }
}
