import ballerina/sql;

public isolated client class MockDbClient {
    *DbClient;

    private final (record{} & readonly)|sql:Error response;

    // Initialize with the response we want this client to return.
    // The response must be readonly or an error to be safe in an isolated object.
    public function init((record{} & readonly)|sql:Error response) {
        self.response = response;
    }

    isolated remote function queryRow(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns record {}|sql:Error {
        // We simply return the configured response.
        // The test case is responsible for configuring the correct response for the specific call it expects.
        return self.response;
    }
}
