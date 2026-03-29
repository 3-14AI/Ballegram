import ballerina/test;
import ballerina/websocket;

// A test service that populates LinkManager using a real websocket:Caller
service /test_devices on new websocket:Listener(9094) {
    resource function get .() returns websocket:Service {
        return new TestWsService();
    }
}

service class TestWsService {
    *websocket:Service;

    remote function onMessage(websocket:Caller caller, string text) returns error? {
        if text.startsWith("INIT:") {
            string publicKey = text.substring(5);
            linkManager.addSession("test-link-123", publicKey, caller);
            check caller->writeMessage("STORED");
        } else if text == "CLEANUP" {
            linkManager.removeSessionByCaller(caller);
            check caller->writeMessage("CLEANED");
        }
    }
}

@test:Config {}
function testRealLinkManagerIntegration() returns error? {
    // 1. Connect a test client
    websocket:Client wsClient = check new("ws://localhost:9094/test_devices");

    // 2. Send INIT payload
    check wsClient->writeMessage("INIT:test-pub-key-888");

    // Wait for the server to process and reply
    string reply = check wsClient->readMessage();
    test:assertEquals(reply, "STORED", "Server should reply STORED");

    // 3. Test LinkManager state
    string? pk = linkManager.getPublicKey("test-link-123");
    test:assertEquals(pk, "test-pub-key-888", "Public key should be correctly stored in LinkManager");

    websocket:Caller? storedCaller = linkManager.getCaller("test-link-123");
    test:assertTrue(storedCaller is websocket:Caller, "Caller should be stored in LinkManager");

    // 4. Test reverse mapping and cleanup
    check wsClient->writeMessage("CLEANUP");
    string cleanupReply = check wsClient->readMessage();
    test:assertEquals(cleanupReply, "CLEANED", "Server should reply CLEANED");

    // 5. Verify cleanup
    string? deletedPk = linkManager.getPublicKey("test-link-123");
    test:assertEquals(deletedPk, (), "Public key should be removed from LinkManager after cleanup by caller");

    websocket:Caller? deletedCaller = linkManager.getCaller("test-link-123");
    test:assertEquals(deletedCaller, (), "Caller should be removed from LinkManager");

    check wsClient->close();
}
