WITH pgaudit_session_truncate_log AS (
    SELECT
        log_time_ist,
        session_id,
        session_line_num,
        statement_id,
        substatement_id,
        class,
        command,
        object_type,
        object_name,
        CASE
            WHEN command = 'INSERT' AND row_count > 1 AND statement ~* '(?i)INSERT\s+INTO.*VALUES.*\).*,.*\(' THEN
            regexp_replace(
                statement,
                '(?i)(?<![a-zA-Z0-9_-])(INSERT\s+INTO\s+[a-zA-Z0-9_.]+(?:\s*\([^)]*\))?\s*VALUES\s*\([^)]*(?:\([^)]*\)[^)]*)*\))(\s*,[\s\S]*?)(?=;|$|(?:\r?\n|\r)(?:\s*\b))',
                '\1, (...) [statement truncated]',
                'g'
            )
            ELSE statement
        END AS statement,
        parameters,
        row_count,
        CAST(:batch_time_ist AS TIMESTAMP(3)) AS batch_time_ist,
        :log_file_path AS log_file_path
    FROM stg.pgaudit_session_log
)
MERGE INTO landing.pgaudit_session_log AS target
USING pgaudit_session_truncate_log AS source
    ON target.session_id = source.session_id
    AND target.session_line_num = source.session_line_num
WHEN NOT MATCHED THEN
INSERT (log_time_ist, session_id, session_line_num, statement_id, substatement_id, class, command, object_type, object_name, statement, parameters, row_count, batch_time_ist, log_file_path)
VALUES (source.log_time_ist, source.session_id, source.session_line_num, source.statement_id, source.substatement_id, source.class, source.command, source.object_type, source.object_name, source.statement, source.parameters, source.row_count, source.batch_time_ist, source.log_file_path)
;