
-- Free space in various areas of the SGA

SET ECHO OFF;
SET SERVEROUTPUT OFF;
SPOOL OFF;

select * from v$sgastat where name = 'free memory';

SPOOL OFF;
DISCONNECT;
EXIT;
