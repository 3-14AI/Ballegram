import ballerina/grpc;
import ballerina/protobuf;

public const string AUTH_DESC = "0A0A617574682E70726F746F120962616C6C656772616D225F0A0F526567697374657252657175657374121A0A08757365726E616D651801200128095208757365726E616D6512140A05656D61696C1802200128095205656D61696C121A0A0870617373776F7264180320012809520870617373776F726422730A105265676973746572526573706F6E7365120E0A02696418012001280352026964121A0A08757365726E616D651802200128095208757365726E616D6512140A05656D61696C1803200128095205656D61696C121D0A0A637265617465645F6174180420012809520963726561746564417422460A0C4C6F67696E52657175657374121A0A08757365726E616D651801200128095208757365726E616D65121A0A0870617373776F7264180220012809520870617373776F726422250A0D4C6F67696E526573706F6E736512140A05746F6B656E1801200128095205746F6B656E328E010A0B417574685365727669636512430A085265676973746572121A2E62616C6C656772616D2E5265676973746572526571756573741A1B2E62616C6C656772616D2E5265676973746572526573706F6E7365123A0A054C6F67696E12172E62616C6C656772616D2E4C6F67696E526571756573741A182E62616C6C656772616D2E4C6F67696E526573706F6E7365620670726F746F33";

public isolated client class AuthServiceClient {
    *grpc:AbstractClientEndpoint;

    private final grpc:Client grpcClient;

    public isolated function init(string url, *grpc:ClientConfiguration config) returns grpc:Error? {
        self.grpcClient = check new (url, config);
        check self.grpcClient.initStub(self, AUTH_DESC, {});
    }

    isolated remote function Register(RegisterRequest|ContextRegisterRequest req) returns RegisterResponse|grpc:Error {
        map<string|string[]> headers = {};
        RegisterRequest message;
        if req is ContextRegisterRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("ballegram.AuthService/Register", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <RegisterResponse>result;
    }

    isolated remote function RegisterContext(RegisterRequest|ContextRegisterRequest req) returns ContextRegisterResponse|grpc:Error {
        map<string|string[]> headers = {};
        RegisterRequest message;
        if req is ContextRegisterRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("ballegram.AuthService/Register", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <RegisterResponse>result, headers: respHeaders};
    }

    isolated remote function Login(LoginRequest|ContextLoginRequest req) returns LoginResponse|grpc:Error {
        map<string|string[]> headers = {};
        LoginRequest message;
        if req is ContextLoginRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("ballegram.AuthService/Login", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <LoginResponse>result;
    }

    isolated remote function LoginContext(LoginRequest|ContextLoginRequest req) returns ContextLoginResponse|grpc:Error {
        map<string|string[]> headers = {};
        LoginRequest message;
        if req is ContextLoginRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("ballegram.AuthService/Login", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <LoginResponse>result, headers: respHeaders};
    }
}

public type ContextRegisterRequest record {|
    RegisterRequest content;
    map<string|string[]> headers;
|};

public type ContextRegisterResponse record {|
    RegisterResponse content;
    map<string|string[]> headers;
|};

public type ContextLoginResponse record {|
    LoginResponse content;
    map<string|string[]> headers;
|};

public type ContextLoginRequest record {|
    LoginRequest content;
    map<string|string[]> headers;
|};

@protobuf:Descriptor {value: AUTH_DESC}
public type RegisterRequest record {|
    string username = "";
    string email = "";
    string password = "";
|};

@protobuf:Descriptor {value: AUTH_DESC}
public type RegisterResponse record {|
    int id = 0;
    string username = "";
    string email = "";
    string created_at = "";
|};

@protobuf:Descriptor {value: AUTH_DESC}
public type LoginResponse record {|
    string token = "";
|};

@protobuf:Descriptor {value: AUTH_DESC}
public type LoginRequest record {|
    string username = "";
    string password = "";
|};