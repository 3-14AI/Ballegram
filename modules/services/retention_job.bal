import ballerina/task;
import ballerina/log;

// Job to delete private messages older than 5 years
class MessageRetentionJob {
    *task:Job;
    public function execute() {
        log:printInfo("Running MessageRetentionJob to delete old messages.");
        // 5 years in seconds: 5 * 365 * 24 * 60 * 60 = 157680000
        error? result = messageDb->deleteOldMessages(157680000);
        if result is error {
            log:printError("Error deleting old messages: " + result.message());
        } else {
            log:printInfo("Successfully deleted old messages.");
        }
    }
}

// Job to handle post retention
class PostRetentionJob {
    *task:Job;
    public function execute() {
        // According to the requirements, social posts must be stored indefinitely.
        // There is no action required to delete them. This job serves as explicit
        // acknowledgment of the "бессрочное хранение социальных публикаций" policy.
        log:printInfo("Running PostRetentionJob. Policy: indefinite storage. No deletion needed.");
    }
}

function init() returns error? {
    // Schedule jobs to run daily at midnight (approx 86400 seconds)
    // using scheduleJobRecurByFrequency
    do {
        _ = check task:scheduleJobRecurByFrequency(new MessageRetentionJob(), 86400.0);
        _ = check task:scheduleJobRecurByFrequency(new PostRetentionJob(), 86400.0);
        log:printInfo("Retention jobs scheduled successfully.");
    } on fail error e {
        log:printError("Failed to schedule retention jobs: " + e.message());
    }

    check startKafkaListener();
}
