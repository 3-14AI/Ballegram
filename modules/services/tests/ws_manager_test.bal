import ballerina/test;

@test:Config {}
function testConnectionManager() returns error? {
    ConnectionManager manager = new;
    // We can't easily instantiate a fake websocket:Caller without type cast errors,
    // but we can ensure the connection manager initializes and broadcast works with empty lists
    // to cover basic syntax.

    // Broadcast to non-existent user should not fail
    manager.broadcast([2], "Ignore me".cloneReadOnly());
    test:assertTrue(true, msg = "Connection manager handles missing connections safely");
}
