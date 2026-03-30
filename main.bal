import ballerina/io;
import ballerina/sql;
import ballerinax/postgresql;
import ballegram.common;
import ballegram.services as _;
import ballegram.devices as _;
import ballegram.widgets as _;

configurable common:DatabaseConfig database = ?;

public function main() returns error? {
    io:println("Starting Ballegram...");

    postgresql:Client|error dbClient = new (
        host = database.host,
        username = database.user,
        password = database.password,
        database = database.database,
        port = database.port
    );

    if dbClient is error {
        io:println("Failed to create DB client: " + dbClient.message());
    } else {
        int|sql:Error result = dbClient->queryRow(`SELECT 1`);
        if result is int {
            io:println("Database connection successful!");
        } else {
            io:println("Database connection failed");
        }

        check dbClient.close();
    }
}
