import ballerina/test;
import ballerina/time;

@test:Config {}
function testCreateChat() returns error? {
    Chat expectedChat = {
        id: 1,
        name: "Test Chat",
        'type: DIRECT,
        created_at: time:utcNow()
    };

    MockDbClient mockDb = new(queryRowResponse = expectedChat.cloneReadOnly());

    Chat|error result = createChat(mockDb, [1, 2], DIRECT, "Test Chat");

    test:assertTrue(result is Chat);
    if result is Chat {
        test:assertEquals(result.id, 1);
        test:assertEquals(result.name, "Test Chat");
        test:assertEquals(result.'type, DIRECT);
    }
}

@test:Config {}
function testSaveMessage() returns error? {
    Message expectedMessage = {
        id: 100,
        chat_id: 1,
        sender_id: 2,
        content: "Hello",
        created_at: time:utcNow()
    };

    MockDbClient mockDb = new(queryRowResponse = expectedMessage.cloneReadOnly());

    Message|error result = saveMessage(mockDb, 1, 2, "Hello");

    test:assertTrue(result is Message);
    if result is Message {
        test:assertEquals(result.content, "Hello");
        test:assertEquals(result.sender_id, 2);
    }
}

@test:Config {}
function testGetChatHistory() returns error? {
    Message msg1 = {
        id: 1, chat_id: 1, sender_id: 1, content: "Hi", created_at: time:utcNow()
    };
    Message msg2 = {
        id: 2, chat_id: 1, sender_id: 2, content: "Hello", created_at: time:utcNow()
    };

    // Pass the array of messages directly. MockDbClient expects record{}[] & readonly.
    // Message[] is compatible with record{}[]. cloneReadOnly() ensures it is readonly.
    MockDbClient mockDb = new(queryResults = [msg1, msg2].cloneReadOnly());

    stream<Message, error?> history = getChatHistory(mockDb, 1);

    record {| Message value; |}|error? item1 = history.next();
    test:assertTrue(item1 is record {| Message value; |});
    if item1 is record {| Message value; |} {
        test:assertEquals(item1.value.content, "Hi");
    }

    record {| Message value; |}|error? item2 = history.next();
    test:assertTrue(item2 is record {| Message value; |});
    if item2 is record {| Message value; |} {
        test:assertEquals(item2.value.content, "Hello");
    }

    record {| Message value; |}|error? item3 = history.next();
    test:assertTrue(item3 is ());
}
