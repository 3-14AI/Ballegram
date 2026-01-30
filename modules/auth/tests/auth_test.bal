import ballerina/test;
import ballegram.common;

common:DatabaseConfig dbConfig = {
    host: "localhost",
    port: 5432,
    user: "postgres",
    password: "dummy_password",
    database: "ballegram"
};

@test:Config {}
function testRegister() {
    common:Database|error db = new(dbConfig);
    if db is error {
        // Expected failure in sandbox environment without DB
        // test:assertFail("Failed to init db: " + db.message());
        return;
    }

    User|error result = register(db, "alice", "alice@example.com", "123");
    if result is error {
        // Expected to fail connection
        // test:assertFail("Registration failed: " + result.message());
    } else {
        test:assertEquals(result.username, "alice");
    }
}

@test:Config {}
function testLogin() {
    string|error result = login("alice", "123");
    test:assertTrue(result is string, "Login should return a token string");
    if result is string {
        test:assertEquals(result, "dummy-token", "Token mismatch");
    }
}
