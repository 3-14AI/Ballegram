import ballerina/sql;

public isolated client class MockDbClient {
    *DbClient;

    private final (record{} & readonly)|sql:Error? queryRowResponse;
    private final record{}[] & readonly queryResults;

    public function init(
        (record{} & readonly)|sql:Error? queryRowResponse = (),
        record{}[] & readonly queryResults = []
    ) {
        self.queryRowResponse = queryRowResponse;
        self.queryResults = queryResults;
    }

    isolated remote function queryRow(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns record {}|sql:Error {
        lock {
            if self.queryRowResponse is () {
                 return error sql:Error("Mock not configured for queryRow");
            }
            var resp = self.queryRowResponse;
            if resp is () {
                return error sql:Error("Unexpected null");
            }
            return resp;
        }
    }

    isolated remote function query(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns stream<record {}, sql:Error?> {
         record{}[] & readonly results;
         lock {
             results = self.queryResults;
         }
         return new stream<record {}, sql:Error?>(new MockStream(results));
    }
}

public isolated class MockStream {
    private final record{}[] & readonly messages;
    private int index = 0;

    public isolated function init(record{}[] & readonly messages) {
        self.messages = messages;
    }

    public isolated function next() returns record {| record {} value; |}|sql:Error? {
        lock {
            if self.index < self.messages.length() {
                record {} & readonly m = self.messages[self.index];
                self.index += 1;
                return { value: m };
            }
        }
        return ();
    }
}
