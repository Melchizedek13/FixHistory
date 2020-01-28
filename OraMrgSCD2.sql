-- truncate table test_src;
-- truncate table test_trg;

-- ############################# DDL/DML SRC ################################## --
create table test_src
(
    c1_bk     varchar(100),
    c2_v1     varchar(20),
    c3_v2     number,
    load_dt   date
);
insert all
  into test_src (c1_bk, c2_v1, c3_v2, load_dt) values ('ключ_1', 'c109', 99, trunc(sysdate)-10)
  into test_src (c1_bk, c2_v1, c3_v2, load_dt) values ('ключ_2', 'c209', 99, trunc(sysdate)-10)
  into test_src (c1_bk, c2_v1, c3_v2, load_dt) values ('ключ_3', 'c309', 99, trunc(sysdate)-10)
select * 
  from dual;
commit;
-- ############################# DDL/DML TRG ################################## --
create table test_trg
(
    c1_hk        raw(20) not null,
    c2_v1        varchar(20),
    c3_v2        number,
    load_dt      date,
    load_end_dt  date    not null,
    checksum     number,
    constraint test_trg_pk primary key (c1_hk, load_end_dt)
);

insert into test_trg(c1_hk, c2_v1, c3_v2, load_dt, load_end_dt, checksum)
  with t(c1,c2,c3,sd,ed) as (
    select 'ключ_1', 'c101', 10, date'2018-01-01', date'2018-02-01' from dual union all
    select 'ключ_1', 'c102', 20, date'2018-02-03', date'9999-12-31' from dual union all
    select 'ключ_2', 'c309', 30, trunc(sysdate)-10,   date'9999-12-31' from dual
  ) select standard_hash('test'||c1), c2, c3, sd, ed, ora_hash(c2||c3)
    from t;
commit;
-- ############################# Slowly Change Dimension Type 2 Merge ################################## --
-- deleted records at the source are not taken into account + backdating

merge /*enable_parallel_dml parallel(14) nologging*/ into test_trg trg
   using (
     select /*parallel(14)*/ standard_hash('test'||c1_bk) c1_hk, 
            c2_v1,c3_v2,load_dt,load_end_dt,ora_hash(c2_v1||c3_v2) checksum
       from (
         select c1_bk,   c2_v1,   c3_v2,   load_dt,   date'9999-12-31' load_end_dt from test_src union all
         select i.c1_bk, i.c2_v1, i.c3_v2, i.load_dt, date'1111-11-11' load_end_dt
           from test_src i
                left join test_trg t
                       on standard_hash('test'||i.c1_bk) = t.c1_hk
                      and t.load_end_dt = date'9999-12-31'
          where t.c1_hk is null or ora_hash(i.c2_v1||i.c3_v2) != t.checksum
       )
   ) src 
on (trg.c1_hk = src.c1_hk and src.load_end_dt = date'9999-12-31')
 when matched then
      update
         set trg.load_end_dt = trunc(sysdate)-1
       where trg.load_end_dt = date'9999-12-31'
         and trg.checksum   != src.checksum
 when not matched then
      insert(c1_hk, c2_v1, c3_v2, load_dt, load_end_dt, checksum)
        values(src.c1_hk, src.c2_v1, src.c3_v2, trunc(sysdate), date'9999-12-31', src.checksum)
          where src.load_end_dt = date'1111-11-11'
;

select * from test_trg order by c1_hk, load_dt;
