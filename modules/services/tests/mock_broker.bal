import ballegram.broker;

public isolated class MockEventBroker {
    private final (byte[] & readonly)[] publishedMessages = [];

    public isolated function init(broker:BrokerConfig config) returns error? {
        // init empty mock
    }

    public isolated function publishEvent(string topic, byte[] message) returns error? {
        byte[] & readonly copy = message.cloneReadOnly();
        lock {
            self.publishedMessages.push(copy);
        }
    }

    public isolated function getMessages() returns byte[][] {
        lock {
            return self.publishedMessages.clone();
        }
    }

    public isolated function close() returns error? {
        // no-op
    }
}
