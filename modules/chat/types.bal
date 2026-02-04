import ballerina/time;

public enum ChatType {
    DIRECT = "DIRECT",
    GROUP = "GROUP"
}

public type Chat record {|
    int id;
    string? name;
    ChatType 'type;
    time:Utc created_at;
|};

public type Message record {|
    int id;
    int chat_id;
    int? sender_id;
    string content;
    time:Utc created_at;
|};
