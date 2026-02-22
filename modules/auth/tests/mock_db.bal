import ballerina/sql;

public isolated client class MockDbClient {
    *DbClient;

    private final (record{} & readonly)|sql:Error response;
    private final (record{}[] & readonly) streamResponse;

    // Initialize with the response we want this client to return.
    // The response must be readonly or an error to be safe in an isolated object.
    // We add an optional streamResponse for mocking query() calls.
    public function init((record{} & readonly)|sql:Error response, record{}[] & readonly streamResponse = []) {
        self.response = response;
        self.streamResponse = streamResponse;
    }

    isolated remote function queryRow(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns record {}|sql:Error {
        // We simply return the configured response.
        // The test case is responsible for configuring the correct response for the specific call it expects.
        return self.response;
    }

    isolated remote function query(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns stream<record {}, sql:Error?> {
        return new stream<record {}, sql:Error?>(new MockStream(self.streamResponse));
    }
}

public isolated class MockStream {
    private final record{}[] & readonly records;
    private int index = 0;

    public isolated function init(record{}[] & readonly records) {
        self.records = records;
    }

    public isolated function next() returns record {| record{} value; |}|sql:Error? {
        record{}? result = ();
        lock {
            if self.index < self.records.length() {
                result = self.records[self.index];
                self.index += 1;
            }
        }
        if result is record{} {
            return {value: result};
        }
        return ();
    }
}
