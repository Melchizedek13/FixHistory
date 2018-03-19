data FactP;
	attrib Id length=8. rest length=8. city_name length=$40;
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
10|110|Киев
;
quit;


data DimCityP;
	attrib city_id length=8. city_name length=$40;
	infile datalines dlm='|' dsd;
	input city_id city_name $;
	datalines;
1|Москва
2|Липецк
3|Пенза
;
quit;

	%macro mExtractPDimension(mvOutPutTable=, mvInputTable=, mvDimensionTable=, 
							  mvVar=, mvIDVar=);
		%let workLib = Work;
		%let libWithInputTabName = %sysfunc(catx(%str(.), &workLib, &mvInputTable));
		%let libWithDimTabName = %sysfunc(catx(%str(.), &workLib, &mvDimensionTable));
		%let libWithOutPutTabName = %sysfunc(catx(%str(.), &workLib, &mvOutPutTable));

		proc datasets library=&workLib;
		proc iml;
			if exist("&mvoutputTable") then
				call delete("&workLib", "&mvoutputTable");
		quit;
		%mCheckTableAndColumns(mvLibname=&workLib, mvTableName=&mvInputTable, 
			mvAttrName=&mvVar);

		proc sort data=&libWithInputTabName;
			by &mvVar;
		quit;
		
		%if %sysfunc(exist(&libWithDimTabName)) %then %do;
		    proc sql noprint;
				select max(&mvIDVar) into :max
				  from &libWithDimTabName;
			quit;
			proc sort data=&libWithDimTabName;
				by &mvVar;
			quit;
	    %end;
		%else %do;
			%let max = 0;
			data &libWithDimTabName;
				set &libWithInputTabName(rename=(id=&mvIDVar) keep=id &mvVar obs=0);
			run;
			/*
			data &libWithDimTabName;
				format &mvIDVar 8. &mvVar $40.;
				stop;
			run;
			*/
		%end;

		data 
			&libWithDimTabName (keep=&mvVar &mvIDVar)
			&mvOutPutTable (drop=&mvVar signal)
		;
			merge &libWithDimTabName(in=d) &libWithInputTabName(in=f);
			by &mvVar;
			retain signal &max;
			
			if missing(&mvIDVar) then do;
				signal + 1;
				&mvIDVar = signal;
			end;
			
			if first.&mvVar then
				output &libWithDimTabName;
			
			if f then
				output &mvOutPutTable;

		run;

	
/* KISS 
	data &libWithDimTabName;
		set &libWithDimTabName missingLinesInDim;
*/
/*
	if d and first.&mvVar then do;
		sig2=&mvIDVar;
		output &libWithDimTabName;
	end;

	if f and d then do;
		sig2=&mvIDVar;
		output &mvOutPutTable;
	end;

	if not d and first.&mvVar then do;
		signal + 1;
		sig2 = signal;
		output &libWithDimTabName &mvOutPutTable;
	end;
*/

/*
		data _null_;
			set &libWithDimTabName end=last;
			retain max;
			max=max(max, city_id);
	
			if last then
				call symput('max', max);
		run;
*/

/*
	data &libWithDimTabName;
		modify &libWithDimTabName missingLinesInDim;
		by &mvVar;

		if _iorc_=%sysrc(_dsenmr) then
			do;
				output;
				_error_=0;
			end;
	run;
*/
/*
	proc datasets library=&workLib;
		delete missingLinesInDim;
		run;
*/		
	%mend mExtractPDimension;

	%mExtractPDimension(mvOutPutTable=FactPChange, mvInputTable=FactP, 
		mvDimensionTable=DimCityP, mvVar=city_name, mvIDVar=city_id);