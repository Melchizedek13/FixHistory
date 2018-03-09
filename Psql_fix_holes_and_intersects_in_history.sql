
/*
    excludeDuplicatesInA - В случае дублирования записей по всему атрибутному составу, одна запись остается. (id: 3)
                           Если записи одинаковые (id, sd, ed), а значения (val) разные, то такие записи
                                исключаются из общей выборки. (id: 4)
    sameDatesInA - 
    postSameDatesInA - 
    findHolesInA - 
    fixHolesInA - 
    fixIntInA - 
*/

with a(id, sd, ed, val) as (
    select 1, to_date('01.01.2018', 'dd.mm.yyyy'), to_date('10.01.2018', 'dd.mm.yyyy'), 11 union all
    select 1, to_date('01.01.2018', 'dd.mm.yyyy'), to_date('08.01.2018', 'dd.mm.yyyy'), 10 union all
    select 1, to_date('01.01.2018', 'dd.mm.yyyy'), to_date('05.01.2018', 'dd.mm.yyyy'), 9  union all
    select 1, to_date('13.01.2018', 'dd.mm.yyyy'), to_date('25.01.2018', 'dd.mm.yyyy'), 12 union all
    select 1, to_date('20.01.2018', 'dd.mm.yyyy'), to_date('25.01.2018', 'dd.mm.yyyy'), 14 union all
    select 1, to_date('15.01.2018', 'dd.mm.yyyy'), to_date('25.01.2018', 'dd.mm.yyyy'), 13 union all
    select 1, to_date('02.02.2018', 'dd.mm.yyyy'), to_date('13.02.2018', 'dd.mm.yyyy'), 15 union all
    select 1, to_date('08.02.2018', 'dd.mm.yyyy'), to_date('26.02.2018', 'dd.mm.yyyy'), 16 union all
    select 1, to_date('01.03.2018', 'dd.mm.yyyy'), to_date('31.12.9999', 'dd.mm.yyyy'), 17 union all
    select 2, to_date('01.01.2018', 'dd.mm.yyyy'), to_date('31.12.9999', 'dd.mm.yyyy'), 20 union all
    select 3, to_date('01.05.2018', 'dd.mm.yyyy'), to_date('10.05.2018', 'dd.mm.yyyy'), 30 union all
    select 3, to_date('01.05.2018', 'dd.mm.yyyy'), to_date('10.05.2018', 'dd.mm.yyyy'), 30 union all
    select 4, to_date('01.05.2018', 'dd.mm.yyyy'), to_date('10.05.2018', 'dd.mm.yyyy'), 40 union all
    select 4, to_date('01.05.2018', 'dd.mm.yyyy'), to_date('10.05.2018', 'dd.mm.yyyy'), 41 union all
    select 4, to_date('01.05.2018', 'dd.mm.yyyy'), to_date('10.05.2018', 'dd.mm.yyyy'), 40
), excludeDuplicatesInA as (
    select distinct *
      from a withoutDups
     where not exists (
        select 1
          from a withDups
         where withoutDups.id = withDups.id
           and withoutDups.sd = withDups.sd
           and withoutDups.ed = withDups.ed
         group by id, sd, ed
        having count(distinct val) > 1        
     )
), sameDatesInA as (
    select id, sd, ed, val,
           lead(sd) over (partition by id order by sd, ed desc) as nsd,
           lag(ed)  over (partition by id order by sd, ed asc)  as ped,
           lead(sd) over (partition by id order by sd, ed desc) - sd as same_sd,
           lead(ed) over (partition by id order by sd, ed asc)  - ed as same_ed
      from excludeDuplicatesInA
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