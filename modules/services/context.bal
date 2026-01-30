import ballerina/http;
import ballegram.common;
import ballegram.auth;

configurable common:DatabaseConfig databaseConfig = ?;
configurable auth:AuthConfig authConfig = ?;

final common:Database db = check new(databaseConfig);

public listener http:Listener ep = new(9090);
