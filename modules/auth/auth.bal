import ballerina/crypto;
import ballerina/sql;
import ballerina/time;
import ballerina/uuid;
import ballegram.common;

# Represents a user in the system.
#
# + id - The user's ID
# + username - The username
# + email - The email address
# + created_at - The timestamp when the user was created
public type User record {|
    int id;
    string username;
    string? email;
    time:Utc created_at;
|};

# Internal record for database mapping including the password hash.
#
# + password_hash - The hashed password
type UserEntity record {|
    *User;
    string password_hash;
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
    string hashHex = hash.toBase16();

    // Store format: salt:hash
    string storedPassword = salt + ":" + hashHex;

    sql:ParameterizedQuery query = `INSERT INTO users (username, email, password_hash)
                                    VALUES (${username}, ${email}, ${storedPassword})
                                    RETURNING id, username, email, created_at`;

    // Execute query and map result to User type
    User user = check db.db->queryRow(query);

    return user;
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
