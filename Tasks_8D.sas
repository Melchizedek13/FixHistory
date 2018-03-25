data Fact2;
    attrib
        Id        length = 8.
        rest      length = 8.
        city_name length = $40
    ;
    infile datalines dlm='|' dsd;  
    input id rest city_name $;
 
datalines;
1|100|Москва
2|50|Липецк
3|30|Москва
4|200|Киев
5|210|Москва
6|10|Рязань
7|37|Иваново
8|400|Воронеж
9|120|Волгоград
10|110|Пенза
;
/*
	proc print data=Fact1 noobs;
*/
quit;

data DimCity2;
    attrib
        city_id   length = 8.
        city_name length = $40
    ;
    infile datalines dlm='|' dsd;  
    input city_id city_name $;
 
datalines;
1|Москва
2|Липецк
3|Пенза
;
quit;



%macro mExtractDimension(mvOutPutTable=, mvInputTable=, mvDimensionTable=, mvVar=, mvIDVar=);

	%let workLib = Work;
	%let libWithInputTabName = %sysfunc(catx(%str(.), &workLib, &mvInputTable));
	%let libWithDimTabName = %sysfunc(catx(%str(.), &workLib, &mvDimensionTable));
	%let libWithOutPutTabName = %sysfunc(catx(%str(.), &workLib, &mvOutPutTable));

	proc datasets library=&workLib;
	proc iml;
	   if exist("&mvoutputTable") then call delete("&workLib", "&mvoutputTable");
	quit;
	
	/* Does exist the input table?*/
	%let mvCheckInpTab = 0;
	proc sql noprint;
	    select 1 into :mvCheckInpTab
	      from DICTIONARY.TABLES
	     where libname="%upcase(&workLib)"
	       and memname ="%upcase(&mvInputTable)";
	quit;
	
	%if(&mvCheckInpTab = 0) %then 
	%do;	
		%put ERROR: The table "&mvInputTable" does not exist!!!;
		%ABORT;
	%end;
	
	/* Does exist the column of the input table?*/
	%let mvCheckVar = 0;
	proc sql noprint;
		select 1 into :mvCheckVar
		  from dictionary.columns
		 where memname = "%upcase(&mvInputTable)"
		   and libname = "%upcase(&workLib)"
		   and name = "&mvVar";
	quit;
	
	%if(&mvCheckVar = 0) %then 
	%do;	
		%put ERROR: The column "&mvVar" of the following table: "&mvInputTable", does not exist!!!;
		%ABORT;
	%end;
	
	/* Find max(id) in the Dim table */
	proc sql noprint;
	select max(&mvIDVar) into :mvMaxIDVar
	  from &libWithDimTabName;
	quit;
	
	/* Update the dimension. */
	proc sql undo_policy=none;
		insert into &libWithDimTabName(&mvVar, &mvIDVar)
		select &mvVar,
		       &mvMaxIDVar + monotonic()
		  from (
			select distinct f.&mvVar
			  from &libWithInputTabName f 
			       left join &libWithDimTabName d on f.&mvVar = d.&mvVar
			 where d.&mvIDVar is null
		);
	quit;
	
	/* get InputTable's headers without common &mvVar attribute */
	proc sql noprint;
		select 'src.' || name into :mvInpTabHeaders separated by ", "
		  from dictionary.columns
		 where memname = "%upcase(&mvInputTable)"
		   and libname = "%upcase(&workLib)"
		   and name <> "&mvVar";
	quit;
	
	proc sql; /* Create and fill the dimension. */
	  create table &libWithOutPutTabName
	  as
        select &mvInpTabHeaders, dim.&mvIDVar
          from &libWithInputTabName src,
               &libWithDimTabName   dim
         where src.&mvVar = dim.&mvVar
      ;
	quit;

%mend mExtractDimension;

%mExtractDimension(mvOutPutTable=Fact2Change,
					mvInputTable=Fact2,
					mvDimensionTable=DimCity2,
					mvVar=city_name,
					mvIDVar=city_id);


