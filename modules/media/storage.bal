public type Storage isolated object {
    public isolated function upload(byte[] content, string filename) returns string|error;
};
