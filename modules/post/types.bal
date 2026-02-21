import ballerina/time;

public type Post record {|
    int id;
    int user_id;
    string? content;
    string? media_url;
    time:Utc created_at;
|};

public type CreatePostRequest record {|
    string? content;
    string? media_url;
|};
