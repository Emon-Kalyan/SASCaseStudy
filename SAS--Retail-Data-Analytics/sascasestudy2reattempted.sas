libname cs2 "/folders/myfolders/cs2/casestudyfiles/";
proc import datafile="/folders/myfolders/cs2/casestudyfiles/POS_Q1.csv" out=cs2.pos_q1 dbms=csv replace;
proc import datafile="/folders/myfolders/cs2/casestudyfiles/POS_Q2.csv" out=cs2.pos_q2 dbms=csv replace;
proc import datafile="/folders/myfolders/cs2/casestudyfiles/POS_Q3.csv" out=cs2.pos_q3 dbms=csv replace;
proc import datafile="/folders/myfolders/cs2/POS_Q4.csv" out=cs2.pos_q4 dbms=csv replace;
proc import datafile="/folders/myfolders/cs2/Laptops.csv" out=cs2.laptops dbms=csv replace;
proc import datafile="/folders/myfolders/cs2/Store_Locations.csv" out=cs2.store_locations dbms=csv replace;
proc import datafile="/folders/myfolders/cs2/London_postal_codes.csv" out=cs2.london_postal_codes dbms=csv replace;
/* the store_code name is not in the csv file ??? */

/* Understanding the datasets  */
proc contents data = cs2._all_ ;

/* sorting the data to combine laptop data and ps quarters data */
proc sort data=cs2.pos_q1;
by configuration;
proc sort data=cs2.pos_q2;
by configuration;
proc sort data=cs2.pos_q3;
by configuration;
proc sort data=cs2.pos_q4;
by configuration;
proc sort data = cs2.laptops;
by configuration;
proc sort data = cs2.store_locations;
by store_code;
proc sort data = cs2.london_postal_codes;
by postcode;

data cs2.pos1combo;
merge cs2.pos_q1(in = a) cs2.laptops(in = b);
by configuration;
if a = b;
run;
data cs2.pos2combo;
merge cs2.pos_q2(in = a) cs2.laptops(in = b);
by configuration;
if a = b;
run;
data cs2.pos3combo;
merge cs2.pos_q3(in = a) cs2.laptops(in = b);
by configuration;
if a = b;
run;
data cs2.pos4combo;
merge cs2.pos_q4(in = a) cs2.laptops(in = b);
by configuration;
if a = b;
run;

data cs2.combo;
set cs2.pos1combo cs2.pos2combo cs2.pos3combo cs2.pos4combo;
proc sort data = cs2.combo;
by store_postcode;
data cs2.store_locations;
set cs2.store_locations;
rename store_code = store_postcode;
proc sort data = cs2.store_locations;
by store_postcode;
data cs2.combo;
merge cs2.combo(in = a) cs2.store_locations(in = b);
by store_postcode;
if a = b;
run;
data cs2.london_postal_codes;
set cs2.london_postal_codes;
rename postcode = customer_postcode;
proc sort data = cs2.combo;
by customer_postcode;
data cs2.combo;
merge cs2.combo(in = a) cs2.london_postal_codes(in = b);
by customer_postcode;
if a = b;
run;
/* the data cs2.combo is ready for the analysis */
proc sort data = cs2.combo;
by month;


data cs2.combo;
set cs2.combo;
if month = 1 or month = 2 or month = 3 then quarter =1;
else if month = 4 or month = 5 or month = 6 then quarter =2;
else if month =7 or month = 8 or month = 9 then quarter =3;
else quarter = 4;

/* reporting the prices by quarter */

ods pdf file="/folders/myfolders/cs2/casestudyfiles/timewisepriceanly.pdf";
proc report data = cs2.combo style(header) = [backgroundcolor= grey];
title "report of average prices in each quarter";
columns quarter retail_price;
define quarter/group "define";
define retail_price/analysis mean "Average_Retail_Price";
rbreak after/summarize dol;
run;
proc report data = cs2.combo style(header) = [backgroundcolor= grey]
style(summary)=[backgroundcolor=grey];
title "report of average prices in each quarter";
columns quarter month retail_price;
define quarter/group "define";
define month/group "Month";
define retail_price/analysis mean "Average_Retail_Price";
break after quarter/summarize;
rbreak after/summarize dol;
run;

proc freq data = cs2.combo nlevels order=freq;
table quarter month;

proc freq data = cs2.combo nlevels;
table quarter*month/norow nocol nopercent chisq;
run;

proc means data = cs2.combo nmiss n sum;
by quarter;
class month;
var quarter;
run;

data cs2.combo1;
set cs2.combo;
by month;
if first.month = 1 then first_month = 1;
else first_month = 0 ;
if last.month = 1 then last_month = 1;
else last_month = 0;
run;

data cs2.combo1;
set cs2.combo1;
if first_month = 1 then Tot_price = 0;
else tot_price + retail_price;
if last_month = 1 then output;
run;

proc tabulate data = cs2.combo;
class quarter month;
var retail_price;
table month * ( mean = "Price" pctsum<month> = "% of columns" pctsum<quarter> = "% of row"
pctsum = "% of all" ),
quarter * retail_price ;
title "monthwise and quarterwise anlaysis of prices";
run;
ods pdf close;

/* understanding price distribution across configurations */

ods pdf file="/folders/myfolders/cs2/casestudyfiles/configurationwiseprice.pdf";
proc format;
value retail_price_format
160 - 250 = "$(160-250)"
251 - 500 = "$(251-500)"
501 - 750 = "$(501-750)"
751 - 900 = "$(751-900)";

proc freq data = cs2.combo;
tables configuration*retail_price;
format retail_price retail_price_format. ;
run;

/* From the table we see that the distribution of price range varies across all the
configuration */

proc tabulate data = cs2.combo;
class quarter configuration;
var retail_price;
table configuration*(mean = "mean_retailprices" pctsum<configuration>="% of all config"),
quarter*retail_price;
run;
ods pdf close;
/* we can see that there is variation of retail prices amongst all the
configuration in each quarters in a range from 1% to .01%  */


/* calculating the distance between two stores, distance between two stores and the average 
customers */
ods pdf file= "/folders/myfolders/cs2/casestudyfiles/distancewiseanalysis.pdf";
proc means data = cs2.combo;
var os_x_str os_y_str os_x os_y;

data cs2.combo;
set cs2.combo;
dist_betwn_strs = sqrt((os_x_str - 530247 )**2 + (os_y_str - 180359)**2);
dist_betn_custstr = sqrt((os_x_str - os_x)**2 + (os_y_str - os_y)**2 );
run;
proc means data = cs2.combo mean std var min max P25 P50 P75;
var dist_betwn_strs dist_betn_custstr;
run;

proc format lib = cs2.fmt ;
value distbetwnstrs
797 - 2330 = " 797 - 2330"
2332 - 4956 = "2332 - 4956"
4957 - 7263 = "4957 - 7263"
7263 - 15949 = "7263 - 15949";

value disbetwncuststr
0 - 2379 = "0 - 2379"
2380 - 3447 = "2380 - 3447 "
3448 -  4548 = "3448 - 4548"
4549 - 19892 = "4549 - 19892 ";

/* proc freq data = cs2.combo; */
/* tables retail_price*dist_betn_custstr; */
/* format retail_price retail_price_format.; */
/* format dist_betn_custstr disbetwncuststr.; */
/* run; */

options fmtsearch= (cs2.fmt);
data cs2.combo;
set cs2.combo;
format dist_betn_custstr disbetwncuststr.;

proc report data = cs2.combo style(header)=[backgroundcolor=grey];
columns dist_betn_custstr retail_price;
define dist_betn_custstr/group;
define retail_price/mean;
rbreak after/summarize;
run;
/* from the above report we see that the sales of laptops donot decrease with increase in custstr 
distance */

proc sql;
create table cs2.custcnt as
select count( distinct customer_postcode) as cust_count,  dist_betn_custstr
from cs2.combo
group by dist_betn_custstr;
quit;

proc report data = cs2.custcnt;
columns dist_betn_custstr cust_count;
define dist_betn_custstr/group 'dist_betn_custstr';
define cust_count/sum "cust_count";
rbreak after/summarize;
quit;
ods pdf close;

/* understanding the configuration and price distribution */
ods pdf file="/folders/myfolders/cs2/casestudyfiles/configuration.pdf";
data cs2.combo;
set cs2.combo;
rename processor_speeds__ghz_ = processorspeeds;
rename screen_size__inches_ = screensize;
rename battery_life__hours_ = batterylife;
rename ram__gb_ = ram;
rename hd_size__gb_ = hdsize;
run;
/* the attributes of each configuration are understood with proc means */

proc means data = cs2.combo n nmiss std mean min P25 P50 P75 max;
var screensize processorspeeds batterylife ram hdsize;
run;


proc format lib = cs2.fmt1;
value processorspeeds
1.5 - 2 = "1.5 - 2"
2.1 - 2.5 = "2 - 2.5";
value batterylife
4 - 5 = "4 - 5"
5.1 - 6 = "5.1 - 6";
value screensize
15 - 16 = "15-16"
16.1 - 17 = "16.1 - 17";
value ram
1 - 2.5 = "1 - 2.5"
2.6 - 4 = "2.6 - 4";
value hdsize
13 - 105 = "13-105"
105 - 170 = "105 - 170"
235 - 300 = "235 - 300";

options fmtsearch=(cs2.fmt1);
data cs2.combo1;
set cs2.combo;
format screensize screensize. processorspeeds processorspeeds
ram ram. hdsize hdsize. batterylife batterylife. reatil_price retail_price_format.;

proc freq data = cs2.combo1;
tables retail_price*screensize;
format retail_price retail_price_format.;
run;

proc report data = cs2.combo1 style(header) = [backgroundcolor=grey]
style(summary) = [backgroundcolor=grey];
columns screensize retail_price;
define screensize/group;
define retail_price/mean;
rbreak after/summarize;
run;
/* We see that the mean price increases with the increase in screensize  */
proc report data = cs2.combo1 style(header) = [backgroundcolor=grey]
style(summary) = [backgroundcolor=grey];
columns batterylife retail_price;
define batterylife/group;
define retail_price/mean;
rbreak after/summarize;
run;
proc report data = cs2.combo1 style(header) = [backgroundcolor=grey]
style(summary) = [backgroundcolor=grey];
columns processorspeeds retail_price;
define processorspeeds/group;
define retail_price/mean;
run;
proc report data = cs2.combo1 style(header) = [backgroundcolor=grey]
style(summary) = [backgroundcolor=grey];
columns ram retail_price;
define ram/group;
define retail_price/mean;
rbreak after/summarize;
run;
proc report data = cs2.combo1 style(header) = [backgroundcolor=grey]
style(summary) = [backgroundcolor=grey];
columns hdsize retail_price;
define hdsize/group;
define retail_price/mean;
rbreak after/summarize;
run;
/* We see that the prices increases with increase in the configuration of the attributes */
proc sql;
create table cs2.configprice as
select count(configuration) as count, screensize 
from cs2.combo1
group by screensize;
quit;
proc sql;
create table cs2.configprice as
select count(configuration) as count, processorspeeds 
from cs2.combo1
group by processorspeeds;
quit;
proc sql;
create table cs2.configprice as
select count(configuration) as count, batterylife
from cs2.combo1
group by batterylife;
quit;
/* the sales volume for battery life is higher for the lower seg of 4 - 5 */
proc sql;
create table cs2.configprice as
select count(configuration) as count, hdsize
from cs2.combo1
group by hdsize;  
quit;
proc sql;
create table cs2.configprice as
select count(configuration) as count, ram
from cs2.combo1
group by ram;;
quit;

/* the lower config attributes show higher sales volume  */

/* proc report data = cs2.combo1; */
/* columns screensize retail_price "Retailprice" = retail_price; */
/* define screensize/group; */
/* define retail_price/mean; */
/* define Retailprice/analysis; */

proc means data = cs2.combo1 sum;
var retail_price;
run;

/* 87720508 */

proc sql;
create table cs2.propsales
as select sum(retail_price) as sum_prices, screensize, 
(sum(retail_price)/87720508) as prop_sales 
from cs2.combo1
group by screensize;
quit;

data cs2.combo1;
set cs2.combo1;
proc sql;
create table cs2.propsales1
as select sum(retail_price) as sum_prices, processorspeeds, 
(sum(retail_price)/87720508) as prop_sales 
from cs2.combo1
group by processorspeeds;
quit;
proc sql;
create table cs2.propsales1
as select sum(retail_price) as sum_prices, batterylife, 
(sum(retail_price)/87720508) as prop_sales 
from cs2.combo1
group by batterylife;
quit;
proc sql;
create table cs2.propsales3
as select sum(retail_price) as sum_prices, ram, 
(sum(retail_price)/87720508) as prop_sales 
from cs2.combo1
group by ram;
quit;
proc sql;
create table cs2.propsales
as select sum(retail_price) as sum_prices, hdsize, 
(sum(retail_price)/87720508) as prop_sales 
from cs2.combo1
group by hdsize;
quit;

/* the sales proportions are almost equal for all the configuration attributes except screensize
the proportion of sales for lower screensize is higher */
proc means data = cs2.combo1 n;
var configuration;
/* 174495 */
proc sql;
create table propvol as
select screensize, count(configuration)/174495 as config_prop
from cs2.combo1
group by screensize;
quit;

/* we have seen that smaller the screen size haigher is the sales prop	  */
proc sql;
create table propvol as
select  processorspeeds, count(configuration)/174495 as config_prop
from cs2.combo1
group by processorspeeds;
quit;
proc sql;
create table propvol as
select batterylife, count(configuration)/174495 as config_prop
from cs2.combo1
group by batterylife;
quit;
/* The highest sales volume had been for 5 hours batterylife */
proc sql;
create table propvol as
select hdsize, count(configuration)/174495 as config_prop
from cs2.combo1
group by hdsize;
quit;
/* 40 GB hdsize is showing highest sales volume */
proc sql;
create table propvol as
select ram, count(configuration)/174495 as config_prop
from cs2.combo1
group by ram;
quit;
/* Intermidiate ram size of 2 gb is showing highest sales volume  */

proc tabulate data = cs2.combo1;
class screensize batterylife ram;
var configuration;
table screensize*(n = "salesvolcount" pctsum = "% of all"), batterylife;
table screensize*(n = "salesvolcount" pctsum = "% of all"), ram;
run;

proc tabulate data = cs2.combo1;
class screensize batterylife ram;
var retail_price;
table screensize*( sum = "salescount" pctsum = "% of all"), batterylife*retail_price;
table screensize*( sum = "salescount" pctsum = "% of all"), ram*retail_price;
run;

/* proc tabulate shows that higher battery life is of higher sales volume along with a 
low screensize and intermediate ram */

proc sql;
select count( distinct configuration) as config_count
from cs2.combo1;
quit;
/* 864  */
proc sql;
select count(distinct configuration) as config_count, store_postcode
from cs2.combo
group by store_postcode;
quit;
/* All stores donot sell all configurations */
ods pdf close;

/* quest-4 how revenue is influenced by different factors */

/* how sales volume is related to revenue in each store */
ods pdf file= "/folders/myfolders/cs2/casestudyfiles/revenue.pdf";
proc sql;
create table cs2.revenueandvolume as
select sum(retail_price) as revenue, count(configuration) as sales_volume, store_postcode,
sum(retail_price)/87720508 as prop_revenue, count(configuration)/174495 as prop_vol
from cs2.combo1
group by store_postcode;
quit;
proc sort data = cs2.revenueandvolume;
by sales_volume;
run;
proc means data = cs2.revenueandvolume n nmiss min P25 P50 P75 max;
var revenue sales_volume;
run; 
data cs2.revenueandvolume;
set cs2.revenueandvolume;
/* Thus we see that the revenue increase with the sale_volume */

/* How does revenue depend on configuration  */

proc sql;
create table cs2.revvsconfig as
select sum(retail_price) as revenue, configuration
from cs2.combo1
group by configuration;
quit;
proc sort data = cs2.revvsconfig;
by revenue;
ods pdf close;
/* The highest revenue is earned by configuration 204 and the 
lowest revenue is earned by configuration 578 */

/* Statistical technique which should be used for predicting the sales in 2010 is
time-series analysis  */














