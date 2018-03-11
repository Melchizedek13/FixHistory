

with t1(id, sd, ed, x) as (
   select 1, to_date('01.03.2018', 'dd.mm.yyyy'), to_date('10.03.2018', 'dd.mm.yyyy'), 1 union all
   select 1, to_date('11.03.2018', 'dd.mm.yyyy'), to_date('20.03.2018', 'dd.mm.yyyy'), 2
), t2(id, sd, ed, y) as (
   select 1, to_date('05.03.2018', 'dd.mm.yyyy'), to_date('15.03.2018', 'dd.mm.yyyy'), 3 union all
   select 1, to_date('15.03.2018', 'dd.mm.yyyy'), to_date('20.03.2018', 'dd.mm.yyyy'), 4
), subIntDiv as( 
   select *
     from
         ( 
           select id, point as sd, lead(point) over (partition by id order by point) as ed
             from
             ( select id, sd as point from t1
               union
               select id, ed as point from t1
               union
               select id, sd as point from t2
               union
               select id, ed as point from t2
             ) res1
         ) res2
     where ed is not null
)
select rs.id, rs.sd, rs.ed, t1.x, t2.y
  from subIntDiv rs
       left join t1 on rs.id = t1.id and t1.sd <= rs.sd and t1.ed >= rs.ed
       left join t2 on rs.id = t2.id and t2.sd <= rs.sd and t2.ed >= rs.ed
order by 1,2,3;