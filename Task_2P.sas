
data A;
    attrib abon_id     length=8.
           tariff_plan length=8. 
           type        length=8. 
           fd informat=ddmmyy10. FORMAT=DDMMYYP10.
           td informat=ddmmyy10. FORMAT=DDMMYYP10.
    ;
    infile datalines dlm='|' dsd;
    input abon_id tariff_plan type fd td;
    datalines;
1|1|1|01.10.2005|01.01.2040
2|1|2|05.11.2005|01.12.2006
2|2|2|02.12.2006|01.12.2007
2|2|1|02.12.2007|01.01.2040
3|0|0|07.11.1917|11.06.1991
3|1|1|12.06.1991|01.01.2040
4|1|1|12.06.1991|01.01.2040
;
quit;

data B;
    attrib abon_id     length=8.
           name        length=$30.
           sex         length=$30.
           fd informat=ddmmyy10. FORMAT=DDMMYYP10.
           td informat=ddmmyy10. FORMAT=DDMMYYP10.
    ;
    infile datalines dlm='|' dsd;
    input abon_id name sex fd td;
    datalines;
1|Игорь|М|01.10.2005|01.01.2040
2|Вася|М|05.11.2005|01.08.2006
2|Лена|Ж|02.08.2006|02.09.2007
2|Юля|Ж|03.09.2007|01.01.2040
3|СССР|Страна|07.11.1917|11.06.1991
3|Россия|Страна|12.06.1991|01.01.2040
4|Петя|М|12.08.1991|01.01.2040
;
quit;

%let c_plusInfinity='01Jan2040'd;

data    C(keep = abon_id tariff_plan type fd td name sex);
    set A(in=ain rename=(fd=sfd td=std tariff_plan=stariff_plan type=stype))
        B(in=bin rename=(fd=sfd td=std name=sname sex=ssex));
     by abon_id sfd;

    retain tariff_plan type name sex p_fd;
    Format fd   DDMMYYP10.;
    Format p_fd DDMMYYP10.;
    Format td   DDMMYYP10.;

    if first.abon_id then do;
        p_fd        = .;
        name        = coalescec(sname, '.');
        sex         = coalescec(ssex, '.');
        tariff_plan = coalesce(stariff_plan, .);
        type        = coalesce(stype, .);
    end;
    else do;
        fd = p_fd;
        td = sfd - 1;

        if not (p_fd = sfd) then
            output;
    end;

    if last.abon_id then do;
        fd          = sfd;
        td          = &c_plusInfinity;
        name        = coalescec(sname, name);
        sex         = coalescec(ssex, sex);
        tariff_plan = coalesce(stariff_plan, tariff_plan);
        type        = coalesce(stype, type);
        output;
    end;

    if ain then do;
        tariff_plan = stariff_plan;
        type = stype;
    end;

    if bin then do;
        name = sname;
        sex = ssex;
    end;

    p_fd = sfd;
run;

data C;
    retain abon_id tariff_plan type name sex fd td;
    set C;
run;

proc print data=C noobs;
run;    

