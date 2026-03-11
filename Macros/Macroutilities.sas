
/*Importing the Dataset*/
%macro Import(Dataset,filetype,Outname,Des,Des2);
Proc Import Datafile=&Dataset
DBMS=&filetype Out=&Outname replace;
Getnames=&Des;
Guessingrows=&Des2;
run;
%mend;

/* i want to Make a macro which can
 read any type of datatype anysheet of the exceldata and any range 
 of the excel data ith Getnames = No / Yes option */

/* Summarisisng Th data */
%macro contents(Dataset);
Proc contents Data=&Dataset;
run;
%Mend;



/*Printing the Dataset*/

%macro Print(Fset,options,Variables,labelopt,proctitle,Footnote);
proc Print data = &Fset &options;
var &Variables;
Label &labelopt;
title "&proctitle";
footnote "&Footnote";
run;
%mend;

/*Sorting the Dataset with One Variable */

%Macro Sorting (DataSort,Varby);
Proc sort data = &DataSort;
by &Varby;
run;
%mend;


/*Applying ruppee format to the Dataset*/

%Macro Rupee;
Proc Format;
Picture Rupee
low-high = '00,00,00,00,009'(Prefix=' ₹ '));
 run;
%mend;



/*Using Proc Stdize for  Dataset */

%MACRO Medreplace (InData,OutData,Methd,Sorting,SortingBy);
Proc stdize data=&InData
     out=&OutData
            method=&Methd
             	reponly;
		by &Sorting;
	var &SortingBy ;
run;
%mend;




