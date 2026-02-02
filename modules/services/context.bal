import ballerina/http;
import ballegram.common;
import ballegram.auth;

// Provide default dummy values to allow module initialization during tests
configurable common:DatabaseConfig databaseConfig = {
    host: "localhost",
    port: 5432,
    user: "postgres",
    password: "dummy",
    database: "ballegram"
};

configurable auth:AuthConfig & readonly authConfig = {
    jwtSecret: "test-secret-key-at-least-32-bytes-long",
    jwtIssuer: "ballegram-test",
    jwtAudience: "ballegram-client",
    jwtExpTime: 3600
};

final common:Database db = check new(databaseConfig);

public listener http:Listener ep = new(9090);
