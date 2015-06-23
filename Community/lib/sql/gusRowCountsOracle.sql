-- generate a row-count for every GUS table
-- (where a GUS table is one represented in core.TableInfo)

-- turn out console output
set termout off

-- query GUS core tables to make a row-count query for each table
spool gusRowCountQ.lst
select 'select ''rowz '' || count(*) || '' ' || gus_table
       || ''' as rowcount from ' || gus_table || ';' as q
from (select distinct lower(di.name) || '.' || ti.name as gus_table
      from all_tables at, core.TableInfo ti, core.DatabaseInfo di
      where ti.database_id = di.database_id
        and upper(di.name) = at.owner
        and upper(ti.name) = at.table_name
        and at.owner not like '%VER'
        -- and at.owner != 'APIDB'
     )
order by gus_table;
spool off

-- separate queries from fluff
!grep rowz gusRowCountQ.lst > gusRowCountQ.sql
!rm gusRowCountQ.lst

-- run row-count queries
spool gusRowCountOut.lst
@gusRowCountQ
spool off
!rm gusRowCountQ.sql

-- grep to find data lines and lose zero-row lines; sed for cleanup
set termout on
!grep rowz gusRowCountOut.lst | grep -v 'rowz 0' | sed 's/rowz //' | sed 's/ *$//' | sed 's/ /	/'
!rm gusRowCountOut.lst
