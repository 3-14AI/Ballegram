import ballerina/websocket;

public isolated class ConnectionManager {
    private map<websocket:Caller[]> connections = {};

    public isolated function addConnection(int userId, websocket:Caller caller) {
        lock {
            string key = userId.toString();
            if self.connections.hasKey(key) {
                self.connections.get(key).push(caller);
            } else {
                self.connections[key] = [caller];
            }
        }
    }

    public isolated function removeConnection(int userId, websocket:Caller caller) {
        lock {
            string key = userId.toString();
            if self.connections.hasKey(key) {
                websocket:Caller[] callers = self.connections.get(key);
                foreach int i in 0 ..< callers.length() {
                    if callers[i] === caller {
                        _ = callers.remove(i);
                        break;
                    }
                }
                if callers.length() == 0 {
                    _ = self.connections.remove(key);
                }
            }
        }
    }

    public isolated function broadcast(int[] userIds, anydata & readonly message) {
        foreach int userId in userIds {
            lock {
                string key = userId.toString();
                if self.connections.hasKey(key) {
                    websocket:Caller[] callers = self.connections.get(key);
                    foreach int i in 0 ..< callers.length() {
                        websocket:Caller caller = callers[i];
                        // Ignore errors during broadcast
                        // It's safe to invoke remote isolated methods within the lock block if we just ignore them
                        // However, writeMessage might be blocking. Ballerina allows it if caller is isolated object.
                        error? result = caller->writeMessage(message);
                        if result is error {
                            // Ignore
                        }
                    }
                }
            }
        }
    }
}
