public enum StorageType {
    LOCAL,
    S3
}

public type StorageConfig record {|
    StorageType 'type;
    string path = "uploads";
    string bucket = "";
    string region = "";
    string accessKey = "";
    string secretKey = "";
|};

public type UploadResult record {|
    string url;
|};
