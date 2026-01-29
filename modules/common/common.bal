public type DatabaseConfig record {|
    string host;
    int port;
    string user;
    string password;
    string database;
|};

public type NotFoundError distinct error;

public type UnauthorizedError distinct error;

public type DatabaseError distinct error;
