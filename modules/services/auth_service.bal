import ballerina/http;
import ballerina/sql;
import ballerinax/postgresql;
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

// Adapter class to make postgresql:Client compatible with auth:DbClient interface
public isolated client class RealDbClient {
    *auth:DbClient;
    private final postgresql:Client db;

    public function init(postgresql:Client db) {
        self.db = db;
    }

    isolated remote function queryRow(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns record {}|sql:Error {
         // Delegate to the real client
         // Note: postgresql:Client.queryRow takes a typedesc.
         // We must handle the optional rowType from the interface.
         if rowType is typedesc<record {}> {
             return self.db->queryRow(sqlQuery, rowType);
         }
         return self.db->queryRow(sqlQuery);
    }
}

service /auth on ep {

    isolated resource function post register(@http:Payload RegisterRequest req) returns http:Created|http:BadRequest|http:InternalServerError {
        if req.username == "" || req.email == "" || req.password == "" {
             return <http:BadRequest> { body: "Missing required fields" };
        }

        // Wrap the DB client
        RealDbClient dbClient = new(db.db);

        auth:User|error user = auth:register(dbClient, req.username, req.email, req.password);
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

        // Wrap the DB client
        RealDbClient dbClient = new(db.db);

        string|error token = auth:login(dbClient, req.username, req.password, authConfig);
        if token is error {
            return <http:Unauthorized> { body: "Invalid credentials" };
        }

        return { token: token };
    }
}
