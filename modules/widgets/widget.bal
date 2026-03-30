import ballerina/uuid;

public type WidgetConfig record {|
    string sessionId;
    int corporateId;
    string theme;
    boolean isLive;
|};

public isolated function initializeWidget(int corporateId, string theme = "light") returns WidgetConfig {
    return {
        sessionId: uuid:createType4AsString(),
        corporateId: corporateId,
        theme: theme,
        isLive: true
    };
}
