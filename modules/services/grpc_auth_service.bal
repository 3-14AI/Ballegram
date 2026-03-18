import ballerina/grpc;
import ballegram.auth;

@grpc:ServiceDescriptor {
    descriptor: GRPC_AUTH_DESC,
    descMap: {}
}
service "ballegram.AuthService" on new grpc:Listener(9092) {

    remote function Register(RegisterRequest req) returns RegisterResponse|error {
        if req.username == "" || req.email == "" || req.password == "" {
             return error grpc:InvalidArgumentError("Missing required fields");
        }

        auth:User|error user = auth:register(db, req.username, req.email, req.password);
        if user is error {
            return error grpc:InternalError(user.message());
        }

        RegisterResponse response = {
            id: user.id,
            username: user.username,
            email: user.email,
            created_at: user.created_at.toString()
        };

        return response;
    }

    remote function Login(LoginRequest req) returns LoginResponse|error {
        if req.username == "" || req.password == "" {
            return error grpc:InvalidArgumentError("Missing required fields");
        }

        string|error token = auth:login(db, req.username, req.password, authConfig);
        if token is error {
            return error grpc:UnauthenticatedError("Invalid credentials");
        }

        return { token: token };
    }
}

const string GRPC_AUTH_DESC = "CgphdXRoLnByb3RvEgliYWxsZWdyYW0iUAoPUmVnaXN0ZXJSZXF1ZXN0EhAKCHVzZXJuYW1lGAEgASgJEg0KBWVtYWlsGAIgASgJEhwKCHBhc3N3b3JkGAMgASgJIlsKEFJlZ2lzdGVyUmVzcG9uc2USCgoCaWQYASABKAMSFAoIdXNlcm5hbWUYAiABKAkSDQoFZW1haWwYAyABKAkSFgoKY3JlYXRlZF9hdBgEIAEoCSI0CgxMb2dpblJlcXVlc3QSEAoIdXNlcm5hbWUYASABKAkSEgoIcGFzc3dvcmQYAiABKAkiHgoNTG9naW5SZXNwb25zZRINCgV0b2tlbhgBIAEoCTqUAQoLQXV0aFNlcnZpY2USRgoIUmVnaXN0ZXISGi5iYWxsZWdyYW0uUmVnaXN0ZXJSZXF1ZXN0GhouYmFsbGVncmFtLlJlZ2lzdGVyUmVzcG9uc2USPQoFTG9naW4SFy5iYWxsZWdyYW0uTG9naW5SZXF1ZXN0GhguYmFsbGVncmFtLkxvZ2luUmVzcG9uc2ViBnByb3RvMw==";
