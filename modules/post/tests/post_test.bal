import ballerina/sql;
import ballerina/test;
import ballerina/time;

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
        return {
            "id": 1,
            "user_id": 1,
            "content": "Test Content",
            "media_url": "http://example.com/image.jpg",
            "version": 1,
            "created_at": time:utcNow()
        };
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
    GenericRecord[] mockData = [
        {
            "id": 2,
            "user_id": 1,
            "content": "Newest Post",
            "media_url": (),
        "version": 1,
            "created_at": time:utcNow()
        },
        {
            "id": 1,
            "user_id": 1,
            "content": "Old Post",
            "media_url": (),
        "version": 1,
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

@test:Config {}
function testEditPost() returns error? {
    MockDbClient db = new([{
        "id": 1,
        "user_id": 1,
        "content": "Updated Content",
        "media_url": "http://example.com/updated.jpg",
        "created_at": time:utcNow(),
        "version": 2
    }]);

    EditPostRequest req = {
        content: "Updated Content",
        media_url: "http://example.com/updated.jpg",
        version: 1
    };

    Post post = check editPost(db, 1, 1, req);

    test:assertEquals(post.id, 1);
    test:assertEquals(post.user_id, 1);
    test:assertEquals(post.content, "Updated Content");
    test:assertEquals(post.media_url, "http://example.com/updated.jpg");
    test:assertEquals(post.version, 2);
}

@test:Config {}
function testGetAggregatedFeed() returns error? {
    GenericRecord[] mockData = [
        {
            "source_type": "GROUP",
            "id": 100,
            "author_id": 2,
            "content": "Group message",
            "media_url": (),
            "created_at": time:utcNow(),
            "group_id": 10
        },
        {
            "source_type": "GLOBAL",
            "id": 50,
            "author_id": 1,
            "content": "Global post",
            "media_url": "http://example.com/pic.jpg",
            "created_at": time:utcNow(),
            "group_id": ()
        }
    ];

    MockDbClient db = new(mockData);

    FeedItem[] feedItems = check getAggregatedFeed(db, 1);
    test:assertEquals(feedItems.length(), 2);
    test:assertEquals(feedItems[0].source_type, "GROUP");
    test:assertEquals(feedItems[0].id, 100);
    test:assertEquals(feedItems[1].source_type, "GLOBAL");
    test:assertEquals(feedItems[1].id, 50);
}
