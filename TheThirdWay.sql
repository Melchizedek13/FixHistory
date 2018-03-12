
/*
    Могут быть дыры, интервалы не могут пересекаться в данных одной таблицы. 
    Пересечения интервалов допустимы только между таблицами.
*/

with t1(id, sd, ed, x) as (
   select 1, to_timestamp('2018-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), to_timestamp('2018-01-03 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), 1 union all
   select 1, to_timestamp('2018-01-03 00:00:01', 'yyyy-mm-dd hh24:mi:ss'), to_timestamp('2018-01-05 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), 2 union all
   select 1, to_timestamp('2018-01-05 00:00:01', 'yyyy-mm-dd hh24:mi:ss'), to_timestamp('5999-12-31 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), 3
), t2(id, sd, ed, y) as (
   select 1, to_timestamp('2018-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), to_timestamp('2018-01-03 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), 4 union all
   select 1, to_timestamp('2018-01-05 00:00:01', 'yyyy-mm-dd hh24:mi:ss'), to_timestamp('5999-12-31 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), 5
), allPoints as (
   select *
     from
         (
           select distinct id, point as p, -- sd,
           lead(point - interval '1 second') over (partition by id order by point) as ed
             from
             ( select id, sd as point from t1
               union
               select id, ed + interval '1 second' as point from t1 where ed != to_timestamp('5999-12-31 00:00:00', 'yyyy-mm-dd hh24:mi:ss')
               union
               select id, sd as point from t2
               union
               select id, ed + interval '1 second' as point from t2 where ed != to_timestamp('5999-12-31 00:00:00', 'yyyy-mm-dd hh24:mi:ss')
             ) res1
         ) res2
)
   select rs.id,
          rs.p as sd,
          coalesce(rs.ed, to_timestamp('5999-12-31 00:00:00', 'yyyy-mm-dd hh24:mi:ss')) as ed,
          t1.x, t2.y
     from allPoints rs
          left join t1 on rs.id = t1.id and rs.p between t1.sd and t1.ed
          left join t2 on rs.id = t2.id and rs.p between t2.sd and t2.ed
    order by 1,2,3
;