import ballerina/sql;
import ballerinax/postgresql;

public isolated client class Database {
    public final postgresql:Client db;

    public function init(DatabaseConfig config) returns error? {
        self.db = check new (
            host = config.host,
            username = config.user,
            password = config.password,
            database = config.database,
            port = config.port
        );
    }

    isolated remote function queryRow(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns record {}|sql:Error {
         if rowType is typedesc<record {}> {
             return self.db->queryRow(sqlQuery, rowType);
         }
         return self.db->queryRow(sqlQuery);
    }
}
