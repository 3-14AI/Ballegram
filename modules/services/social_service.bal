import ballerina/http;
import ballerina/jwt;
import ballegram.social;
import ballegram.auth;

// Helper function to extract user ID from JWT token
isolated function getUserId(http:Request req) returns int|error {
    string|http:HeaderNotFoundError header = req.getHeader("Authorization");
    if header is http:HeaderNotFoundError {
        return error("Missing Authorization header");
    }

    string token = header;
    if token.startsWith("Bearer ") {
        token = token.substring(7);
    }

    // Reuse auth config from context (available via auth:getJwtValidatorConfig or directly if accessible)
    // context.bal has 'authConfig'. But it is package-private in 'services' module.
    // So 'social_service.bal' can access 'authConfig' because it is in the same module 'services'.

    jwt:ValidatorConfig validatorConfig = auth:getJwtValidatorConfig(authConfig);
    jwt:Payload payload = check jwt:validate(token, validatorConfig);

    var uid = payload["uid"];
    if uid is int {
        return uid;
    }
    return error("Invalid user ID in token");
}

service /social on ep {

    // --- Likes ---

    isolated resource function post posts/[int postId]/like(http:Request req) returns http:Ok|http:Unauthorized|http:InternalServerError {
        int|error userId = getUserId(req);
        if userId is error {
            return <http:Unauthorized> { body: userId.message() };
        }

        error? result = social:likePost(db, userId, postId);
        if result is error {
            return <http:InternalServerError> { body: result.message() };
        }
        return <http:Ok>{};
    }

    isolated resource function delete posts/[int postId]/like(http:Request req) returns http:Ok|http:Unauthorized|http:InternalServerError {
        int|error userId = getUserId(req);
        if userId is error {
            return <http:Unauthorized> { body: userId.message() };
        }

        error? result = social:unlikePost(db, userId, postId);
        if result is error {
            return <http:InternalServerError> { body: result.message() };
        }
        return <http:Ok>{};
    }

    // --- Comments ---

    isolated resource function post posts/[int postId]/comments(http:Request req, @http:Payload social:CreateCommentRequest commentReq) returns http:Created|http:Unauthorized|http:InternalServerError|http:BadRequest {
        int|error userId = getUserId(req);
        if userId is error {
            return <http:Unauthorized> { body: userId.message() };
        }
        if commentReq.content == "" {
             return <http:BadRequest> { body: "Content cannot be empty" };
        }

        social:Comment|error comment = social:commentOnPost(db, userId, postId, commentReq.content);
        if comment is error {
            return <http:InternalServerError> { body: comment.message() };
        }

        social:CommentResponse response = {
            id: comment.id,
            user_id: comment.user_id,
            post_id: comment.post_id,
            content: comment.content,
            created_at: comment.created_at.toString(),
            username: () // Explicitly set optional field to nil
        };
        return <http:Created> { body: response };
    }

    isolated resource function get posts/[int postId]/comments() returns social:CommentResponse[]|http:InternalServerError {
        social:CommentWithUser[]|error comments = social:getComments(db, postId);
        if comments is error {
            return <http:InternalServerError> { body: comments.message() };
        }

        social:CommentResponse[] response = [];
        foreach var c in comments {
            response.push({
                id: c.id,
                user_id: c.user_id,
                post_id: c.post_id,
                content: c.content,
                created_at: c.created_at.toString(),
                username: c.username
            });
        }
        return response;
    }

    // --- Follows ---

    isolated resource function post users/[int userId]/follow(http:Request req) returns http:Ok|http:Unauthorized|http:InternalServerError|http:BadRequest {
        int|error followerId = getUserId(req);
        if followerId is error {
            return <http:Unauthorized> { body: followerId.message() };
        }

        if followerId == userId {
            return <http:BadRequest> { body: "Cannot follow yourself" };
        }

        error? result = social:followUser(db, followerId, userId);
        if result is error {
            return <http:InternalServerError> { body: result.message() };
        }
        return <http:Ok>{};
    }

    isolated resource function delete users/[int userId]/follow(http:Request req) returns http:Ok|http:Unauthorized|http:InternalServerError {
        int|error followerId = getUserId(req);
        if followerId is error {
            return <http:Unauthorized> { body: followerId.message() };
        }

        error? result = social:unfollowUser(db, followerId, userId);
        if result is error {
            return <http:InternalServerError> { body: result.message() };
        }
        return <http:Ok>{};
    }

    isolated resource function get users/[int userId]/followers() returns social:UserSummary[]|http:InternalServerError {
        social:UserSummary[]|error followers = social:getFollowers(db, userId);
        if followers is error {
            return <http:InternalServerError> { body: followers.message() };
        }
        return followers;
    }

    isolated resource function get users/[int userId]/following() returns social:UserSummary[]|http:InternalServerError {
        social:UserSummary[]|error following = social:getFollowing(db, userId);
        if following is error {
            return <http:InternalServerError> { body: following.message() };
        }
        return following;
    }

    isolated resource function get users(string q) returns social:UserSummary[]|http:InternalServerError {
        auth:User[]|error users = auth:searchUsers(db, q);
        if users is error {
            return <http:InternalServerError> { body: users.message() };
        }

        social:UserSummary[] summaries = [];
        foreach var user in users {
            summaries.push({
                id: user.id,
                username: user.username
            });
        }
        return summaries;
    }
}
