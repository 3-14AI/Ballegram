import ballerina/test;
import ballerina/sql;
import ballerina/time;

AuthConfig authConfig = {
    jwtSecret: "test-secret",
    jwtIssuer: "ballegram-test",
    jwtAudience: "ballegram-client",
    jwtExpTime: 3600
};

@test:Config {}
function testRegisterSuccess() returns error? {
    User expectedUser = {
        id: 1,
        username: "alice",
        email: "alice@example.com",
        created_at: time:utcNow()
    };
    // Mock returns the user on INSERT
    MockDbClient mockDb = new(expectedUser);

    User|error result = register(mockDb, "alice", "alice@example.com", "password123");

    test:assertTrue(result is User);
    if result is User {
        test:assertEquals(result.username, "alice");
        test:assertEquals(result.email, "alice@example.com");
    }
}

@test:Config {}
function testRegisterDuplicateError() {
    sql:Error dbError = error sql:Error("Duplicate key violation");
    MockDbClient mockDb = new(dbError);

    User|error result = register(mockDb, "duplicate", "dup@test.com", "pass");

    test:assertTrue(result is error);
    if result is error {
        test:assertEquals(result.message(), "Duplicate key violation");
    }
}

@test:Config {}
function testLoginSuccess() returns error? {
    string salt = "testsalt";
    // We access the internal hashPassword function
    string hash = check hashPassword("password123", salt);
    string stored = salt + ":" + hash;

    UserEntity userEntity = {
        id: 10,
        username: "bob",
        email: "bob@test.com",
        created_at: time:utcNow(),
        password_hash: stored
    };
    MockDbClient mockDb = new(userEntity);

    string|error token = login(mockDb, "bob", "password123", authConfig);

    test:assertTrue(token is string, "Login should return a token string");
}

@test:Config {}
function testLoginUserNotFound() {
    MockDbClient mockDb = new(error sql:NoRowsError("No rows"));

    string|error result = login(mockDb, "unknown", "pass", authConfig);

    test:assertTrue(result is error);
    if result is error {
        test:assertEquals(result.message(), "Invalid username or password");
    }
}

@test:Config {}
function testLoginWrongPassword() returns error? {
    string salt = "testsalt";
    string hash = check hashPassword("correctpass", salt);
    string stored = salt + ":" + hash;

    UserEntity userEntity = {
        id: 11,
        username: "charlie",
        email: "c@test.com",
        created_at: time:utcNow(),
        password_hash: stored
    };
    MockDbClient mockDb = new(userEntity);

    // Attempt login with wrong password
    string|error result = login(mockDb, "charlie", "wrongpass", authConfig);

    test:assertTrue(result is error);
    if result is error {
        test:assertEquals(result.message(), "Invalid username or password");
    }
}

@test:Config {}
function testLoginDbError() {
    MockDbClient mockDb = new(error sql:Error("Connection lost"));

    string|error result = login(mockDb, "dave", "pass", authConfig);

    test:assertTrue(result is error);
    if result is error {
        // Should bubble up the DB error or handle it?
        // Implementation: if result is sql:Error { if NoRows... else return result }
        // So it returns the sql:Error.
        test:assertEquals(result.message(), "Connection lost");
    }
}

@test:Config {}
function testLoginInvalidStoredFormat() returns error? {
    // Password hash missing the salt:hash delimiter
    UserEntity userEntity = {
        id: 12,
        username: "eve",
        email: "e@test.com",
        created_at: time:utcNow(),
        password_hash: "invalidformatstring"
    };
    MockDbClient mockDb = new(userEntity);

    string|error result = login(mockDb, "eve", "pass", authConfig);

    test:assertTrue(result is error);
    if result is error {
        test:assertEquals(result.message(), "Invalid stored password format");
    }
}
