# Registers a new user.
#
# + username - The username
# + password - The password
# + return - Error if registration fails
public function register(string username, string password) returns error? {
    // TODO: Implement registration
}

# Logs in a user.
#
# + username - The username
# + password - The password
# + return - JWT token or error
public function login(string username, string password) returns string|error {
    // TODO: Implement login
    return "dummy-token";
}
