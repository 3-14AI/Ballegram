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
    int version = 1;
|};

public type Message record {|
    int id;
    int chat_id;
    int? sender_id;
    string content;
    time:Utc created_at;
    int version = 1;
    int[] read_by = [];
    int read_count = 0;
    boolean is_read = false;
|};

public type EditMessageRequest record {|
    string content;
    int version;
|};
