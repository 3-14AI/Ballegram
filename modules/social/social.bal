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

public isolated function followUser(DbClient db, int followerId, int followingId) returns error? {
    if followerId == followingId {
        return error("Cannot follow yourself");
    }
    sql:ParameterizedQuery query = `
        INSERT INTO follows (follower_id, following_id)
        VALUES (${followerId}, ${followingId})
        ON CONFLICT (follower_id, following_id) DO NOTHING
        RETURNING follower_id
    `;
    GenericRecord|sql:Error result = db->queryRow(query);
    if result is sql:NoRowsError {
        // Already following, ignore
        return ();
    }
    if result is sql:Error {
        return result;
    }
}

public isolated function unfollowUser(DbClient db, int followerId, int followingId) returns error? {
    sql:ParameterizedQuery query = `
        DELETE FROM follows
        WHERE follower_id = ${followerId} AND following_id = ${followingId}
        RETURNING follower_id
    `;
    GenericRecord|sql:Error result = db->queryRow(query);
    if result is sql:NoRowsError {
        // Not following, ignore
        return ();
    }
    if result is sql:Error {
        return result;
    }
}

public isolated function getFollowers(DbClient db, int userId) returns UserSummary[]|error {
    sql:ParameterizedQuery query = `
        SELECT u.id, u.username
        FROM follows f
        JOIN users u ON f.follower_id = u.id
        WHERE f.following_id = ${userId}
    `;
    stream<GenericRecord, sql:Error?> resultStream = db->query(query);

    UserSummary[] followers = [];
    check from GenericRecord row in resultStream
        do {
            followers.push(check row.cloneWithType(UserSummary));
        };
    return followers;
}

public isolated function getFollowing(DbClient db, int userId) returns UserSummary[]|error {
    sql:ParameterizedQuery query = `
        SELECT u.id, u.username
        FROM follows f
        JOIN users u ON f.following_id = u.id
        WHERE f.follower_id = ${userId}
    `;
    stream<GenericRecord, sql:Error?> resultStream = db->query(query);

    UserSummary[] following = [];
    check from GenericRecord row in resultStream
        do {
            following.push(check row.cloneWithType(UserSummary));
        };
    return following;
}
