import ballerina/sql;

public isolated function createPost(DbClient db, int userId, CreatePostRequest req) returns Post|error {
    if req.content == () && req.media_url == () {
        return error("Post must have content or media");
    }

    sql:ParameterizedQuery query = `
        INSERT INTO posts (user_id, content, media_url)
        VALUES (${userId}, ${req.content}, ${req.media_url})
        RETURNING id, user_id, content, media_url, created_at
    `;
    record {} result = check db->queryRow(query);
    return result.cloneWithType(Post);
}

public isolated function getFeed(DbClient db, int limitCount = 10, int offsetCount = 0) returns Post[]|error {
    if limitCount < 0 || offsetCount < 0 {
        return error("Limit and offset must be non-negative");
    }

    sql:ParameterizedQuery query = `
        SELECT id, user_id, content, media_url, created_at
        FROM posts
        ORDER BY created_at DESC
        LIMIT ${limitCount} OFFSET ${offsetCount}
    `;
    stream<record {}, sql:Error?> resultStream = db->query(query);

    Post[] posts = [];
    check from record {} post in resultStream
        do {
            posts.push(check post.cloneWithType(Post));
        };
    return posts;
}
