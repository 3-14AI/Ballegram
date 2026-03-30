import ballerina/http;
import ballegram.widgets;

service /widgets on ep {
    isolated resource function post chat/[int corporateId](http:Request req) returns widgets:WidgetConfig|http:InternalServerError {
        widgets:WidgetConfig config = widgets:initializeWidget(corporateId, "light");
        return config;
    }
}
