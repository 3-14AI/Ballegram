import ballerina/http;

service / on new http:Listener(9090) {

    resource function get .() returns string {
        return "Ballegram API";
    }

    resource function get health() returns string {
        return "OK";
    }
}
