import ballerina/sql;
import ballerina/test;
import ballerina/time;

public isolated client class MockGraphClient {
    *GraphClient;
    private final int[] & readonly getFollowersRes;
    private final int[] & readonly getFollowingRes;

    public isolated function init(int[] getFollowersRes = [], int[] getFollowingRes = []) {
        self.getFollowersRes = getFollowersRes.cloneReadOnly();
        self.getFollowingRes = getFollowingRes.cloneReadOnly();
    }

    isolated remote function followUser(int followerId, int followingId) returns error? {
        if followerId == followingId {
            return error("Cannot follow yourself");
        }
    }

    isolated remote function unfollowUser(int followerId, int followingId) returns error? {
    }

    isolated remote function getFollowers(int userId) returns int[]|error {
        return self.getFollowersRes;
    }

    isolated remote function getFollowing(int userId) returns int[]|error {
        return self.getFollowingRes;
    }
}

public isolated client class MockDbClient {
    *DbClient;
    private final GenericRecord[] & readonly queryResults;

    public isolated function init(GenericRecord[] queryResults = []) {
        self.queryResults = queryResults.cloneReadOnly();
    }

    isolated remote function queryRow(sql:ParameterizedQuery sqlQuery, typedesc<GenericRecord>? rowType = ()) returns GenericRecord|sql:Error {
        if self.queryResults.length() > 0 {
            return self.queryResults[0];
        }
        return error sql:NoRowsError("No rows found");
    }

    isolated remote function query(sql:ParameterizedQuery sqlQuery, typedesc<GenericRecord>? rowType = ()) returns stream<GenericRecord, sql:Error?> {
        return new stream<GenericRecord, sql:Error?>(new MockStream(self.queryResults));
    }
}

public isolated class MockStream {
    private final GenericRecord[] & readonly records;
    private int index = 0;

    public isolated function init(GenericRecord[] & readonly records) {
        self.records = records;
    }

    public isolated function next() returns record {| GenericRecord value; |}|sql:Error? {
        GenericRecord? result = ();
        lock {
            if self.index < self.records.length() {
                result = self.records[self.index];
                self.index += 1;
            }
        }
        if result is GenericRecord {
            return {value: result};
        }
        return ();
    }
}

@test:Config {}
function testLikePost() returns error? {
    MockDbClient db = new([{"user_id": 1}]);
    check likePost(db, 1, 1);
}

@test:Config {}
function testLikePostAlreadyLiked() returns error? {
    MockDbClient db = new([]); // Returns NoRowsError
    check likePost(db, 1, 1);
}

@test:Config {}
function testUnlikePost() returns error? {
    MockDbClient db = new([{"user_id": 1}]);
    check unlikePost(db, 1, 1);
}

@test:Config {}
function testCommentOnPost() returns error? {
    time:Utc now = time:utcNow();
    MockDbClient db = new([{
        "id": 1,
        "user_id": 1,
        "post_id": 1,
        "content": "Test Comment",
        "created_at": now
    }]);

    Comment comment = check commentOnPost(db, 1, 1, "Test Comment");
    test:assertEquals(comment.content, "Test Comment");
}

@test:Config {}
function testGetComments() returns error? {
    time:Utc now = time:utcNow();
    MockDbClient db = new([{
        "id": 1,
        "user_id": 1,
        "post_id": 1,
        "content": "Test Comment",
        "created_at": now,
        "username": "testuser"
    }]);

    CommentWithUser[] comments = check getComments(db, 1);
    test:assertEquals(comments.length(), 1);
    test:assertEquals(comments[0].username, "testuser");
}

@test:Config {}
function testFollowUser() returns error? {
    MockGraphClient graphDb = new();
    check followUser(graphDb, 1, 2);
}

@test:Config {}
function testUnfollowUser() returns error? {
    MockGraphClient graphDb = new();
    check unfollowUser(graphDb, 1, 2);
}

@test:Config {}
function testGetFollowers() returns error? {
    MockDbClient db = new([{
        "id": 1,
        "username": "follower"
    }]);
    MockGraphClient graphDb = new(getFollowersRes = [1]);

    UserSummary[] followers = check getFollowers(graphDb, db, 2);
    test:assertEquals(followers.length(), 1);
    test:assertEquals(followers[0].username, "follower");
}

@test:Config {}
function testGetFollowing() returns error? {
    MockDbClient db = new([{
        "id": 2,
        "username": "following"
    }]);
    MockGraphClient graphDb = new(getFollowingRes = [2]);

    UserSummary[] following = check getFollowing(graphDb, db, 1);
    test:assertEquals(following.length(), 1);
    test:assertEquals(following[0].username, "following");
}
