
SET ECHO OFF;
SET SERVEROUTPUT OFF;
SPOOL OFF;

--Block size = 8192 bytes
--(see $ORACLE_HOME/admin/gus/pfile/initgus.ora, db_block_size init parameter)

-------------------------------------------------------
-- files_space_used_summary

create global temporary table files_space_used_summary (
  tablespace_name	varchar(30),
  file_id		number,
  current_bytes		number,
  max_bytes		number,
  free_bytes		number,
  autoextend_free_bytes	number
) on commit preserve rows;

insert into files_space_used_summary (tablespace_name, file_id, current_bytes, max_bytes)
select ddf.tablespace_name,
       ddf.file_id, 
       ddf.bytes,
       DECODE(ddf.maxbytes, 0, ddf.bytes, ddf.maxbytes)
from dba_data_files ddf;

update files_space_used_summary fsus
set free_bytes = (select sum(bytes) from dba_free_space where file_id = fsus.file_id);

update files_space_used_summary 
set autoextend_free_bytes = max_bytes - current_bytes;

-------------------------------------------------------
-- tablespaces_space_used_summary

create global temporary table tablespaces_space_used_summary (
  tablespace_name      varchar2(30)	  primary key not null,
  num_datafiles	       number,
  mb_avail	       number,
  mb_used	       number,
  mb_free	       number,
  pct_used	       number
) on commit preserve rows; 

insert into tablespaces_space_used_summary (tablespace_name, num_datafiles)
select ddf.tablespace_name,
       count(ddf.file_id)
from dba_data_files ddf
group by ddf.tablespace_name;
       
update tablespaces_space_used_summary sus
 set mb_avail = (select sum(max_bytes) / (1024 * 1024)
                 from files_space_used_summary fsus 
                 where fsus.tablespace_name = sus.tablespace_name);
       
update tablespaces_space_used_summary sus
 set mb_free = (select (sum(free_bytes) + sum(autoextend_free_bytes)) / (1024 * 1024)
                 from files_space_used_summary fsus 
                 where fsus.tablespace_name = sus.tablespace_name);

update tablespaces_space_used_summary set mb_used = mb_avail - mb_free;
update tablespaces_space_used_summary set pct_used = (mb_used / mb_avail) * 100;

-------------------------------------------------------
-- Display the summary data

SPOOL ON;

select tablespace_name,
       num_datafiles,
       TO_CHAR(mb_avail, '99999999') as mb_total, 
       TO_CHAR(mb_used, '99999999') as mb_used, 
       TO_CHAR(mb_free, '99999999') as mb_free, 
       CONCAT(TO_CHAR(pct_used, '999'), '%') as pct_used
from tablespaces_space_used_summary
order by mb_total asc;

SPOOL OFF;

commit;
drop table files_space_used_summary;
drop table tablespaces_space_used_summary;

DISCONNECT;
EXIT;
