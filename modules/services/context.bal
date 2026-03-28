import ballerina/http;
import ballegram.common;
import ballegram.auth;
import ballegram.media;
import ballegram.chat;
import ballegram.social;
import ballegram.broker;
import ballegram.push;

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

public type OpenSearchConfig record {|
    string url;
    string username;
    string password;
|};

configurable OpenSearchConfig openSearchConfig = {
    url: "http://localhost:9200",
    username: "admin",
    password: "Admin123!@#"
};

final chat:MessageStoreClient messageDb = check new chat:OpenSearchMessageClient(openSearchConfig.url, openSearchConfig.username, openSearchConfig.password);

public type Neo4jConfig record {|
    string url;
    string username;
    string password;
|};

configurable Neo4jConfig neo4jConfig = {
    url: "http://localhost:7474/db/neo4j/tx/commit",
    username: "neo4j",
    password: "password"
};

final social:GraphClient graphDb = check new social:Neo4jGraphClient(neo4jConfig.url, neo4jConfig.username, neo4jConfig.password);

public listener http:Listener ep = new(9090);

configurable broker:BrokerConfig brokerConfig = {
    bootstrapServers: "localhost:9093",
    mockMode: false
};

final broker:EventBroker eventBroker = check new broker:EventBroker(brokerConfig);

public type PushConfig record {|
    string fcmProjectId;
    string fcmAccessToken;
    string apnsEnvUrl;
    string apnsBundleId;
    string apnsAuthToken;
|};

configurable PushConfig pushConfig = {
    fcmProjectId: "dummy-project-id",
    fcmAccessToken: "dummy-server-key",
    apnsEnvUrl: "https://api.development.push.apple.com",
    apnsBundleId: "com.ballegram.app",
    apnsAuthToken: "dummy-auth-token"
};

final push:PushProvider fcmProvider = check new push:FCMPushProvider(pushConfig.fcmProjectId, pushConfig.fcmAccessToken);
final push:PushProvider apnsProvider = check new push:APNsPushProvider(pushConfig.apnsEnvUrl, pushConfig.apnsBundleId, pushConfig.apnsAuthToken);
final push:CompositePushProvider pushProvider = new push:CompositePushProvider(fcmProvider, apnsProvider);
