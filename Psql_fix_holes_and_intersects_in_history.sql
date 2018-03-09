
/*
    Как быть с засписями, у которых история одинакова, но значения разные?
*/

with a as (
    select 1 as id, to_date('01.01.2018', 'dd.mm.yyyy') as sd, to_date('10.01.2018', 'dd.mm.yyyy') as ed, 11 as val union all
    select 1, to_date('01.01.2018', 'dd.mm.yyyy'), to_date('08.01.2018', 'dd.mm.yyyy'), 10 union all
    select 1, to_date('01.01.2018', 'dd.mm.yyyy'), to_date('05.01.2018', 'dd.mm.yyyy'), 9 union all
    select 1, to_date('13.01.2018', 'dd.mm.yyyy'), to_date('25.01.2018', 'dd.mm.yyyy'), 12 union all
    select 1, to_date('20.01.2018', 'dd.mm.yyyy'), to_date('25.01.2018', 'dd.mm.yyyy'), 14 union all
    select 1, to_date('15.01.2018', 'dd.mm.yyyy'), to_date('25.01.2018', 'dd.mm.yyyy'), 13 union all
    select 1, to_date('02.02.2018', 'dd.mm.yyyy'), to_date('13.02.2018', 'dd.mm.yyyy'), 15 union all
    select 1, to_date('08.02.2018', 'dd.mm.yyyy'), to_date('26.02.2018', 'dd.mm.yyyy'), 16 union all
    select 1, to_date('01.03.2018', 'dd.mm.yyyy'), to_date('31.12.9999', 'dd.mm.yyyy'), 17 union all
    select 2, to_date('01.01.2018', 'dd.mm.yyyy'), to_date('31.12.9999', 'dd.mm.yyyy'), 20
), sameDatesInA as (
    select id, sd, ed, val,
           lead(sd) over (partition by id order by sd, ed desc) as nsd,
           lag(ed)  over (partition by id order by sd, ed asc)  as ped,
           lead(sd) over (partition by id order by sd, ed desc) - sd as same_sd,
           lead(ed) over (partition by id order by sd, ed asc)  - ed as same_ed
      from a
), postSameDatesInA as (
    select id, nsd, val,
           case when same_sd = 0 then ped + 1 else sd end as sd, 
           case when same_ed = 0 then nsd - 1 else ed end as ed
      from sameDatesInA
), findHolesInA as (
    select id, sd, ed, val,
           lead(sd) over (partition by id order by sd) as nsd,
           lead(sd) over (partition by id order by sd) - ed - 1 as diff 
      from postSameDatesInA
), fixHolesInA as (
    select id, sd, val, nsd,
           case when diff > 0 then ed + diff else ed end as ed,
           case when nsd  <= case when diff > 0 then ed + diff else ed end then 1 else 0 end fi
      from findHolesInA
), fixIntInA as (
    select id, sd, val, 
           case when fi = 1 then nsd - 1 else ed end as ed
      from fixHolesInA
)
  select id, 
         to_char(sd, 'dd.mm.yyyy') as sd,
         to_char(ed, 'dd.mm.yyyy') as ed,
         val
    from fixIntInA;