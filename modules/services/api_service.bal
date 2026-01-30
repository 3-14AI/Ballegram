import ballerina/http;

service / on ep {

    resource function get .() returns string {
        return "Ballegram API";
    }

    resource function get health() returns string {
        return "OK";
    }
}
