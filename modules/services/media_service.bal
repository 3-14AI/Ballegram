import ballerina/http;
import ballerina/mime;

service /media on ep {

    isolated resource function post upload(http:Request req) returns http:Created|http:BadRequest|http:Unauthorized|http:InternalServerError {
        int|error userId = getUserId(req);
        if userId is error {
            return <http:Unauthorized> { body: "Unauthorized: " + userId.message() };
        }

        mime:Entity[]|http:ClientError parts = req.getBodyParts();
        if parts is http:ClientError {
            return <http:BadRequest> { body: "Invalid multipart request" };
        }

        int imageCount = 0;
        int audioCount = 0;

        // Count and validate first
        foreach var part in parts {
            string contentType = part.getContentType();
            if contentType.startsWith("image/") {
                imageCount += 1;
            } else if contentType.startsWith("audio/") {
                audioCount += 1;
            } else if part.getContentDisposition().fileName != "" {
                 // It's a file but neither image nor audio, maybe reject?
                 return <http:BadRequest> { body: "Unsupported file type: " + contentType };
            }
        }

        if imageCount > 5 {
            return <http:BadRequest> { body: "Maximum 5 images allowed per upload" };
        }

        string[] uploadedUrls = [];

        foreach var part in parts {
            string contentType = part.getContentType();
            if contentType.startsWith("image/") || contentType.startsWith("audio/") {
                mime:ContentDisposition disp = part.getContentDisposition();
                string fileName = disp.fileName;
                if fileName == "" {
                    continue;
                }

                byte[]|error content = part.getByteArray();
                if content is byte[] {
                    string|error uploadResult = storageClient.upload(content, fileName);
                    if uploadResult is string {
                        uploadedUrls.push(uploadResult);
                    } else {
                        return <http:InternalServerError> { body: "Failed to upload file: " + fileName };
                    }
                } else {
                     return <http:BadRequest> { body: "Failed to read file content" };
                }
            }
        }

        return <http:Created> { body: uploadedUrls };
    }
}
