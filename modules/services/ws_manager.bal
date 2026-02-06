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

    public isolated function broadcast(int[] userIds, anydata message) {
        foreach int userId in userIds {
            websocket:Caller[] targetCallers = [];
            lock {
                string key = userId.toString();
                if self.connections.hasKey(key) {
                    // Create a shallow copy of the array
                    websocket:Caller[] existing = self.connections.get(key);
                    foreach var c in existing {
                        targetCallers.push(c);
                    }
                }
            }

            foreach websocket:Caller caller in targetCallers {
                // Ignore errors during broadcast
                var res = caller->writeMessage(message);
            }
        }
    }
}
