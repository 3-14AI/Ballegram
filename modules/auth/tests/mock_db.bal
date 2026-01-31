import ballerina/sql;

public isolated client class MockDbClient {
    *DbClient;

    private final record{}|sql:Error response;

    // Initialize with the response we want this client to return
    public function init(record{}|sql:Error response) {
        self.response = response;
    }

    isolated remote function queryRow(sql:ParameterizedQuery|string sqlQuery, typedesc<record {}>? rowType = ()) returns record {}|sql:Error {
        // We simply return the configured response.
        // The test case is responsible for configuring the correct response for the specific call it expects.
        return self.response;
    }
}
