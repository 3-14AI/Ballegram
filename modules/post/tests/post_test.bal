import ballerina/sql;
import ballerina/test;
import ballerina/time;

public isolated client class MockDbClient {
    *DbClient;

    public isolated remote function queryRow(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns record {}|sql:Error {
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

    public isolated remote function query(sql:ParameterizedQuery sqlQuery, typedesc<record {}>? rowType = ()) returns stream<record {}, sql:Error?> {
        // Not used in createPost, returning empty stream
        return new stream<record {}, sql:Error?>(new MockStream());
    }
}

public isolated class MockStream {
    public isolated function next() returns record {| record {} value; |}|sql:Error? {
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
