import ballerina/sql;
import ballerina/test;
import ballerina/time;

public isolated client class MockDbClient {
    *DbClient;
    private final record {}[] & readonly queryResults;

    public isolated function init(record {}[] queryResults = []) {
        self.queryResults = queryResults.cloneReadOnly();
    }

    isolated remote function queryRow(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns record {}|sql:Error {
        // Mock returning a created post record
        // The values here should match what we expect in the test assertions
        return {
            "id": 1,
            "user_id": 1,
            "content": "Test Content",
            "media_url": "http://example.com/image.jpg",
            "created_at": time:utcNow()
        };
    }

    isolated remote function query(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns stream<record {}, sql:Error?> {
        return new stream<record {}, sql:Error?>(new MockStream(self.queryResults));
    }
}

public isolated class MockStream {
    private final record {}[] & readonly records;
    private int index = 0;

    public isolated function init(record {}[] & readonly records) {
        self.records = records;
    }

    public isolated function next() returns record {| record {} value; |}|sql:Error? {
        record {}? result = ();
        lock {
            if self.index < self.records.length() {
                result = self.records[self.index];
                self.index += 1;
            }
        }
        if result is record {} {
            return {value: result};
        }
        return ();
    }
}

@test:Config {}
function testCreatePost() returns error? {
    MockDbClient db = new;
    CreatePostRequest req = {
        content: "Test Content",
        media_url: "http://example.com/image.jpg"
    };

    Post post = check createPost(db, 1, req);

    test:assertEquals(post.id, 1);
    test:assertEquals(post.user_id, 1);
    test:assertEquals(post.content, "Test Content");
    test:assertEquals(post.media_url, "http://example.com/image.jpg");
    // created_at is dynamic, so we just check it exists (it's part of the record type so it must exist)
}

@test:Config {}
function testCreatePostValidation() {
    MockDbClient db = new;
    CreatePostRequest req = {
        content: (),
        media_url: ()
    };

    Post|error result = createPost(db, 1, req);
    test:assertTrue(result is error, "Should return error if content and media are missing");
}

@test:Config {}
function testGetFeed() returns error? {
    record {}[] mockData = [
        {
            "id": 2,
            "user_id": 1,
            "content": "Newest Post",
            "media_url": (),
            "created_at": time:utcNow()
        },
        {
            "id": 1,
            "user_id": 1,
            "content": "Old Post",
            "media_url": (),
            "created_at": time:utcNow()
        }
    ];

    MockDbClient db = new(mockData);

    // Test with default limit/offset
    Post[] posts = check getFeed(db);
    test:assertEquals(posts.length(), 2);
    test:assertEquals(posts[0].content, "Newest Post");
    test:assertEquals(posts[1].content, "Old Post");
}
