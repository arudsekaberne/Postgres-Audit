BEGIN;

-- a) Fetch only pgaudit session log
CREATE TEMP TABLE temp_pgaudit_session_log
ON COMMIT DROP AS
SELECT
	log_time_ist, session_id, session_line_num, parse_csv_value(SUBSTRING(message, 16)) AS pgaudit_log
FROM stg.postgre_log
WHERE message LIKE 'AUDIT: SESSION,%'
;

-- b) Split pgaudit logs into multiple columns
CREATE TEMP TABLE temp_pgaudit_session_split_log
ON COMMIT DROP AS
SELECT
	log_time_ist,
	session_id,
	session_line_num,
	TRIM(pgaudit_log[1])::INT AS statement_id,
	TRIM(pgaudit_log[2])::INT AS substatement_id,
	TRIM(pgaudit_log[3]) AS class,
	TRIM(pgaudit_log[4]) AS command,
	TRIM(pgaudit_log[5]) AS object_type,
	TRIM(pgaudit_log[6]) AS object_name,
	TRIM(pgaudit_log[7]) AS statement,
    TRIM(pgaudit_log[8]) AS parameters,
	TRIM(pgaudit_log[9])::INT AS row_count
FROM temp_pgaudit_session_log
;

-- c) Parse empty values
CREATE TEMP TABLE temp_pgaudit_session_parsed_log
ON COMMIT DROP AS
SELECT
	log_time_ist,
	session_id,
	session_line_num,
	statement_id,
	substatement_id,
	CASE WHEN class = '' THEN NULL ELSE class END,
    CASE WHEN command = '' THEN NULL ELSE command END,
    CASE WHEN object_type = '' THEN NULL ELSE object_type END,
    CASE WHEN object_name = '' THEN NULL ELSE object_name END,
    CASE WHEN statement = '' THEN NULL ELSE statement END,
    CASE WHEN parameters = '' OR parameters = '<none>' THEN NULL ELSE parameters END,		
	row_count
FROM temp_pgaudit_session_split_log
;

-- d) Fill missing object type and object name 
TRUNCATE TABLE stg.pgaudit_session_log;
INSERT INTO stg.pgaudit_session_log
SELECT 
	log_time_ist,
	session_id,
	session_line_num,
	statement_id,
	substatement_id,
	class,
	command,
	CASE
		WHEN log.command IN ('CREATE EXTENSION') THEN 'EXTENSION'
		WHEN log.command IN ('DROP FUNCTION') THEN 'FUNCTION'
		WHEN log.command IN ('DROP INDEX') THEN 'INDEX'
		WHEN log.command IN ('ALTER TABLE', 'COPY', 'CREATE TABLE', 'DROP TABLE', 'TRUNCATE TABLE') THEN 'TABLE'
		WHEN log.command IN ('DROP VIEW', 'DROP MATERIALIZED VIEW') THEN 'VIEW'
	    ELSE log.object_type
	END AS object_type,
	COALESCE(
		log.object_name,
		CASE
			WHEN match.schema_name IS NOT NULL AND match.table_name IS NOT NULL THEN match.schema_name || '.' || match.table_name
			WHEN match.schema_name IS NULL THEN match.table_name
			ELSE match.schema_name
		END
	) AS object_name,
	statement,
	parameters,
	row_count
FROM temp_pgaudit_session_parsed_log AS log
LEFT JOIN LATERAL (
    SELECT 
        REGEXP_MATCHES(
            log.statement,
            CASE
				WHEN log.command = 'ALTER TABLE' THEN '(?i)ALTER\s+TABLE\s+(?:(\w+)\.)?(\w+)'
				WHEN log.command = 'COPY' THEN '(?i)copy\s+(?:([a-zA-Z_][\w]*)\.)?([a-zA-Z_][\w]*)\s+from'
				WHEN log.command = 'CREATE EXTENSION' THEN '(?i)CREATE\s+EXTENSION\s+(\w+)'
				WHEN log.command = 'CREATE TABLE' AND UPPER(TRIM(log.statement)) LIKE '%PARTITION OF%FOR VALUES%' THEN '(?i)partition\s+of\s+([a-zA-Z_][\w]*)\s*\.\s*([a-zA-Z_][\w]*)'
				WHEN log.command = 'CREATE TABLE' AND UPPER(TRIM(log.statement)) LIKE '%CREATE TEMP TABLE%' THEN '(?i)CREATE\s+TEMP[ORARY]*\s+TABLE\s+(?:(\w+)\.)?(\w+)'
				WHEN log.command = 'DROP FUNCTION' THEN '(?i)DROP\s+FUNCTION(?:\s+IF\s+EXISTS)?\s+(?:(\w+)\.)?(\w+)\s*\([^)]*\)'
				WHEN log.command = 'DROP INDEX' THEN '(?i)drop\s+index(?:\s+if\s+exists)?\s+(?:([a-zA-Z_][\w]*)\.)?([a-zA-Z_][\w]*)'
				WHEN log.command = 'DROP MATERIALIZED VIEW' THEN '(?i)DROP\s+MATERIALIZED\s+VIEW(?:\s+IF\s+EXISTS)?\s+(?:(\w+)\.)?(\w+)'
                WHEN log.command = 'DROP TABLE' THEN '(?i)drop\s+table(?:\s+if\s+exists)?\s+(?:([a-zA-Z_][\w]*)\.)?([a-zA-Z_][\w]*)'
				WHEN log.command = 'DROP VIEW' THEN '(?i)drop\s+view(?:\s+if\s+exists)?\s+(?:([a-zA-Z_][\w]*)\.)?([a-zA-Z_][\w]*)'
				WHEN log.command = 'TRUNCATE TABLE' THEN '(?i)truncate\s+(?:[t]able\s+)?(?:([a-zA-Z_][\w]*)\.)?([a-zA-Z_][\w]*)'
            END
        ) AS match
) AS raw_match
	ON (log.command IN ('ALTER TABLE', 'COPY', 'CREATE EXTENSION', 'DROP FUNCTION', 'DROP INDEX', 'DROP MATERIALIZED VIEW', 'DROP TABLE', 'DROP VIEW', 'TRUNCATE TABLE'))
	OR (log.command = 'CREATE TABLE' AND UPPER(TRIM(log.statement)) LIKE '%PARTITION OF%FOR VALUES%')
	OR (log.command = 'CREATE TABLE' AND UPPER(TRIM(log.statement)) LIKE '%CREATE TEMP TABLE%')
CROSS JOIN LATERAL (
    SELECT 
        raw_match.match[1] AS schema_name,
        raw_match.match[2] AS table_name
) AS match
WHERE UPPER(TRIM(command)) NOT IN ('EXPLAIN')
;

COMMIT;