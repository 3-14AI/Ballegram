import ballerina/test;

@test:Config {}
function testInitializeWidget() {
    WidgetConfig config = initializeWidget(12345, "dark");
    test:assertEquals(config.corporateId, 12345);
    test:assertEquals(config.theme, "dark");
    test:assertEquals(config.isLive, true);
    test:assertTrue(config.sessionId.length() > 10);
}
