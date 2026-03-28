import ballerina/time;

public type Post record {|
    int id;
    int user_id;
    string? content;
    string? media_url;
    time:Utc created_at;
    int version = 1;
|};

public type CreatePostRequest record {|
    string? content;
    string? media_url;
|};

public type EditPostRequest record {|
    string? content;
    string? media_url;
    int version;
|};

public type FeedItem record {|
    string source_type; // "USER", "GROUP", "GLOBAL"
    int id;
    int author_id;
    string? content;
    string? media_url;
    time:Utc created_at;
    int? group_id = ();
|};
