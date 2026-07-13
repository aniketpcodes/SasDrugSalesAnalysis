/* Macro Utility Library exercised end-to-end.
   Source: Macros/MacroUtlity.sas (definitions verbatim). The caller
   below builds the sample inline, then invokes %Rupee, %contents,
   %Sorting, %Medreplace, %Title and %Print from the library. */

/* ---- Macro Utility Library (verbatim from Macros/MacroUtlity.sas) ---- */

/*Importing the Dataset*/
%macro Import(Dataset,filetype,Outname,Des,Des2);
Proc Import Datafile=&Dataset
DBMS=&filetype Out=&Outname replace;
Getnames=&Des;
Guessingrows=&Des2;
run;
%mend;


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
title &proctitle;
footnote &Footnote;
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
low-high = '00,00,00,00,009'(Prefix=' ₹ ');
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


/* Macro for Title statemnet for Business analysis */

%macro Title (Tit,Description);
title j=Center &Tit;
title2 h=10pt " ";
title3 j=Center h=8pt color=Black Bold &Description;
%mend;

/* macro for Sgplot Graph */

%Macro Plotting (data,Topic,Xlabel,Ylabel,title);
proc sgplot data=&data;
&Topic;
	xaxis label= &Xlabel valueattrs=(size=10 weight=bold) labelattrs=(Color=Black weight=Bold size=11 style=Italic);
	yaxis label= &Ylabel labelattrs=(Color=Black weight=Bold 
		size=11 style=Italic);
title &title;
run;
%mend;




/* ---- Caller: build the sample inline, then exercise the utility macros ---- */

/* Bundled sample of the repo's drug_sales_raw.csv (30 rows), read inline
   via INFILE DSD so PROC IMPORT is unnecessary — the runner uploads only
   the script, and this keeps the bundle fully self-contained. Column
   types match what PROC IMPORT infers from the CSV: Sale_ID, Units_Sold
   and Unit_Price numeric; Region, Product_Name, Sales_Rep, Sale_Date,
   Channel and Discount_Pct character. */
data Sales_Data;
	length Region $5 Product_Name $12 Sales_Rep $4 Sale_Date $10 Channel $8 Discount_Pct $2;
	infile datalines dsd truncover;
	input Sale_ID Region $ Product_Name $ Sales_Rep $ Units_Sold Unit_Price Sale_Date $ Channel $ Discount_Pct $;
datalines;
,East,VitaBoost,,730663.0,4937.93,,Online,5
1002.0,East,AntiBio-Plus,R103,483775.0,3914.96,03-20-2024,Hospital,
1003.0,South,VitaBoost,R102,484994.0,1148.34,2024-01-15,hospital ,5
1004.0,SOUTH,PainRelief-X ,R104,243550.0,3432.64,03-20-2024,Online,5
1005.0,West,VitaBoost,R103,345634.0,4835.9,2024-01-15,Online,
1006.0,East,PainRelief-X ,R101,358476.0,1328.92,2024-01-15,hospital ,5
1007.0,South,PainRelief-X,R102,841425.0,4466.54,2024/04/10,hospital ,5%
1008.0,East,VitaBoost,,425958.0,4937.93,2024/04/10,Hospital,5%
1009.0,South,coldcure,R102,791032.0,3324.55,15/02/2024,Hospital,5%
1010.0,South,ColdCure,R104,443317.0,4578.99,2024-01-15,Hospital,
1011.0,north ,ColdCure,,421763.0,4589.62,2024/04/10,hospital ,5%
1012.0,north ,PainRelief-X,,513413.0,4073.85,2024-01-15,Online,0
1013.0,North,VitaBoost,R103,395964.0,4972.54,03-20-2024,Online,0
1014.0,East,PainRelief-X ,R102,453752.0,1328.92,2024/04/10,Online,0
1015.0,West,ColdCure,R101,192340.0,1538.02,03-20-2024,hospital ,10
,East,PainRelief-X,R103,164092.0,1891.31,2024-01-15,Retail,5
1017.0,East,coldcure,R103,254363.0,2164.0,15/02/2024,hospital ,
1018.0,East,PainRelief-X,R104,106374.0,1891.31,,Online,
1019.0,East,AntiBio-Plus,,358373.0,3914.96,03-20-2024,Online,5%
1020.0,South,ColdCure,,448657.0,4578.99,,Hospital,5%
1021.0,West,VitaBoost,R104,711502.0,4835.9,15/02/2024,Online,5%
1022.0,North,coldcure,R101,219315.0,1258.39,03-20-2024,Hospital,0
1023.0,West,PainRelief-X ,R101,897772.0,2570.64,2024-01-15,Hospital,
1024.0,North,AntiBio-Plus,R102,220293.0,4059.53,2024-01-15,hospital ,0
1025.0,SOUTH,PainRelief-X,R102,734010.0,2722.98,15/02/2024,Online,0
1026.0,north ,PainRelief-X,R101,354691.0,4073.85,15/02/2024,Hospital,5%
1027.0,SOUTH,PainRelief-X ,R101,735362.0,3432.64,15/02/2024,Retail,5%
1028.0,South,coldcure,R104,234607.0,3324.55,2024-01-15,Online,
1029.0,West,ColdCure,R103,280702.0,1538.02,2024/04/10,Online,
1030.0,East,VitaBoost,R104,274169.0,4937.93,03-20-2024,Hospital,10
;
run;

/* %contents macro: inspect the imported dataset */
%contents(Sales_Data);

/* Minimal cleaning so numeric vars carry through the STDIZE macro */
data Sales_Base;
	set Sales_Data;
	Product_Name=Propcase(Product_Name);
run;

/* %Rupee macro: define the currency picture format */
%Rupee;

/* %Sorting macro: sort by product before median replacement */
%Sorting(Sales_Base,Product_Name);

/* %Medreplace macro: PROC STDIZE median replacement of missing values */
%Medreplace(Sales_Base,Sales_Median,Median,Product_Name,Units_Sold Unit_Price);

/* %Title macro: standardized business-report title */
%Title("Median-replaced sample","Units and price with missing values replaced by product-wise median");

/* %Print macro: display selected variables */
%Print(Sales_Median,noobs,Product_Name Region Units_Sold Unit_Price,,,);
