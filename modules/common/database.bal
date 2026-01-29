import ballerinax/postgresql;

public client class Database {
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
}
