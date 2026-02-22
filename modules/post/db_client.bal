import ballerina/sql;

public type GenericRecord record {};

public type DbClient client object {
    isolated remote function queryRow(sql:ParameterizedQuery sqlQuery, typedesc<GenericRecord>? rowType = ()) returns GenericRecord|sql:Error;
    isolated remote function query(sql:ParameterizedQuery sqlQuery, typedesc<GenericRecord>? rowType = ()) returns stream<GenericRecord, sql:Error?>;
};
