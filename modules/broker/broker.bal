import ballerinax/kafka;

public type BrokerConfig record {|
    string bootstrapServers;
    boolean mockMode = false;
|};

public isolated class EventBroker {
    private final kafka:Producer? producer;

    public isolated function init(BrokerConfig config) returns error? {
        if config.mockMode {
            self.producer = ();
            return;
        }

        kafka:ProducerConfiguration producerConfig = {
            clientId: "ballegram-producer",
            acks: kafka:ACKS_ALL,
            retryCount: 3
        };
        self.producer = check new (config.bootstrapServers, producerConfig);
    }

    public isolated function publishEvent(string topic, byte[] message) returns error? {
        kafka:Producer? p = self.producer;
        if p is kafka:Producer {
            check p->send({
                topic: topic,
                value: message
            });
        }
    }

    public isolated function close() returns error? {
        kafka:Producer? p = self.producer;
        if p is kafka:Producer {
            check p->close();
        }
    }
}
