import ballerina/grpc;
import ballegram.auth;

service "AuthService" on new grpc:Listener(9092) {

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
