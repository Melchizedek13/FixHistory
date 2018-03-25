
/*
    Options macrogen symbolgen mlogic mprint mfile;
    filename mprint '/folders/myfolders/for_debug/1.txt';
*/

%macro mFdTdJoin(mvOutTable=, mvTableA=, mvTableB=, mvKeyVars=, mvFdVar=, mvTdVar=);
    %let workLib = Work;

    proc datasets library=&workLib;

    proc sort data=&mvTableA;
        by &mvKeyVars &mvFdVar;
    quit;

    proc sort data=&mvTableB;
        by &mvKeyVars &mvFdVar;
    quit;

    proc sql noprint;   
        select distinct name
          into :mvTabCHeader separated by " "
          from dictionary.columns
         where memname in ("%upcase(&mvTableA)", "%upcase(&mvTableB)")
        ;
    quit;
    
    proc sql noprint;
        select 
          case when type='char' then trim(name)||'=coalescec(c'||trim(name)||", '.'"||')' 
               else trim(name)||'=coalesce(c'||trim(name)||', .)'
           end,
          case when type='char' then trim(name)||'=coalescec(c'||trim(name)||', '||trim(name)||')'
               else trim(name)||'=coalesce(c'||trim(name)||', '||trim(name)||')'
           end
          into :mvFirstBlock separated by '; ',
               :mvLastBlock separated by '; '
          from dictionary.columns
         where memname in ("%upcase(&mvTableA)", "%upcase(&mvTableB)")
           and libname = "%upcase(&workLib)"
           and name not in ("&mvKeyVars", '&mvFdVar', '&mvTdVar');
    quit;

    proc sql noprint;
        select name,
               trim(name)||'=c'||name
          into :mvTabAHeader       separated by " ",
               :mvTabARenameHeader separated by " "
          from dictionary.columns
         where memname = "%upcase(&mvTableA)"
           and libname = "%upcase(&workLib)"
           and name <> "&mvKeyVars"
        ;
    quit;

    proc sql noprint;
        select name,
               trim(name)||'=c'||name
          into :mvTabBHeader       separated by " ",
               :mvTabBRenameHeader separated by " "
          from dictionary.columns
         where memname = "%upcase(&mvTableB)"
           and libname = "%upcase(&workLib)"
           and name <> "&mvKeyVars"
        ;
    quit;

    %let retain_header=;
    %let initListFromTabA=;
    %let initListFromTabB=;
    %let c_plusInfinity='01Jan2040'd;

    %do i=1 %to %sysfunc(countw(&mvTabCHeader));
        %let cn=%scan(&mvTabCHeader,&i);
        %if not (&cn = &mvKeyVars or &cn = &mvFdVar or &cn = &mvTdVar) %then
            %let retain_header = &retain_header &cn;
    %end;

    %do i=1 %to %sysfunc(countw(&mvTabAHeader));
        %let cn=%scan(&mvTabAHeader,&i);
        %if not (&cn = &mvFdVar or &cn = &mvTdVar) %then
            %let initListFromTabA = &initListFromTabA &cn;
    %end;

    %do i=1 %to %sysfunc(countw(&mvTabBHeader));
        %let cn=%scan(&mvTabBHeader,&i);
        %if not (&cn = &mvFdVar or &cn = &mvTdVar) %then
            %let initListFromTabB = &initListFromTabB &cn;
    %end;

    Data &mvOutTable(keep=&mvTabCHeader);
        set &mvTableA(in=ain rename=(&mvTabARenameHeader))
            &mvTableB(in=bin rename=(&mvTabBRenameHeader));
         by &mvKeyVars c&mvFdVar;

        retain p_fd &retain_header;

        Format &mvFdVar  DDMMYYP10.;
        Format p_fd      DDMMYYP10.;
        Format &mvTdVar  DDMMYYP10.;

        if first.&mvKeyVars then do;
            p_fd = .;
            &mvFirstBlock;
        end;
        else do;
            &mvFdVar = p_fd;
            &mvTdVar = c&mvFdVar - 1;

            if not (p_fd = c&mvFdVar) then
                output;
        end;

        if last.&mvKeyVars then do;
            &mvFdVar    = c&mvFdVar;
            &mvTdVar    = &c_plusInfinity;
            &mvFirstBlock;
            output;
        end;

        if ain then do;
            %do i=1 %to %sysfunc(countw(&initListFromTabA));
                %let cn=%scan(&initListFromTabA,&i);
                    &cn = c&cn;
            %end;
        end;

        if bin then do;
            %do i=1 %to %sysfunc(countw(&initListFromTabB));
                %let cn=%scan(&initListFromTabB,&i);
                    &cn = c&cn;
            %end;
        end;

        p_fd = c&mvFdVar;
        
    run;

%mend mFdTdJoin;


%mFdTdJoin(mvOutTable=C, mvTableA=A, mvTableB=B, mvKeyVars=abon_id, mvFdVar=fd, mvTdVar=td);

proc print data=C;
run;
