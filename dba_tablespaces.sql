-- +-----------------------------------------------------------------+
SET LINESIZE 141
SET PAGESIZE 9999
SET VERIFY OFF
COLUMN status FORMAT a9 HEADING 'Status'
COLUMN name FORMAT a22 HEADING 'Tablespace Name'
COLUMN type FORMAT a12 HEADING 'TS Type'
COLUMN extent_mgt FORMAT a10 HEADING 'Ext. Mgt.'
COLUMN segment_mgt FORMAT a9 HEADING 'Seg. Mgt.'
COLUMN ts_size FORMAT 9,999,999,999,999 HEADING 'Tablespace Size'
COLUMN used FORMAT 9,999,999,999,999 HEADING 'Used (in bytes)'
COLUMN free FORMAT 9,999,999,999,999 HEADING 'Free (in bytes)'
COLUMN pct_used FORMAT 999 HEADING '. Used'
BREAK ON reportPct
COMPUTE SUM OF ts_size ON report
COMPUTE SUM OF used ON report
COMPUTE SUM OF free ON report
COMPUTE AVG OF pct_used ON report
SELECT
d.status status
, d.tablespace_name name
, d.contents type
, d.extent_management extent_mgt
, d.segment_space_management segment_mgt
, NVL(a.bytes, 0) ts_size
, NVL(a.bytes - NVL(f.bytes, 0), 0) used
-- , NVL(f.bytes, 0) free
, NVL((a.bytes - NVL(f.bytes, 0)) / a.bytes * 100, 0) pct_used
FROM
sys.dba_tablespaces d
, ( select tablespace_name, sum(bytes) bytes
from dba_data_files
group by tablespace_name
) a
, ( select tablespace_name, sum(bytes) bytes
from dba_free_space
group by tablespace_name
) f
WHERE
d.tablespace_name = a.tablespace_name(+)
AND d.tablespace_name = f.tablespace_name(+)
AND NOT (
d.extent_management like 'LOCAL'
AND
d.contents like 'TEMPORARY'
)
UNION ALL
SELECT
d.status status
, d.tablespace_name name
, d.contents type
, d.extent_management extent_mgt
, d.segment_space_management segment_mgt
, NVL(a.bytes, 0) ts_size
, NVL(t.bytes, 0) used
-- , NVL(a.bytes - NVL(t.bytes,0), 0) free
, NVL(t.bytes / a.bytes * 100, 0) pct_used
FROM
sys.dba_tablespaces d
, ( select tablespace_name, sum(bytes) bytes
from dba_temp_files
group by tablespace_name
) a
, ( select tablespace_name, sum(bytes_cached) bytes
from v$temp_extent_pool
group by tablespace_name
) t
WHERE
d.tablespace_name = a.tablespace_name(+)
AND d.tablespace_name = t.tablespace_name(+)
AND d.extent_management like 'LOCAL'
AND d.contents like 'TEMPORARY'
;
