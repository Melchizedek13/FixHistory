
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
           and name not in ("&mvKeyVars", "&mvFdVar", "&mvTdVar")
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
           and name not in ("&mvKeyVars", "&mvFdVar", "&mvTdVar")
        ;
    quit;

    proc sql noprint;
        select trim(name)||'=c'||trim(name),
               trim(name)||'=c'||trim(name)
          into :mvTabAHeader       separated by '; ',
               :mvTabARenameHeader separated by ' '
          from dictionary.columns
         where memname = "%upcase(&mvTableA)"
           and libname = "%upcase(&workLib)"
           and name not in ("&mvKeyVars", "&mvFdVar", "&mvTdVar");
        ;
    quit;

    proc sql noprint;
        select trim(name)||'=c'||trim(name),
               trim(name)||'=c'||trim(name)
          into :mvTabBHeader       separated by '; ',
               :mvTabBRenameHeader separated by ' '
          from dictionary.columns
         where memname = "%upcase(&mvTableB)"
           and libname = "%upcase(&workLib)"
           and name not in ("&mvKeyVars", "&mvFdVar", "&mvTdVar");
        ;
    quit;

    %let c_plusInfinity='01Jan2040'd;

    Data &mvOutTable(keep=&mvTabCHeader &mvKeyVars &mvFdVar &mvTdVar);
        set &mvTableA(in=ain rename=(&mvTabARenameHeader &mvFdVar=c&mvFdVar &mvTdVar=c&mvTdVar))
            &mvTableB(in=bin rename=(&mvTabBRenameHeader &mvFdVar=c&mvFdVar &mvTdVar=c&mvTdVar));
         by &mvKeyVars c&mvFdVar;

        retain p_fd &mvTabCHeader;

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
            &mvLastBlock;
            output;
        end;

        if ain then do;
            &mvTabAHeader;
        end;

        if bin then do;
            &mvTabBHeader;
        end;

        p_fd = c&mvFdVar;
        
    run;

%mend mFdTdJoin;


%mFdTdJoin(mvOutTable=C, mvTableA=A, mvTableB=B, mvKeyVars=abon_id, mvFdVar=fd, mvTdVar=td);

proc print data=C;
run;
