import ballerinax/kafka;
import ballerina/log;
import ballegram.push;

public isolated function routeEvent(json msgJson) returns error? {
    if msgJson is map<json> {
        if msgJson.hasKey("eventType") {
            string eventType = msgJson.get("eventType").toString();

            if eventType == "NEW_MESSAGE" {
                // Broadcast chat message
                json|error participantsJson = msgJson.participants;
                if participantsJson is json[] {
                    int[] participants = [];
                    foreach json p in participantsJson {
                        int|error id = p.ensureType(int);
                        if id is int {
                            participants.push(id);
                        }
                    }

                    json|error payload = msgJson.get("payload");
                    if payload is json {
                        connectionManager.broadcast(participants, payload.cloneReadOnly());
                        // Send push notifications to offline users
                        foreach int participantId in participants {
                            if !connectionManager.hasConnection(participantId) {
                                push:DeviceToken[]|error tokens = push:getUserTokens(db, participantId);
                                if tokens is push:DeviceToken[] {
                                    string textBody = "New message";
                                    map<json>|error plMap = payload.ensureType();
                                    if plMap is map<json> && plMap.hasKey("content") {
                                        textBody = plMap.get("content").toString();
                                    }
                                    foreach push:DeviceToken t in tokens {
                                        _ = start pushProvider->routeNotification(t.provider, t.token, "Ballegram", textBody);
                                    }
                                }
                            }
                        }
                    }
                }
            } else if eventType == "CDC_EVENT" {
                // Broadcast change data to participants
                json|error participantsJson = msgJson.participants;
                if participantsJson is json[] {
                    int[] participants = [];
                    foreach json p in participantsJson {
                        int|error id = p.ensureType(int);
                        if id is int {
                            participants.push(id);
                        }
                    }

                    json|error delta = msgJson.delta;
                    if delta is json {
                        connectionManager.broadcast(participants, delta.cloneReadOnly());
                    }
                }
            } else if eventType == "LIKE" || eventType == "COMMENT" {
                log:printInfo("Received social event: " + eventType);
            }
        }
    }
}

public function startKafkaListener() returns error? {
    if brokerConfig.mockMode {
        log:printInfo("Broker is in mock mode. Skipping listener initialization.");
        return;
    }

    kafka:Listener kafkaListener = check new (brokerConfig.bootstrapServers, {
        groupId: "ballegram-events-group",
        topics: "events",
        clientId: "ballegram-consumer"
    });

    check kafkaListener.attach(kafkaService);
    check kafkaListener.'start();
}

service class KafkaService {
    *kafka:Service;

    remote function onConsumerRecord(kafka:Caller caller, kafka:BytesConsumerRecord[] records) returns error? {
        foreach kafka:BytesConsumerRecord recordValue in records {
            byte[] msgBytes = recordValue.value;
            string|error msgString = string:fromBytes(msgBytes);

            if msgString is error {
                log:printError("Failed to convert message to string", 'error = msgString);
                continue;
            }

            json|error msgJson = msgString.fromJsonString();
            if msgJson is error {
                log:printError("Failed to parse message JSON", 'error = msgJson);
                continue;
            }

            _ = check routeEvent(msgJson);
        }
    }
}

final KafkaService kafkaService = new;
