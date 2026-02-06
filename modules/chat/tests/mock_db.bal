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

         if rowType is typedesc<Message> {
             // We know the tests pass compatible records, so we cast to Message[]
             // cloneWithType is safer but for array casting in tests, simple cast or reconstruction works.
             // Since results is record{}[] & readonly, we cast it to Message[] & readonly
             Message[] & readonly msgs = <Message[] & readonly>results;
             return new stream<Message, sql:Error?>(new MockMessageStream(msgs));
         }

         return new stream<record {}, sql:Error?>(new MockGenericStream(results));
    }
}

public isolated class MockMessageStream {
    private final Message[] & readonly messages;
    private int index = 0;

    public isolated function init(Message[] & readonly messages) {
        self.messages = messages;
    }

    public isolated function next() returns record {| Message value; |}|sql:Error? {
        Message & readonly|() result = ();
        lock {
            if self.index < self.messages.length() {
                result = self.messages[self.index];
                self.index += 1;
            }
        }

        if result is Message {
            return { value: result };
        }
        return ();
    }
}

public isolated class MockGenericStream {
    private final record{}[] & readonly records;
    private int index = 0;

    public isolated function init(record{}[] & readonly records) {
        self.records = records;
    }

    public isolated function next() returns record {| record {} value; |}|sql:Error? {
        record {} & readonly|() result = ();
        lock {
            if self.index < self.records.length() {
                result = self.records[self.index];
                self.index += 1;
            }
        }

        if result is record {} {
            return { value: result };
        }
        return ();
    }
}
