%macro mCheckTableAndColumns(mvLibname=, mvTableName=, mvAttrName=);

	/* Does exist the input table?*/
	%let mvCheckInpTab = 0;
	proc sql noprint;
	    select 1 into :mvCheckInpTab
	      from DICTIONARY.TABLES
	     where libname="%upcase(&mvLibname)"
	       and memname ="%upcase(&mvTableName)";
	quit;
	
	%if(&mvCheckInpTab = 0) %then 
	%do;	
		%put ERROR: The table "&mvTableName" does not exist!!!;
		%ABORT;
	%end;
	
	/* Does exist the column of the input table?*/
	%let mvCheckVar = 0;
	proc sql noprint;
		select 1 into :mvCheckVar
		  from dictionary.columns
		 where memname = "%upcase(&mvTableName)"
		   and libname = "%upcase(&mvLibname)"
		   and name = "&mvAttrName";
	quit;
	
	%if(&mvCheckVar = 0) %then 
	%do;	
		%put ERROR: The column "&mvAttrName" of the following table: "&mvTableName", does not exist!!!;
		%ABORT;
	%end;
%mend mCheckTableAndColumns;