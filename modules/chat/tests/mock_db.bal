import ballerina/sql;

public isolated client class MockDbClient {
    *DbClient;

    private final (record{} & readonly)|sql:Error? queryRowResponse;
    private final stream<record {}, sql:Error?>? queryResponse;

    public function init(
        (record{} & readonly)|sql:Error? queryRowResponse = (),
        stream<record {}, sql:Error?>? queryResponse = ()
    ) {
        self.queryRowResponse = queryRowResponse;
        self.queryResponse = queryResponse;
    }

    isolated remote function queryRow(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns record {}|sql:Error {
        if self.queryRowResponse is () {
             return error sql:Error("Mock not configured for queryRow");
        }
        // Safely unwrap the optional
        var resp = self.queryRowResponse;
        if resp is () {
            return error sql:Error("Unexpected null");
        }
        return resp;
    }

    isolated remote function query(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns stream<record {}, sql:Error?> {
         if self.queryResponse is () {
             return new stream<record {}, sql:Error?>(new EmptyStream());
         }
         var resp = self.queryResponse;
         if resp is () {
              return new stream<record {}, sql:Error?>(new EmptyStream());
         }
         return resp;
    }
}

public isolated class EmptyStream {
    public isolated function next() returns record {| record {} value; |}|sql:Error? {
        return ();
    }
}
