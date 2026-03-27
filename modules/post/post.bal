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
    GenericRecord result = check db->queryRow(query);
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
    stream<GenericRecord, sql:Error?> resultStream = db->query(query);

    Post[] posts = [];
    check from GenericRecord post in resultStream
        do {
            posts.push(check post.cloneWithType(Post));
        };
    return posts;
}

public isolated function editPost(DbClient db, int postId, int userId, EditPostRequest req) returns Post|error {
    sql:ParameterizedQuery query = `
        UPDATE posts
        SET content = ${req.content}, media_url = ${req.media_url}, version = ${req.version} + 1
        WHERE id = ${postId} AND user_id = ${userId} AND version <= ${req.version}
        RETURNING id, user_id, content, media_url, created_at, version
    `;
    GenericRecord|sql:Error result = db->queryRow(query);
    if result is sql:NoRowsError {
        return error("Post not found, unauthorized, or version conflict");
    }
    if result is error {
        return result;
    }
    return result.cloneWithType(Post);
}
