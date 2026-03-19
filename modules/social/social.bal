import ballerina/sql;

// Interaction: Likes

public isolated function likePost(DbClient db, int userId, int postId) returns error? {
    sql:ParameterizedQuery query = `
        INSERT INTO likes (user_id, post_id)
        VALUES (${userId}, ${postId})
        ON CONFLICT (user_id, post_id) DO NOTHING
        RETURNING user_id
    `;
    GenericRecord|sql:Error result = db->queryRow(query);
    if result is sql:NoRowsError {
        // Already liked, ignore
        return ();
    }
    if result is sql:Error {
        return result;
    }
}

public isolated function unlikePost(DbClient db, int userId, int postId) returns error? {
    sql:ParameterizedQuery query = `
        DELETE FROM likes
        WHERE user_id = ${userId} AND post_id = ${postId}
        RETURNING user_id
    `;
    GenericRecord|sql:Error result = db->queryRow(query);
    if result is sql:NoRowsError {
        // Not liked, ignore
        return ();
    }
    if result is sql:Error {
        return result;
    }
}

// Interaction: Comments

public isolated function commentOnPost(DbClient db, int userId, int postId, string content) returns Comment|error {
    sql:ParameterizedQuery query = `
        INSERT INTO comments (user_id, post_id, content)
        VALUES (${userId}, ${postId}, ${content})
        RETURNING id, user_id, post_id, content, created_at
    `;
    GenericRecord result = check db->queryRow(query);
    return result.cloneWithType(Comment);
}

public isolated function getComments(DbClient db, int postId) returns CommentWithUser[]|error {
    sql:ParameterizedQuery query = `
        SELECT c.id, c.user_id, c.post_id, c.content, c.created_at, u.username
        FROM comments c
        JOIN users u ON c.user_id = u.id
        WHERE c.post_id = ${postId}
        ORDER BY c.created_at ASC
    `;
    stream<GenericRecord, sql:Error?> resultStream = db->query(query);

    CommentWithUser[] comments = [];
    check from GenericRecord row in resultStream
        do {
            comments.push(check row.cloneWithType(CommentWithUser));
        };
    return comments;
}

// Interaction: Follows

public isolated function followUser(GraphClient graphDb, int followerId, int followingId) returns error? {
    return graphDb->followUser(followerId, followingId);
}

public isolated function unfollowUser(GraphClient graphDb, int followerId, int followingId) returns error? {
    return graphDb->unfollowUser(followerId, followingId);
}

public isolated function getFollowers(GraphClient graphDb, DbClient db, int userId) returns UserSummary[]|error {
    int[] followerIds = check graphDb->getFollowers(userId);
    return resolveUsers(db, followerIds);
}

public isolated function getFollowing(GraphClient graphDb, DbClient db, int userId) returns UserSummary[]|error {
    int[] followingIds = check graphDb->getFollowing(userId);
    return resolveUsers(db, followingIds);
}

isolated function resolveUsers(DbClient db, int[] userIds) returns UserSummary[]|error {
    if userIds.length() == 0 {
        return [];
    }

    sql:ParameterizedQuery query = `SELECT id, username FROM users WHERE id IN (`;
    foreach int i in 0 ..< userIds.length() {
        if i > 0 {
             query = sql:queryConcat(query, `,`);
        }
        int cur = userIds[i];
        query = sql:queryConcat(query, `${cur}`);
    }
    query = sql:queryConcat(query, `)`);

    stream<GenericRecord, sql:Error?> resultStream = db->query(query);

    UserSummary[] summaries = [];
    check from GenericRecord row in resultStream
        do {
            summaries.push(check row.cloneWithType(UserSummary));
        };
    return summaries;
}
