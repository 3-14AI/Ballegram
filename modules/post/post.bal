import ballerina/sql;

public isolated function createPost(DbClient db, int userId, CreatePostRequest req) returns Post|error {
    if req.content is string {
        string postContent = <string>req.content;
        if postContent.length() > 4000 {
            return error("Post content exceeds 4000 characters limit");
        }
    }
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
    if req.content is string {
        string postContent = <string>req.content;
        if postContent.length() > 4000 {
            return error("Post content exceeds 4000 characters limit");
        }
    }
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

public isolated function getAggregatedFeed(DbClient db, int userId, int limitCount = 10, int offsetCount = 0) returns FeedItem[]|error {
    if limitCount < 0 || offsetCount < 0 {
        return error("Limit and offset must be non-negative");
    }

    // Query to aggregate:
    // 1. Global posts (from user themselves and maybe others if we follow them, but requirement says "от самого пользователя, групп и глобальной ленты" - meaning we can include all posts for 'global', or just all posts in the system for now as 'global feed', plus user's own posts, plus messages from groups the user is a participant of)
    // Actually, "от самого пользователя, групп и глобальной ленты" means:
    // - User's own posts ("USER" or "GLOBAL")
    // - All posts globally (could be just all posts) -> "GLOBAL"
    // - Group messages where user is a participant -> "GROUP"
    //
    // Let's do a UNION ALL:
    // SELECT 'GLOBAL' as source_type, p.id, p.user_id as author_id, p.content, p.media_url, p.created_at, NULL as group_id FROM posts p
    // UNION ALL
    // SELECT 'GROUP' as source_type, m.id, m.sender_id as author_id, m.content, NULL as media_url, m.created_at, m.chat_id as group_id
    // FROM messages m
    // JOIN chats c ON m.chat_id = c.id
    // JOIN chat_participants cp ON c.id = cp.chat_id
    // WHERE c.type = 'GROUP' AND cp.user_id = ${userId}
    // ORDER BY created_at DESC LIMIT ${limitCount} OFFSET ${offsetCount}

    sql:ParameterizedQuery query = `
        SELECT 'GLOBAL' as source_type, p.id, p.user_id as author_id, p.content, p.media_url, p.created_at, NULL as group_id
        FROM posts p
        UNION ALL
        SELECT 'GROUP' as source_type, m.id, m.sender_id as author_id, m.content, NULL as media_url, m.created_at, m.chat_id as group_id
        FROM messages m
        JOIN chats c ON m.chat_id = c.id
        JOIN chat_participants cp ON c.id = cp.chat_id
        WHERE c.type = 'GROUP' AND cp.user_id = ${userId}
        ORDER BY created_at DESC
        LIMIT ${limitCount} OFFSET ${offsetCount}
    `;

    stream<GenericRecord, sql:Error?> resultStream = db->query(query);

    FeedItem[] feed = [];
    check from GenericRecord row in resultStream
        do {
            feed.push(check row.cloneWithType(FeedItem));
        };
    return feed;
}
