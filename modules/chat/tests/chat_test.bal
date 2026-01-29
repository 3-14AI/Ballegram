import ballerina/test;

@test:Config {}
function testCreateChat() {
    string|error chatId = createChat("u1", "u2");
    test:assertTrue(chatId is string, "Should return a chat ID");
    test:assertEquals(chatId, "chat-id");
}

@test:Config {}
function testSaveMessage() {
    string|error msgId = saveMessage("c1", "u1", "Hi");
    test:assertTrue(msgId is string, "Should return a message ID");
    test:assertEquals(msgId, "msg-id");
}
