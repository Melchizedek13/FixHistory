

with t1(id, sd, ed, x) as (
   select 1, to_date('01.03.2018', 'dd.mm.yyyy'), to_date('10.03.2018', 'dd.mm.yyyy'), 1 union all
   -- select 1, to_date('01.03.2018', 'dd.mm.yyyy'), to_date('03.03.2018', 'dd.mm.yyyy'), -1 union all
   select 1, to_date('11.03.2018', 'dd.mm.yyyy'), to_date('20.03.2018', 'dd.mm.yyyy'), 2 union all
   select 3, to_date('05.03.2018', 'dd.mm.yyyy'), to_date('15.03.2018', 'dd.mm.yyyy'), 6
), t2(id, sd, ed, y) as (
   select 1, to_date('05.03.2018', 'dd.mm.yyyy'), to_date('15.03.2018', 'dd.mm.yyyy'), 3 union all
   select 1, to_date('15.03.2018', 'dd.mm.yyyy'), to_date('20.03.2018', 'dd.mm.yyyy'), 4 union all
   select 3, to_date('19.03.2018', 'dd.mm.yyyy'), to_date('25.03.2018', 'dd.mm.yyyy'), 5
), subIntDiv as(
   select *
     from
         (
           select distinct id, point as sd, lead(point) over (partition by id order by point) as ed
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
), TheSameDate as (
   select rs.id, rs.sd, rs.ed,
          -- min(t1.x) KEEP (DENSE_RANK FIRST ORDER BY t1.sd, t1.ed) over (partition by t1.id) x, -- t1.x x,
          -- min(t2.y) KEEP (DENSE_RANK FIRST ORDER BY t2.sd, t2.ed) over (partition by t2.id) y, -- t2.y y,
          first_value(t1.x) over (partition by rs.id, rs.sd, rs.ed order by t1.sd, t1.ed) x,
          first_value(t2.y) over (partition by rs.id, rs.sd, rs.ed order by t2.sd, t2.ed) y,
          row_number() over (partition by rs.id, rs.sd, rs.ed) rn
     from subIntDiv rs
          left join t1 on rs.id = t1.id and t1.sd <= rs.sd and t1.ed >= rs.ed
          left join t2 on rs.id = t2.id and t2.sd <= rs.sd and t2.ed >= rs.ed
  -- group by rs.id, rs.sd, rs.ed
), excludeRowsDurartionOfTheDay as (
   select id, sd, ed, x, y,
          lag(ed) over (partition by id order by sd) + 1 - ed as f
     from TheSameDate
    where rn = 1
      and (x is not null or y is not null)
), fixHoles as (
   select id, sd, ed, lag(ed) over (partition by id order by sd) ned, x, y
     from excludeRowsDurartionOfTheDay
    where coalesce(f, -1) != 0
)
   select id, case when ned is null then sd else ned + 1 end as sd, ed, x, y
     from fixHoles
    order by 1,2,3;
