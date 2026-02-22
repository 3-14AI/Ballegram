import ballerina/time;

public type Like record {|
    int user_id;
    int post_id;
    time:Utc created_at;
|};

public type Comment record {|
    int id;
    int user_id;
    int post_id;
    string content;
    time:Utc created_at;
|};

public type Follow record {|
    int follower_id;
    int following_id;
    time:Utc created_at;
|};

public type CreateCommentRequest record {|
    string content;
|};

public type CommentWithUser record {|
    *Comment;
    string username;
|};

public type UserSummary record {|
    int id;
    string username;
|};

public type CommentResponse record {|
    int id;
    int user_id;
    int post_id;
    string content;
    string created_at;
    string? username; // Optional, if we want to include username
|};
