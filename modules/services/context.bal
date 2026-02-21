import ballerina/http;
import ballegram.common;
import ballegram.auth;
import ballegram.media;

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

// Default to local storage for ease of development and testing
configurable media:StorageConfig storageConfig = {
    'type: media:LOCAL,
    path: "uploads"
};

final common:Database db = check new(databaseConfig);

// Initialize the storage client based on configuration
// This allows switching between LOCAL and S3 by changing the config
final media:Storage storageClient = check media:getStorageClient(storageConfig);

public listener http:Listener ep = new(9090);
