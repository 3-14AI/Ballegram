import ballerina/test;

@test:Config {}
function testRegister() {
    error? result = register("alice", "123");
    test:assertEquals(result, (), "Registration should succeed (mock)");
}

@test:Config {}
function testLogin() {
    string|error result = login("alice", "123");
    test:assertTrue(result is string, "Login should return a token string");
    if result is string {
        test:assertEquals(result, "dummy-token", "Token mismatch");
    }
}
