import ballerina/crypto;
import ballerina/sql;
import ballerina/time;
import ballerina/uuid;
import ballegram.common;

public type User record {|
    int id;
    string username;
    string? email;
    string password_hash;
    time:Utc created_at;
|};

# Registers a new user.
#
# + db - The database client
# + username - The username
# + email - The email address
# + password - The password
# + return - The created User or error
public function register(common:Database db, string username, string email, string password) returns User|error {
    // Generate a random salt using UUID
    // TODO: Upgrade to cryptographic random bytes and Argon2/Bcrypt when external modules are available.
    string salt = uuid:createType4AsString();

    // Combine salt and password
    string input = salt + password;
    byte[] hash = crypto:hashSha256(input.toBytes());
    string hashHex = hash.toHexString();

    // Store format: salt:hash
    string storedPassword = salt + ":" + hashHex;

    sql:ParameterizedQuery query = `INSERT INTO users (username, email, password_hash)
                                    VALUES (${username}, ${email}, ${storedPassword})
                                    RETURNING id, username, email, password_hash, created_at`;

    User|sql:Error result = db.db->queryRow(query);

    return result;
}

# Logs in a user.
#
# + username - The username
# + password - The password
# + return - JWT token or error
public function login(string username, string password) returns string|error {
    // TODO: Implement login
    return "dummy-token";
}
