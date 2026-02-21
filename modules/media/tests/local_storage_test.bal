import ballerina/test;
import ballerina/file;
import ballerina/io;

@test:Config {}
function testLocalStorage() returns error? {
    string tempDir = check file:createTempDir();
    string uploadDir = check file:joinPath(tempDir, "uploads");

    // Initialize LocalStorage with a subdirectory inside temp dir
    LocalStorage storage = check new(uploadDir);

    byte[] content = "Hello Ballerina Storage".toBytes();
    string filename = "test_file.txt";

    // Perform upload
    string uploadedPath = check storage.upload(content, filename);

    // Verify file existence
    boolean exists = check file:test(uploadedPath, file:EXISTS);
    test:assertTrue(exists, "Uploaded file should exist on disk");

    // Verify content
    byte[] readContent = check io:fileReadBytes(uploadedPath);
    test:assertEquals(readContent, content, "File content should match");

    // Cleanup
    check file:remove(tempDir, file:RECURSIVE);
}
