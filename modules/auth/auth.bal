import ballerina/crypto;
import ballerina/http;
import ballerina/jwt;
import ballerina/sql;
import ballerina/time;
import ballerina/uuid;
import ballegram.common;

// PBKDF2 Constants
const int ITERATIONS = 10000;

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

# Configuration for JWT authentication.
#
# + jwtSecret - The secret key for signing the JWT
# + jwtIssuer - The issuer of the JWT
# + jwtAudience - The audience of the JWT
# + jwtExpTime - The expiration time in seconds
public type AuthConfig record {|
    string jwtSecret;
    string jwtIssuer;
    string jwtAudience;
    decimal jwtExpTime;
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
    string salt = uuid:createType4AsString();

    // Hash password using PBKDF2
    string hashHex = check hashPassword(password, salt);

    // Store format: salt:hash
    string storedPassword = salt + ":" + hashHex;

    sql:ParameterizedQuery query = `INSERT INTO users (username, email, password_hash)
                                    VALUES (${username}, ${email}, ${storedPassword})
                                    RETURNING id, username, email, created_at`;

    // Execute query and map result to User type
    sql:Client dbClient = db.db;
    User user = check dbClient->queryRow(query);

    return user;
}

# Logs in a user.
#
# + db - The database client
# + username - The username
# + password - The password
# + config - The authentication configuration
# + return - JWT token or error
public function login(common:Database db, string username, string password, AuthConfig config) returns string|error {
    sql:Client dbClient = db.db;

    // We need to fetch all fields to map to UserEntity
    sql:ParameterizedQuery query = `SELECT id, username, email, created_at, password_hash
                                    FROM users WHERE username = ${username}`;

    UserEntity|sql:Error result = dbClient->queryRow(query);

    if result is sql:Error {
         if result is sql:NoRowsError {
             return error("Invalid username or password");
         }
         return result;
    }

    // Verify password
    string storedPassword = result.password_hash;
    int? delimiterIndex = storedPassword.indexOf(":");
    if delimiterIndex is () {
        return error("Invalid stored password format");
    }
    string salt = storedPassword.substring(0, delimiterIndex);
    string storedHash = storedPassword.substring(delimiterIndex + 1);

    string hashHex = check hashPassword(password, salt);

    if hashHex != storedHash {
        return error("Invalid username or password");
    }

    // Issue JWT
    jwt:IssuerConfig issuerConfig = {
        username: username,
        issuer: config.jwtIssuer,
        audience: config.jwtAudience,
        expTime: config.jwtExpTime,
        customClaims: { "uid": result.id },
        signatureConfig: {
            config: {
                key: config.jwtSecret
            }
        }
    };
    string token = check jwt:issue(issuerConfig);
    return token;
}

# Returns the JWT validator configuration for HTTP services.
#
# + config - The authentication configuration
# + return - The JWT validator configuration
public function getJwtValidatorConfig(AuthConfig config) returns http:JwtValidatorConfig {
    return {
        issuer: config.jwtIssuer,
        audience: config.jwtAudience,
        signatureConfig: {
            config: {
                key: config.jwtSecret
            }
        }
    };
}

# Hashes the password using PBKDF2 with HMAC-SHA256.
#
# + password - The password to hash
# + salt - The salt
# + return - The hex encoded hash or error
function hashPassword(string password, string salt) returns string|error {
    byte[] passwordBytes = password.toBytes();
    byte[] saltBytes = salt.toBytes();

    // Construct Salt || INT_32_BE(1) for the first block
    // We only generate 32 bytes (one block of SHA-256)
    byte[] blockInput = [...saltBytes, 0, 0, 0, 1];

    byte[] u = check crypto:hmacSha256(blockInput, passwordBytes);
    byte[] t = u.clone();

    foreach int i in 1 ..< ITERATIONS {
        u = check crypto:hmacSha256(u, passwordBytes);
        foreach int j in 0 ..< u.length() {
            t[j] = <byte>(t[j] ^ u[j]);
        }
    }
    return t.toBase16();
}
