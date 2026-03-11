/* Global Statement to call any macro from any folder and any nummber of folders can be accessed from the system  */
options sasautos=("/home/u64231588/Macros");

*Importing the File ;
%Import("/home/u64231588/Raw file/drug_sales_final_requested.csv",CSV,Sale_Data,Yes,Max);

*Summarisisng;
%contents(Sale_Data);

Proc Format;
	Picture Rupee low-high='00,00,00,00,009'(Prefix=' ₹ ');
run;



/* Data Cleaning part */
Data Sales_Base(drop=S_ID Region1 PCDT USD Sale_D Channel1 DCT);
	Length Sales_Rep $ 8;
	Set Sale_Data (Rename=(Sale_ID=S_ID Region=Region1 Product_Name=PCDT 
		Units_Sold=USD Sale_Date=Sale_D Channel=Channel1 Discount_Pct=DCT));
	Retain Sale_ID;

	If _N_=1 then
		Sale_ID=1001;
	else
		Sale_ID=Sale_ID + 1;
	Region=Propcase(Region1);
	Product_Name=Propcase(PCDT);

	If Sales_Rep=" " then
		Sales_Rep="Unknown";
	Format Sales_Rep $8.;
	Units_Sold=Input(Strip (USD), ?? 4.);
	Format Units_sold 20.;
	Sale_Date=Input(Strip(Sale_D), ?? ANYDTDTE12.);
	Format Sale_Date ddmmyy10.;
	Channel=Propcase(Channel1);
	Discount_Pct=Input(Strip(DCT), ?? 8.);
	Discount_Pct=Discount_Pct/100;

	If Discount_Pct=. then
		Discount_Pct=0.05;
	Format Discount_Pct percent8.2;
run;


/* Sorting the dataset by Product name */
 %let Varby = Product_Name;
%Sorting(Sales_Base,Product_Name);


/* Stdize procedure */

%let Sorting = Product_Name;
%let SortingBy = Units_Sold Unit_Price;
%Medreplace (Sales_Base,Sales_Median,Median,Product_Name,Units_Sold Unit_Price);


/* Finding the Derived Variables */

data Sales_Derivation;
	Set Sales_Median;
	*Here the we calculated the Derive Variables;
	length Revenue 8.;
	Revenue=Units_Sold * Unit_Price;

	Discount_Amt=Revenue * Discount_Pct;
	Net_Revenue=Revenue - Discount_Amt;

	If Product_Name="Vitaboost" then
		Cost_Per_unit=Unit_Price * 0.6;

	If Product_Name="Painrelief-X" then
		Cost_Per_unit=Unit_Price * 0.5;

	If Product_Name="Antibio-Plus" then
		Cost_Per_unit=Unit_Price * 0.55;

	If Product_Name="Coldcure" then
		Cost_Per_unit=Unit_Price * 0.45;
	Profit=Net_Revenue - (Cost_Per_unit * Units_Sold);

	if Revenue > 0 then
		Profit_Margin=(Profit/Revenue);
	else
		Profit_Margin=.;
	format Revenue Rupee.;
	format Discount_Amt Rupee.;
	format Net_Revenue Rupee.;
	format Cost_Per_unit Rupee.;
	format Profit Rupee.;
	Format Profit_Margin percent8.2;
	Format Unit_Price Rupee.;

/* Printing the Dataset	 */

%let options = Noobs width=Minimum;
%let Variables = Sale_ID Sales_Rep Sale_Date Region Channel Product_Name Cost_Per_Unit 
		Unit_Price Units_Sold Discount_Pct Revenue Discount_Amt Net_Revenue Profit 
		Profit_Margin ;
%LET labelopt= %Str (Sales_Rep = "Sales Represntative Id") ;
*Inside a macro call, = makes SAS think you are using keyword parameters, 
while the others are positional parameters.%str is used to protect that;
%Print(Sales_Derivation,&options,&Variables,&labelopt,"Cleaned dataset",&Sysdate &Systime);

Footnote;


/* Section 2  */
/* EDA(Explatory Data Analysis) */
*1.Analysis of  Mean Net_Revenue per Product , Number of Transaction Occured Per Product , total revenue generated Per Product;

%Title ("Product wise Average Sale,Total Sales Per Product & Net Revenue Analysis","This section analyses product wise average sale, total sales per product and net revenue analysis");
proc report data=Sales_Derivation;
	column Product_Name Net_Revenue=MeanRev Net_Revenue=SumRev;
	*Coloumn names works like select in proc sql means what to display in the output and here we use Net revenue= Aliases 
becuase we are going to perform diffrent analysis in the same varibale soo it may create an errror;
	define Product_Name / group 'Product Name';
	*here define indicated which variable we want to define and for what purpose ex : Grouping , Sum , etc;
	define MeanRev / analysis mean 'Mean Net Revenue' format=Rupee.;
	*we used analysis in order to explain Sas that treat the variables for Statistical ananlysis not simply display


				and for analysis we have to use aliases not the Net_revenue here;
	define SumRev / analysis sum 'Total Revenue per Product' format=Rupee.;
run;

*2.Frequency  Analysis;
*Analysis of Total number of Transaction Per Product & Total number of Transaction Per Region by single tabulation Method;
%Title("Total Number of Transaction analysis Per Product & Per Region",
"This section analyses Product wise total Number of Transaction Per Product And Total Number of Transaction in every region separately and the highest number of transaction occured for Antibio-Plus");
title4  h=10pt " ";
title5  j=Center h=8pt color=Blue Bold "Frequency= Total Number of Trasaction , Percent= The Percentage of transaction in Total Transaction";
run;
ods noproctitle;
proc freq data=Sales_Derivation ;
	tables Product_Name /nocum plots=freqplot(orient=Vertical) out=Sales_Freq;
	*nocum = No cumulative frequency or sum , Plots = Plot a Frequency Curve in the Vertical orientation;
run; 

title;

Title "Explanatory Table";
data Sales_transaction_Product;
	set Sales_Freq;
	label count="Total Number of Transactions" percent="Percentage Contribution";
run;

proc print data=Sales_Transaction_Product noobs label;
run;

*Analysis of Total number of Transaction Per Product in Each Region by Cross tabulation Method;
%Title("Total Number of Transaction analysis Per Product in each region","This section analyses Product wise total Number of Transaction Per Product in each region by Cross tabulation method and
the highest Transaction has Occured for Painrelief-X in East Region  ");
title4  h=10pt " ";
title5  j=Center h=8pt color=Blue Bold "Y-Left=Frequency of Transaction , Y-Right = Regions ,X=Product_Name";

proc freq data=Sales_Derivation;
	tables Region*Product_Name/ norow nocol nopercent 
		plots=freqplot (orient=Vertical);
run;


/* Business Based Analyis */
*3.Top Find the Top Performimg Product by Profit Gained By per Product;
%Title("Top Performing Product Analysis by Profit","This section Analyses and determines the Top Performing Product in
 Terms of Highest Profit Obtained ");
proc sql;
	Create table Performance_analysis as select Product_Name, sum(Profit) as 
		Total_Profit format=Rupee.
from Sales_Derivation group by Product_Name order by calculated Total_Profit 
		desc;
quit;

proc print data=Performance_analysis noobs label;
label Total_Profit = "Total Profit Generated"
Product_Name= "Product Name";
run;
 
/* Graph Plotting For Easier Understanding */
%let Type = %str(Hbar Product_Name/ Response=Total_profit group=Product_Name 
		baselineattrs=(color=Black));
%Plotting(Performance_analysis,&Type,"Profit Generated","Name of the products", "Top  Profit Generating Product");

*4.Total Net revenue per drug For Finding Top Performing Product;
%Title("Net Revenue Analysis Per Product","This section Analyses and determines the Top Performing Product in terms of 
Highest Net Revenue Generation");

proc sql;
	Create Table Revenue_analysis as select Product_Name, sum(Net_Revenue) as 
		Total_Net_Revenue format=Rupee.
from Sales_Derivation group by Product_Name;
quit;

proc print data=Revenue_analysis noobs lABEL;
Label Total_Net_Revenue = "Total Revenue Generated "
Product_Name= "Product Name";
run;

/* Graph Plotting For Easier Understanding */
%let Type = %str(Vbar Product_Name/ Response=Total_Net_Revenue group=Product_Name 
		baselineattrs=(color=Black));
%Plotting(Revenue_analysis,&Type,"Name of the products","Revenue Generated", "Highest Revenue Generating Product");


*5.Total Net revenue per month for non missing values for Finding the Top Performing Month ;
%Title("Month wise Net Revenue Analysis","This section Analyses the Total Net Revenue Obtained in each month to determine the Top performing Month");
data Sales_Derivation_month;
	Set Sales_Derivation;

	if not missing (Sale_Date) then
		Month=put(Sale_Date , monname10.);
	*Sale_Date is in Numeric Format and have missing value therefore for Selecting Non-missing values we used this Procedure;
	*,monnamew. is a method to extract the Month Name from a Numeric Sas date in Character Format;
run;

proc sql;
	create table Month_Revenue_analysis as select Month, sum(Net_Revenue) as 
		T_Net_Revenue format=Rupee.
from Sales_Derivation_month where Month ne " " group by Month order by 
		calculated T_Net_Revenue desc;
quit;

proc print data=Month_Revenue_analysis noobs Label;
Label  T_Net_Revenue = "Total Revenue Generated ";
run;


*Visualisation For the Monthly revenue analysis;
%let Type = %str(series X=Month Y=T_Net_Revenue / dataskin=matte);
%Plotting(Month_Revenue_analysis,&Type,"Month" ,"Total Net Revenue Generated","Monthy Revenue generated Analysis");


*6.Total Revenue Generated per Month per region;
%Title( "Net Revenue Month wise in Per region Analysis","This section Analyses the Total Net Revenue Obtained in each month in each region to determine the Top performing Region in each Month ");
proc sql;
	create table Month_Revenue_Region_analysis as select Month, Region, 
		sum(Net_Revenue) as Total_Net_Revenue format=Rupee.
from Sales_Derivation_month where Month ne " " group by Month , Region order by 
		Region, calculated Total_Net_Revenue desc;
quit;

*SAS groups rows that have the same Month and Region and then adds their Net_Revenue.;
*Order by Region, calculated Total_Net_Revenue desc This means:
1.First arrange Region alphabetically
2.Inside each Region, show highest revenue first;

proc print data=Month_Revenue_Region_analysis noobs label;
Label Total_Net_Revenue = "Total Revenue Generated By Each Product";
run;

/* Visualisation for the Same */
%let Type = %str(hbar Month / group=Region response=Total_Net_Revenue groupdisplay=Cluster);
%Plotting(Month_Revenue_Region_analysis,&Type,"Net Revenue Generated" ,"Month","Analsis of The Revenue Generated Monthwise in Each Region");


*7.Percent Contribution each region ;
%Title("Percentage Contribution of Net Revenue Per Region","This section Analyses the percentage Contribution of each Region By total Revenue 
Generated Product wise by Total Revenue Generated Including all the Region ");

proc sql;
	Create Table Region_Revenue_analysis as select Region, sum(Net_Revenue) as 
		Total_Revenue, calculated Total_Revenue / (select sum(Net_Revenue) from 
		Sales_Derivation)as Percentage_Contribution format=percent8.2 from 
		Sales_Derivation group by Region order by Calculated Percentage_Contribution 
		desc;
quit;

*Here we Used Inner subquery to get the Percentage Contribution of each Region by
(Net revenue Per Region / total revenue including all regions )*100 
proc print data= Region_Revenue_analysis noobs;

Proc Print Data=Region_Revenue_analysis noobs label;
Label Total_Revenue ="Total Revenue Generated By each Region"
Percentage_Contribution = "Percentage of Revenue Contribution";
run;

/* Pie Chart analysis of the Percentage contribution of revenue per region */
Proc sgpie Data=Region_Revenue_analysis;
	format Percentage_Contribution percent8.2;
	pie Region / dATASKIN=matte datalabelattrs=(size=13 color=black weight=Bold 
		style=Italic) response=Percentage_Contribution datalabelloc=callout 
		startangle=270 startpos=center;
	*dataskin = Colour Finishing of the circles datalabelattrs=How the displace of (size= color= weight= style=) should be and
 response=For which numeric varibale it should show the chart slices  and datalabelloc=position of the datalables;
	title "Percentage of Revenue Contribution by each Region";
run;

*8.Unit based Analysis;
%Title("Analysis of Units Sold Per Product","This Report summarises the number of Units Sold  for Per Product for determining the Total Units Sold Product wise ");
proc sql;
	Create Table Unit_Sold_analysis as select Product_Name , Sum(Units_Sold) as 
		Net_Units_Sold from Sales_Derivation group by Product_Name order by 
		Calculated Net_Units_Sold desc;
quit;

proc print data=Unit_Sold_analysis noobs label;
Label Product_Name = "Product Name"
Net_Units_Sold = "Net Units of Product Sold";
run;


/* Visualisation and customisation of Unit based analysis */
%let Type = %str(hbar Product_Name / Response=Net_Units_Sold 
		baselineattrs=(color=Black)group=Product_Name);
%Plotting(Unit_Sold_analysis,&Type,"Units of Product sold" ,"Name of the Products","Highest Units of Product sold");

*9.Profit analysis by Region wise;
%Title("Analysis of Net Profit Per Product in each region", "This section analyses and determines the total Profit obtained in each region and Top performing Product in each region in terms of Profit Generated");
proc sql;
	Create Table Profit_analysis_Region as select Region, Sum(Profit) as 
		Net_Profit format=Rupee. from Sales_Derivation group by Region order by 
		Calculated Net_Profit desc;
quit;

proc print data=Profit_analysis_Region noobs Label;
Label Net_Profit = "Total Profit generated region wise";
run;

/*  Visualisation of the Same */
%let Type = %str(vbar Region/ Response=Net_Profit group=Region baselineattrs=(color=Black));
%Plotting(Profit_analysis_Region,&Type,"Region" ,"Net Profit Generated","Top  Profit Generating Region");

*10 Profit analysis by Product wise in Each region ;
%Title ( "Analysis of Net Profit Per Product Per Region","This section analyses and determines the total Profit obtained by each Product in each region and 
the Most Profitable Product in each region");

proc sql;
	Create Table Profit_analysis_Reg_Pdt as select REgion , Product_Name, 
		Sum(Profit) as Net_Profit Format=Rupee. from Sales_Derivation group by Region, 
		Product_Name order by Region, Calculated Net_Profit desc;
quit;

*we Grouped Regions Separately , Products Separately And Then we sorted it by Region and Net_Profit;

proc print data=Profit_analysis_Reg_Pdt noobs Label;
Label Product_Name = "Product Name"
Net_Profit = "Total Profit by each product in each region wise";
run;

/* Visualisation of the same */
%let Type = %str(hbar Product_Name / group=Region response=Net_Profit groupdisplay=Cluster;);
%Plotting(Profit_analysis_Reg_Pdt,&Type,"Net Profit Generated" ,"Name of the Products" , "Analsis of The Profit Generated by Each product in Each Region");

*11 Finding Relation Between Unit_Sold and Profit and Net_Revenue;
*Corr Gives the Idea about How two variables are related  as if One Variable Increase what is the aafect on second Variable
+1------>	Perfect positive relationship
0---->	No relationship
-1----->	Perfect negative relationship;
%Title("Correlation Analysis Between Units Sold with Net revenue and Profit","This Report Summarises the Relationship between Units of Products Sold with Net Revenue and Units of 
Products Sold with Profit and gives us the idea about the strong Relationship Between Unit Sold & Net Revenue & Profit");

Proc corr data=Sales_Derivation nomiss nosimple noprob plots=scatter 
		plots=matrix;
	*NOMISS=Use only observations with no missing values for all variables,
NOSIMPLE=Removes simple descriptive statistics from the output,
NOPROB=Removes p-values from the output;
	var Units_Sold;
	with Net_Revenue Profit;
	footnote Bold color=Black h=8pt "N = Number of records were used in the calculation, Pearson Correlation Coefficients (r) = Values obtained from the analysis";
run;

footnote;

*Finding Relation Between Unit_Sold and Profit region wise;
*sorting of data by Region for Region analysis;
%Title("Correlation Analysis Between Units Sold with Net revenue and Profit Region wise ",
"This Report Summarises the Relationship between Units of Products Sold 
with Profit in each Region and gives us the idea about the strong Relationship Between Unit Sold  & Profit in each Region");
Proc sort Data=Sales_Derivation;
	By Region;
run;

proc corr data=Sales_Derivation nomiss nosimple noprob Plots=Scatter;
	by Region;
	var Units_Sold;
	with Profit;
	* Sorting of Data Region wise and finding the relation between Units Sold and Profit;
run;







