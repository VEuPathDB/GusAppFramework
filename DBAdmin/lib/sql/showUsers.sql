
SPOOL ON;

column username format a30;
column created format a10;
column account_status format a33;
column default_tablespace format a30;
column temporary_tablespace format a30;

select username, created, account_status, default_tablespace, 
       temporary_tablespace 
from dba_users
order by created asc, account_status;

SPOOL OFF;
DISCONNECT;
EXIT;
