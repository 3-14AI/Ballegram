import ballerina/http;
import ballegram.common;
import ballegram.auth;

// Provide default values that match docker-compose.yml to ensure container starts successfully
configurable common:DatabaseConfig databaseConfig = {
    host: "localhost",
    port: 5432,
    user: "user",
    password: "password",
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
