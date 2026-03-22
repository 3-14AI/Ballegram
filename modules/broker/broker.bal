import ballerinax/kafka;

public type BrokerConfig record {|
    string bootstrapServers;
|};

public isolated class EventBroker {
    private final kafka:Producer producer;

    public isolated function init(BrokerConfig config) returns error? {
        kafka:ProducerConfiguration producerConfig = {
            clientId: "ballegram-producer",
            acks: kafka:ACKS_ALL,
            retryCount: 3
        };
        self.producer = check new (config.bootstrapServers, producerConfig);
    }

    public isolated function publishEvent(string topic, byte[] message) returns error? {
        check self.producer->send({
            topic: topic,
            value: message
        });
    }

    public isolated function close() returns error? {
        check self.producer->close();
    }
}
