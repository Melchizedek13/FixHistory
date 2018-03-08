
/*
    1. Как исправлять историю записей, которые открыты в один день?
    2. Как быть с засписями, у которых история одинакова, но значения разные?
*/

with a as (
    select 1 as id, to_date('01.01.2018', 'dd.mm.yyyy') as sd, to_date('03.01.2018', 'dd.mm.yyyy') as ed, 10 as val union all
    select 1, to_date('04.01.2018', 'dd.mm.yyyy'), to_date('07.01.2018', 'dd.mm.yyyy'), 11 union all
    select 1, to_date('11.01.2018', 'dd.mm.yyyy'), to_date('17.01.2018', 'dd.mm.yyyy'), 12 union all
    select 1, to_date('22.01.2018', 'dd.mm.yyyy'), to_date('01.02.2018', 'dd.mm.yyyy'), 13 union all
    select 1, to_date('02.02.2018', 'dd.mm.yyyy'), to_date('13.02.2018', 'dd.mm.yyyy'), 14 union all
    select 1, to_date('08.02.2018', 'dd.mm.yyyy'), to_date('26.02.2018', 'dd.mm.yyyy'), 15 union all
    select 1, to_date('01.03.2018', 'dd.mm.yyyy'), to_date('31.12.9999', 'dd.mm.yyyy'), 16 union all
    select 2, to_date('01.01.2018', 'dd.mm.yyyy'), to_date('31.12.9999', 'dd.mm.yyyy'), 20
), preHandleA as (
    select id, sd, ed, val,
           lead(sd) over (partition by id order by sd) as nsd,
           lead(sd) over (partition by id order by sd) - ed - 1 as diff
      from a
), fixHolesInA as (
    select id,
           sd,
           case when diff > 0 then ed + diff else ed end as ed,
           case when nsd  <= case when diff > 0 then ed + diff else ed end then 1 else 0 end fi,
           val,
           nsd
      from preHandleA
), fixIntInA as (
    select id, sd, case when fi = 1 then nsd - 1 else ed end as ed, val
      from fixHolesInA
)
  select id, 
         to_char(sd, 'dd.mm.yyyy') as sd,
         to_char(ed, 'dd.mm.yyyy') as ed,
         val
    from fixIntInA;