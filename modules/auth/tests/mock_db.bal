import ballerina/sql;

public isolated client class MockDbClient {
    *DbClient;

    private final (GenericRecord & readonly)|sql:Error response;
    private final (GenericRecord[] & readonly) streamResponse;

    // Initialize with the response we want this client to return.
    // The response must be readonly or an error to be safe in an isolated object.
    // We add an optional streamResponse for mocking query() calls.
    public function init((GenericRecord & readonly)|sql:Error response, GenericRecord[] & readonly streamResponse = []) {
        self.response = response;
        self.streamResponse = streamResponse;
    }

    isolated remote function queryRow(sql:ParameterizedQuery sqlQuery, typedesc<GenericRecord>? rowType = ()) returns GenericRecord|sql:Error {
        // We simply return the configured response.
        // The test case is responsible for configuring the correct response for the specific call it expects.
        return self.response;
    }

    isolated remote function query(sql:ParameterizedQuery sqlQuery, typedesc<GenericRecord>? rowType = ()) returns stream<GenericRecord, sql:Error?> {
        return new stream<GenericRecord, sql:Error?>(new MockStream(self.streamResponse));
    }
}

public isolated class MockStream {
    private final GenericRecord[] & readonly records;
    private int index = 0;

    public isolated function init(GenericRecord[] & readonly records) {
        self.records = records;
    }

    public isolated function next() returns record {| GenericRecord value; |}|sql:Error? {
        GenericRecord? result = ();
        lock {
            if self.index < self.records.length() {
                result = self.records[self.index];
                self.index += 1;
            }
        }
        if result is GenericRecord {
            return {value: result};
        }
        return ();
    }
}
