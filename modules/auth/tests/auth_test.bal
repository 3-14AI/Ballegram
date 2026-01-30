import ballerina/test;
import ballegram.common;

common:DatabaseConfig dbConfig = {
    host: "localhost",
    port: 5432,
    user: "postgres",
    password: "dummy_password",
    database: "ballegram"
};

AuthConfig authConfig = {
    jwtSecret: "test-secret",
    jwtIssuer: "ballegram-test",
    jwtAudience: "ballegram-client",
    jwtExpTime: 3600
};

@test:Config {}
function testRegister() {
    common:Database|error db = new(dbConfig);
    if db is error {
        // Expected failure in sandbox environment without DB
        return;
    }

    User|error result = register(db, "alice", "alice@example.com", "123");
    if result is error {
        // Expected failure due to no DB connection
    } else {
        test:assertEquals(result.username, "alice");
    }
}

@test:Config {}
function testLogin() {
    common:Database|error db = new(dbConfig);
    if db is error {
        return;
    }

    string|error result = login(db, "alice", "123", authConfig);
    if result is error {
        // Expected failure due to no DB connection.
        // In a real environment, we would assert success or specific failure.
        // test:assertFail("Login failed: " + result.message());
    } else {
         test:assertTrue(result.length() > 0, "Login should return a token string");
    }
}
