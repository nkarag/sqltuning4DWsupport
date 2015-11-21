-- ----------------------------------------------------------------------------------------------
--  ash_events.sql
--
--   Returns from Active Session History, for a specific sql id,
--   the most-waited Wait Events for the last N minutes.
--
--  PARAMETERS
--
--  1.  SQL_ID              (optional)      If not specified it will return results for ALL sql id in ASH!
--  2.  child_number        (optional)      Default 0
--  3.  minutes_from_now    (required)      Time interval for which you wish to examine ASH samples
--
-- (C) 2015 Nikos Karagiannidis - http://oradwstories.blogspot.com    
-- ----------------------------------------------------------------------------------------------


set pagesize 999
set lines 999
col object_name format a50
col object_type format a20

select sql_exec_start, event, decode(session_state, 'ON CPU', 'ON CPU', wait_class) wait_class_or_CPU,round(ratio_to_report(count(*)) over(partition by sql_exec_start) *100) PCNT, owner, object_name, object_type, count(*) nosamples, cnttot nosamplestot, P1TEXT, P2TEXT, P3TEXT 
    from (
		select sql_exec_start,   event, wait_class, P1TEXT, P2TEXT, P3TEXT, owner, object_name, object_type, session_state,  count(*) over(partition by sql_exec_start) cnttot
		from gv$active_session_history a left outer join dba_objects b on(a.CURRENT_OBJ# = b.object_id)
		where  
		SAMPLE_TIME > sysdate - (&minutes_from_now/(24*60))
		and ((session_state = 'WAITING' and WAIT_TIME = 0) or session_state ='ON CPU')
		and sql_id = nvl('&sql_id',sql_id)
		and SQL_CHILD_NUMBER = nvl('&SQL_CHILD_NUMBER',0)
		and sql_exec_id is not null
    )t
    group by sql_exec_start, event, wait_class, session_state, P1TEXT, P2TEXT, P3TEXT, owner, object_name, object_type, cnttot
    order by sql_exec_start desc, pcnt desc
/
