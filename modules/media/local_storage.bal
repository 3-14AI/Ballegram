import ballerina/io;
import ballerina/file;
import ballerina/uuid;

public isolated class LocalStorage {
    // Explicitly state adherence to the interface for clarity,
    // though structural typing handles it.
    *Storage;

    private final string uploadDir;

    public isolated function init(string path) returns error? {
        self.uploadDir = path;
        // Check if directory exists, if not create it.
        // Note: file:test and file:createDir are isolated operations on the file system.
        boolean exists = check file:test(self.uploadDir, file:EXISTS);
        if !exists {
            check file:createDir(self.uploadDir, file:RECURSIVE);
        }
    }

    public isolated function upload(byte[] content, string filename) returns string|error {
        // Generate a unique filename using UUID to prevent collisions
        string uniqueId = uuid:createType1AsString();
        string safeFilename = uniqueId + "_" + filename;

        // Construct the full path
        string filePath = check file:joinPath(self.uploadDir, safeFilename);

        // Write content to file
        check io:fileWriteBytes(filePath, content);

        // Return the path relative to the upload directory or just the filename
        // depending on how the frontend expects to access it.
        // For now, returning the filename which can be used to construct a URL.
        // Or better, return the relative path from the static root.
        // Let's return the full path for now, the service layer can map it to a URL.
        return filePath;
    }
}
