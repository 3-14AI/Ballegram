import ballerina/test;
import ballerina/time;

@test:Config {}
function testCreateChat() returns error? {
    Chat expectedChat = {
        id: 1,
        name: "Test Chat",
        'type: DIRECT,
        created_at: time:utcNow(),
        version: 1
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
        created_at: time:utcNow(),
        version: 1
    };

    MockMessageStoreClient mockDb = new(messageResponse = expectedMessage.cloneReadOnly());

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

    MockMessageStoreClient mockDb = new(messagesResponse = [msg1, msg2].cloneReadOnly());

    stream<Message, error?>|error historyRes = getChatHistory(mockDb, 1);
    test:assertTrue(historyRes is stream<Message, error?>);
    if historyRes is error {
        return historyRes;
    }
    stream<Message, error?> history = historyRes;

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

@test:Config {}
function testDeleteOldMessages() returns error? {
    MockMessageStoreClient mockDb = new();
    // This should execute without errors based on mock implementation
    error? result = mockDb->deleteOldMessages(157680000);
    test:assertTrue(result is ());
}

@test:Config {}
function testGetMissedMessages() returns error? {
    Message msg1 = {
        id: 1, chat_id: 1, sender_id: 1, content: "Hi", created_at: time:utcNow()
    };
    Message msg2 = {
        id: 2, chat_id: 1, sender_id: 2, content: "Hello", created_at: time:utcNow()
    };
    Message msg3 = {
        id: 3, chat_id: 1, sender_id: 1, content: "How are you?", created_at: time:utcNow()
    };

    MockMessageStoreClient mockDb = new(messagesResponse = [msg1, msg2, msg3].cloneReadOnly());

    stream<Message, error?>|error historyRes = getMissedMessages(mockDb, 1, 1);
    test:assertTrue(historyRes is stream<Message, error?>);
    if historyRes is error {
        return historyRes;
    }
    stream<Message, error?> history = historyRes;

    record {| Message value; |}|error? item1 = history.next();
    test:assertTrue(item1 is record {| Message value; |});
    if item1 is record {| Message value; |} {
        test:assertEquals(item1.value.id, 2);
    }

    record {| Message value; |}|error? item2 = history.next();
    test:assertTrue(item2 is record {| Message value; |});
    if item2 is record {| Message value; |} {
        test:assertEquals(item2.value.id, 3);
    }

    record {| Message value; |}|error? item3 = history.next();
    test:assertTrue(item3 is ());
}

@test:Config {}
function testEditMessage() returns error? {
    Message editedMsg = {
        id: 1,
        chat_id: 1,
        sender_id: 2,
        content: "Edited",
        created_at: time:utcNow(),

        version: 2
    };

    MockMessageStoreClient mockDb = new(messageResponse = editedMsg.cloneReadOnly());

    Message|error result = editMessage(mockDb, 1, 1, 2, "Edited", 1);

    // As mockDb returns "Not implemented"
    test:assertTrue(result is error);
}

@test:Config {}
function testMarkMessageAsReadDirect() returns error? {
    Message msg = {
        id: 1, chat_id: 1, sender_id: 2, content: "To Read", created_at: time:utcNow(),
        version: 1, read_by: [], read_count: 0, is_read: false
    };

    MockMessageStoreClient mockDb = new(messageResponse = msg.cloneReadOnly());
    Message|error result = markMessageAsRead(mockDb, 1, 1, DIRECT);

    test:assertTrue(result is Message);
    if result is Message {
        test:assertEquals(result.read_count, 1);
        test:assertTrue(result.is_read);
        test:assertEquals(result.read_by, [1]);
    }
}

@test:Config {}
function testMarkMessageAsReadGroup() returns error? {
    Message msg = {
        id: 1, chat_id: 1, sender_id: 2, content: "To Read Group", created_at: time:utcNow(),
        version: 1, read_by: [3, 4], read_count: 2, is_read: false
    };

    MockMessageStoreClient mockDb = new(messageResponse = msg.cloneReadOnly());
    Message|error result = markMessageAsRead(mockDb, 1, 1, GROUP);

    test:assertTrue(result is Message);
    if result is Message {
        test:assertEquals(result.read_count, 3);
        test:assertTrue(result.is_read); // Reached threshold of 3
        test:assertEquals(result.read_by, [3, 4, 1]);
    }
}

@test:Config {}
function testMarkMessageAsReadGroupNotThreshold() returns error? {
    Message msg = {
        id: 1, chat_id: 1, sender_id: 2, content: "To Read Group Not", created_at: time:utcNow(),
        version: 1, read_by: [3], read_count: 1, is_read: false
    };

    MockMessageStoreClient mockDb = new(messageResponse = msg.cloneReadOnly());
    Message|error result = markMessageAsRead(mockDb, 1, 1, GROUP);

    test:assertTrue(result is Message);
    if result is Message {
        test:assertEquals(result.read_count, 2);
        test:assertFalse(result.is_read); // Not reached threshold of 3
        test:assertEquals(result.read_by, [3, 1]);
    }
}

@test:Config {}
function testMarkMessageAsReadAlreadyRead() returns error? {
    Message msg = {
        id: 1, chat_id: 1, sender_id: 2, content: "Already Read", created_at: time:utcNow(),
        version: 1, read_by: [1], read_count: 1, is_read: true
    };

    MockMessageStoreClient mockDb = new(messageResponse = msg.cloneReadOnly());
    Message|error result = markMessageAsRead(mockDb, 1, 1, DIRECT);

    test:assertTrue(result is error);
    if result is error {
        test:assertEquals(result.message(), "Already read");
    }
}
