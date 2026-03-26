import ballerina/test;

@test:Config {}
function testRouteEventMessage() returns error? {
    json payload = {
        id: 1,
        chat_id: 10,
        sender_id: 2,
        content: "hello kafka",
        created_at: [1, 0.0]
    };

    json chatEvent = {
        eventType: "NEW_MESSAGE",
        participants: [1, 2],
        payload: payload
    };

    check routeEvent(chatEvent);
}

@test:Config {}
function testRouteEventSocial() returns error? {
    json socialEvent = {
        eventType: "LIKE",
        postId: 100,
        userId: 2
    };

    check routeEvent(socialEvent);
}
