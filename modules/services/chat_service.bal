import ballerina/websocket;

service /chat on new websocket:Listener(9091) {

    resource function get .() returns websocket:Service|websocket:Error {
        return new ChatService();
    }
}

service class ChatService {
    *websocket:Service;

    remote function onOpen(websocket:Caller caller) returns error? {
        // io:println("New connection");
    }

    remote function onMessage(websocket:Caller caller, string text) returns error? {
        check caller->writeMessage("Echo: " + text);
    }
}
