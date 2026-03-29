import ballerina/websocket;

public isolated class LinkManager {
    private final map<websocket:Caller> callers = {};
    private final map<string> publicKeys = {};
    private final map<string> callerToLinkId = {};

    public isolated function init() {}

    public isolated function addSession(string linkId, string publicKey, websocket:Caller caller) {
        lock {
            self.callers[linkId] = caller;
            self.publicKeys[linkId] = publicKey;
            self.callerToLinkId[caller.getConnectionId()] = linkId;
        }
    }

    public isolated function getPublicKey(string linkId) returns string? {
        lock {
            return self.publicKeys[linkId];
        }
    }

    public isolated function getCaller(string linkId) returns websocket:Caller? {
        lock {
            return self.callers[linkId];
        }
    }

    public isolated function removeSession(string linkId) {
        lock {
            websocket:Caller? caller = self.callers[linkId];
            if caller is websocket:Caller {
                _ = self.callerToLinkId.removeIfHasKey(caller.getConnectionId());
            }
            _ = self.callers.removeIfHasKey(linkId);
            _ = self.publicKeys.removeIfHasKey(linkId);
        }
    }

    public isolated function removeSessionByCaller(websocket:Caller caller) {
        lock {
            string? linkId = self.callerToLinkId[caller.getConnectionId()];
            if linkId is string {
                _ = self.callers.removeIfHasKey(linkId);
                _ = self.publicKeys.removeIfHasKey(linkId);
                _ = self.callerToLinkId.removeIfHasKey(caller.getConnectionId());
            }
        }
    }
}

public final LinkManager linkManager = new;
