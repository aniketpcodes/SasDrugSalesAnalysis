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
Proc Format;
	Picture Rupee low-high='00,00,00,00,009'(Prefix=' Rs ');
run;

Data Sales_Base(drop=S_ID Region1 PCDT USD Sale_D Channel1 DCT);
	Length Sales_Rep $ 8;
	Set Sales_Data (Rename=(Sale_ID=S_ID Region=Region1 Product_Name=PCDT
		Units_Sold=USD Sale_Date=Sale_D Channel=Channel1 Discount_Pct=DCT));
	Retain Sale_ID;
	If _N_=1 then Sale_ID=1001;
	else Sale_ID=Sale_ID + 1;
	Region=Propcase(Region1);
	Product_Name=Propcase(PCDT);
	If Sales_Rep=" " then Sales_Rep="Unknown";
	Format Sales_Rep $8.;
	Units_Sold=Input(Strip (USD), ?? 4.);
	Format Units_sold 20.;
	Sale_Date=Input(Strip(Sale_D), ?? ANYDTDTE12.);
	Format Sale_Date ddmmyy10.;
	Channel=Propcase(Channel1);
	Discount_Pct=Input(Strip(DCT), ?? 8.);
	Discount_Pct=Discount_Pct/100;
	If Discount_Pct=. then Discount_Pct=0.05;
	Format Discount_Pct percent8.2;
run;

proc sort data=Sales_Base;
	by Product_Name;
run;

Proc stdize data=Sales_Base out=Sales_Median method=median reponly;
	by Product_Name;
	var Units_Sold Unit_Price;
run;

data Sales_Derivation;
	Set Sales_Median;
	length Revenue 8.;
	Revenue=Units_Sold * Unit_Price;
	Discount_Amt=Revenue * Discount_Pct;
	Net_Revenue=Revenue - Discount_Amt;
	If Product_Name="Vitaboost" then Cost_Per_unit=Unit_Price * 0.6;
	If Product_Name="Painrelief-X" then Cost_Per_unit=Unit_Price * 0.5;
	If Product_Name="Antibio-Plus" then Cost_Per_unit=Unit_Price * 0.55;
	If Product_Name="Coldcure" then Cost_Per_unit=Unit_Price * 0.45;
	Profit=Net_Revenue - (Cost_Per_unit * Units_Sold);
	if Revenue > 0 then Profit_Margin=(Profit/Revenue);
	else Profit_Margin=.;
	format Revenue Rupee.;
	format Net_Revenue Rupee.;
	format Profit Rupee.;
	Format Profit_Margin percent8.2;
	Format Unit_Price Rupee.;
run;

/* Top Profit Generating Product visualization (their PROC SGPLOT) */
proc sql;
	Create table Performance_analysis as select Product_Name, sum(Profit) as
		Total_Profit format=Rupee.
from Sales_Derivation group by Product_Name order by calculated Total_Profit desc;
quit;

Proc Sgplot data=Performance_analysis;
	Hbar Product_Name / Response=Total_profit group=Product_Name
		baselineattrs=(color=Black);
	xaxis label="Profit Generated" valueattrs=(size=10 weight=bold)
		labelattrs=(Color=Black weight=Bold size=11 style=Italic);
	yaxis label="Name of the products" valueattrs=(size=10 weight=bold)
		labelattrs=(Color=Black weight=Bold size=11 style=Italic);
	title "Top  Profit Generating Product";
run;
