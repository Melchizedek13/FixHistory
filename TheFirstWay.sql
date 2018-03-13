
/*
  Надо не забывать, что функции GREATEST и LEAST в Postgres, в отличии от реализации в Oracle и DB2 LUW, игнорируют NULL.
  https://habrahabr.ru/post/340460/#comment_10488792
*/

with t1(id, sd, ed, x) as (
   select 1, to_timestamp('2018-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), to_timestamp('2018-01-10 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), 1 union all
   select 2, to_timestamp('2018-02-01 00:00:01', 'yyyy-mm-dd hh24:mi:ss'), to_timestamp('2018-03-01 16:13:13', 'yyyy-mm-dd hh24:mi:ss'), 3
), t2(id, sd, ed, y) as (
   select 1, to_timestamp('2018-01-05 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), to_timestamp('2018-01-15 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), 2 union all
   select 2, to_timestamp('2018-01-28 00:00:01', 'yyyy-mm-dd hh24:mi:ss'), to_timestamp('2018-02-25 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), 4
)
  select t1.id, 
         greatest(t1.sd, t2.sd) sd,
         least(t1.ed, t2.ed)    ed,
         t1.x,
         t2.y
    from t1, t2
   where t1.id = t2.id
     and greatest(t1.sd, t2.sd) < least(t1.ed, t2.ed)
;