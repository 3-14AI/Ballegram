import ballerina/grpc;

listener grpc:Listener ep = new (9090);

@grpc:Descriptor {value: AUTH_DESC}
service "AuthService" on ep {

    remote function Register(RegisterRequest value) returns RegisterResponse|error {
    }

    remote function Login(LoginRequest value) returns LoginResponse|error {
    }
}
