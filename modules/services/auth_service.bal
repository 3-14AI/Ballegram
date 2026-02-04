import ballerina/http;
import ballegram.auth;

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

        // Pass the global db object directly.
        // It now satisfies the DbClient interface.
        auth:User|error user = auth:register(db, req.username, req.email, req.password);
        if user is error {
            // In a real app, check for unique constraint violation
            return <http:InternalServerError> { body: user.message() };
        }

        RegisterResponse response = {
            id: user.id,
            username: user.username,
            email: user.email,
            created_at: user.created_at.toString()
        };

        return <http:Created> { body: response };
    }

    isolated resource function post login(@http:Payload LoginRequest req) returns LoginResponse|http:Unauthorized|http:BadRequest {
        if req.username == "" || req.password == "" {
            return <http:BadRequest> { body: "Missing required fields" };
        }

        // Pass the global db object directly.
        // It now satisfies the DbClient interface.
        string|error token = auth:login(db, req.username, req.password, authConfig);
        if token is error {
            return <http:Unauthorized> { body: "Invalid credentials" };
        }

        return { token: token };
    }
}
