
service / on ep {

    isolated resource function get .() returns string {
        return "Ballegram API";
    }

    isolated resource function get health() returns string {
        return "OK";
    }
}
