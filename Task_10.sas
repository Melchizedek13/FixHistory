data confTabsForView;
	attrib
		library length = $30
		table length = $60
	;
	infile datalines dlm='|' dsd;
	input library $ table $;
datalines;
tduser|t10_1
tduser|t10_2
tduser|t10_3
;

options macrogen symbolgen mlogic mprint sastrace=',,,d' sastraceloc=saslog nostsuffix;

%macro mDDLViewOnTeradata(mvConfDS=, mvViewName=, mvAttrForSorting=);
	%let workLib = Work;
	%let libWithConfDS = %sysfunc(catx(%str(.), &workLib, &mvConfDS));
	%let genSqlStmt = '';

	proc sql noprint;
		select 'select * from '||trim(library)||'.'||trim(table)
		  into :genSqlStmt separated by " union all "
		  from &libWithConfDS;
	quit;

	%put &genSqlStmt;

	proc sql;
		connect to teradata (user=tduser pw=tduser server=localtd);
		execute (drop view &mvViewName) by teradata;
		execute (commit) by teradata;
		execute (create view &mvViewName
				     as &genSqlStmt) by teradata;
		execute (commit) by teradata;
	quit;

%mend mDDLViewOnTeradata;

%mDDLViewOnTeradata(mvConfDs=confTabsForView, mvViewName=v20);


libname tdata teradata user="tduser" password="tduser" tdpid="localtd";

proc sql;
	select * from tdata.v20;
quit;
