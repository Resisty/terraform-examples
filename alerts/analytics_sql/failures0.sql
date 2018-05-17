CREATE OR REPLACE STREAM "DESTINATION_SQL_STREAM" (
    "message" varchar(256),
    "counter" bigint,
    "category" varchar(256),
    "gen_host" varchar(128),
    "job_id" varchar(64),
    "log_file" varchar(128),
    "tag" varchar(128),
    "COL_time" timestamp,
    "threshold" bigint);
-- Block for Disk Full Failures
-- Create a temporary stream to store Unit Test Failures
CREATE OR REPLACE STREAM "DISKFULLSTREAM" ( 
   "message" varchar(256),
   "category" varchar(256),
   "gen_host" varchar(128),
   "job_id" varchar(64),
   "log_file" varchar(128),
   "tag" varchar(128),
   "COL_time" timestamp);
-- Pump Disk Full Failures from source  into temporary stream
CREATE OR REPLACE PUMP "DISKFULLSTREAM_PUMP" AS
    INSERT INTO "DISKFULLSTREAM"
    SELECT STREAM
        "message",
        REGEX_REPLACE("message", '^.*[Nn]o space left on device.*$', 'Disk full failure!', 1, 0),
        "gen_host",
        "job_id",
        "log_file",
        "tag",
        "COL_time"
    FROM "SOURCE_SQL_STREAM_001";
-- Pump Disk Full Failures from temporary stream into destination
CREATE OR REPLACE PUMP "DISKFULL_DESTINATION_PUMP" AS
    INSERT INTO "DESTINATION_SQL_STREAM"
    SELECT STREAM
        "message",
        COUNT("category") OVER (
            PARTITION BY "category"
            RANGE INTERVAL '4' HOUR PRECEDING) AS counter,
        "category",
        "gen_host",
        "job_id",
        "log_file",
        "tag",
        "ROWTIME",
	${diskfull_threshold}
    FROM "DISKFULLSTREAM"
    WHERE "category" LIKE 'Disk full failure!';
