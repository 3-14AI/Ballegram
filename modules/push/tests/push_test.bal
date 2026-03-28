import ballerina/test;
import ballerina/sql;

public isolated client class MockDbClient {
    *DbClient;

    public isolated function init() {
    }

    isolated remote function query(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns stream<record {}, sql:Error?> {
        record {}[] rows = [
            {
                "user_id": 1,
                "device_id": "test-device-123",
                "token": "token-abc",
                "provider": "FCM"
            }
        ];
        return new stream<record {}, sql:Error?>(new MockStream(rows));
    }

    isolated remote function execute(sql:ParameterizedQuery sqlQuery) returns sql:ExecutionResult|sql:Error {
        return {
            affectedRowCount: 1,
            lastInsertId: 1
        };
    }
}

public class MockStream {
    private record {}[] rows;
    private int index = 0;

    public isolated function init(record {}[] rows) {
        self.rows = rows;
    }

    public isolated function next() returns record {|record {} value;|}|sql:Error? {
        if self.index < self.rows.length() {
            record {} row = self.rows[self.index];
            self.index += 1;
            return {value: row};
        }
        return ();
    }
}

public isolated client class MockPushProvider {
    *PushProvider;

    isolated remote function sendNotification(string token, string title, string body) returns error? {
        return; // Success
    }

    isolated remote function routeNotification(string providerStr, string token, string title, string body) returns error? {
        return;
    }
}

@test:Config {}
isolated function testRegisterToken() returns error? {
    MockDbClient db = new;
    error? result = registerDeviceToken(db, 1, "test-device-123", "token-abc", "FCM");
    test:assertEquals(result, ());
}

@test:Config {}
isolated function testUnregisterToken() returns error? {
    MockDbClient db = new;
    error? result = unregisterDeviceToken(db, 1, "test-device-123");
    test:assertEquals(result, ());
}
