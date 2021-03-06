
with t1(id, sd, ed, x) as (
   select 1, to_timestamp('2018-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), to_timestamp('2018-01-05 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), 1 union all
   select 1, to_timestamp('2018-01-05 00:00:01', 'yyyy-mm-dd hh24:mi:ss'), to_timestamp('5999-12-31 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), 2
), t2(id, sd, ed, y) as (
   select 1, to_timestamp('2018-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), to_timestamp('2018-01-07 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), 1 union all
   select 1, to_timestamp('2018-01-07 00:00:01', 'yyyy-mm-dd hh24:mi:ss'), to_timestamp('5999-12-31 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), 2
), cuttPeriods as (
   select t1.id, t1.sd as p, t1.x as x, t2.y as y
     from t1 left join t2 on t1.id = t2.id and t1.sd between t2.sd and t2.ed
   union
   select t2.id, t2.sd as p, t1.x as x, t2.y as y
     from t2 left join t1 on t2.id = t1.id and t2.sd between t1.sd and t1.ed
)
select id,
       p as sd,
       lead(p, 1, to_timestamp('5999-12-31 00:00:00', 'yyyy-mm-dd hh24:mi:ss')) over (partition by id order by p) - interval '1 second' as ed,
       x, y
  from cuttPeriods
 order by id, p;
;