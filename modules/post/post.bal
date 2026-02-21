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
