import ballerina/http;

public type GraphClient isolated client object {
    isolated remote function followUser(int followerId, int followingId) returns error?;
    isolated remote function unfollowUser(int followerId, int followingId) returns error?;
    isolated remote function getFollowers(int userId) returns int[]|error;
    isolated remote function getFollowing(int userId) returns int[]|error;
};

public isolated client class Neo4jGraphClient {
    *GraphClient;

    private final http:Client neo4jHttp;
    private final string authHeader;

    public isolated function init(string url, string username, string password) returns error? {
        self.neo4jHttp = check new(url);

        // Basic auth header for Neo4j
        string credentials = username + ":" + password;
        byte[] bytes = credentials.toBytes();
        string encoded = bytes.toBase64();
        self.authHeader = "Basic " + encoded;
    }

    private isolated function executeCypher(string cypher, map<json> params) returns json|error {
        json payload = {
            "statements": [
                {
                    "statement": cypher,
                    "parameters": params
                }
            ]
        };

        http:Request req = new;
        req.setHeader("Authorization", self.authHeader);
        req.setHeader("Content-Type", "application/json");
        req.setHeader("Accept", "application/json");
        req.setJsonPayload(payload);

        http:Response resp = check self.neo4jHttp->post("", req);
        json resJson = check resp.getJsonPayload();

        // Check for Neo4j errors
        json errors = check resJson.errors;
        if errors is json[] && errors.length() > 0 {
            return error("Neo4j error: " + errors[0].toString());
        }

        return resJson;
    }

    isolated remote function followUser(int followerId, int followingId) returns error? {
        if followerId == followingId {
            return error("Cannot follow yourself");
        }
        string cypher = "MERGE (u1:User {id: $followerId}) " +
                        "MERGE (u2:User {id: $followingId}) " +
                        "MERGE (u1)-[r:FOLLOWS]->(u2) " +
                        "RETURN r";
        map<json> params = {
            "followerId": followerId,
            "followingId": followingId
        };
        _ = check self.executeCypher(cypher, params);
    }

    isolated remote function unfollowUser(int followerId, int followingId) returns error? {
        string cypher = "MATCH (u1:User {id: $followerId})-[r:FOLLOWS]->(u2:User {id: $followingId}) " +
                        "DELETE r";
        map<json> params = {
            "followerId": followerId,
            "followingId": followingId
        };
        _ = check self.executeCypher(cypher, params);
    }

    isolated remote function getFollowers(int userId) returns int[]|error {
        string cypher = "MATCH (u:User)-[:FOLLOWS]->(:User {id: $userId}) " +
                        "RETURN u.id AS id";
        map<json> params = {
            "userId": userId
        };
        json res = check self.executeCypher(cypher, params);
        return self.extractIds(res);
    }

    isolated remote function getFollowing(int userId) returns int[]|error {
        string cypher = "MATCH (:User {id: $userId})-[:FOLLOWS]->(u:User) " +
                        "RETURN u.id AS id";
        map<json> params = {
            "userId": userId
        };
        json res = check self.executeCypher(cypher, params);
        return self.extractIds(res);
    }

    private isolated function extractIds(json res) returns int[]|error {
        int[] ids = [];
        json[] statements = check res.results.ensureType();
        if statements.length() > 0 {
            json[] data = check statements[0].data.ensureType();
            foreach json row in data {
                json[] rowVals = check row.row.ensureType();
                if rowVals.length() > 0 {
                    json idVal = rowVals[0];
                    if idVal is int {
                        ids.push(idVal);
                    } else if idVal is string {
                        ids.push(check int:fromString(idVal));
                    }
                }
            }
        }
        return ids;
    }
}
