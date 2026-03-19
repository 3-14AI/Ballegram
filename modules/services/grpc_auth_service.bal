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

const string GRPC_AUTH_DESC = "0A0A617574682E70726F746F120962616C6C656772616D225F0A0F526567697374657252657175657374121A0A08757365726E616D651801200128095208757365726E616D6512140A05656D61696C1802200128095205656D61696C121A0A0870617373776F7264180320012809520870617373776F726422730A105265676973746572526573706F6E7365120E0A02696418012001280352026964121A0A08757365726E616D651802200128095208757365726E616D6512140A05656D61696C1803200128095205656D61696C121D0A0A637265617465645F6174180420012809520963726561746564417422460A0C4C6F67696E52657175657374121A0A08757365726E616D651801200128095208757365726E616D65121A0A0870617373776F7264180220012809520870617373776F726422250A0D4C6F67696E526573706F6E736512140A05746F6B656E1801200128095205746F6B656E328E010A0B417574685365727669636512430A085265676973746572121A2E62616C6C656772616D2E5265676973746572526571756573741A1B2E62616C6C656772616D2E5265676973746572526573706F6E7365123A0A054C6F67696E12172E62616C6C656772616D2E4C6F67696E526571756573741A182E62616C6C656772616D2E4C6F67696E526573706F6E7365620670726F746F33";
