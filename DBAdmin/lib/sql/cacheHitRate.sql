
-- Display cache hit ratios; should be > .90
-- If not, increase db_block_buffers and/or shared_pool_size

SET ECHO OFF;
SET SERVEROUTPUT OFF;
SPOOL OFF;

SELECT 1.0 - ( v3.value / ( v1.value + v2.value)) as "Disk Buffer Cache Hit Ratio"
FROM v$sysstat v1, v$sysstat v2, v$sysstat v3
WHERE v1.name = 'db block gets'
AND v2.name = 'consistent gets'
and v3.name = 'physical reads';

select (sum(gets - getmisses - usage - fixed)) / sum(gets) as "Dictionary Cache Hit Ratio" 
from v$rowcache;

SPOOL OFF;
DISCONNECT;
EXIT;

