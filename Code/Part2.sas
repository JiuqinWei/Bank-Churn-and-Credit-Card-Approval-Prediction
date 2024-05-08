PROC IMPORT DATAFILE='/home/u63376849/STAT675/application_record.csv'
    OUT=work.data
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
    DATAROW=2;
RUN;

PROC IMPORT DATAFILE='/home/u63376849/STAT675/credit_record.csv'
    OUT=work.record
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
    DATAROW=2;
RUN;

/* Rename columns */
data data;
	set data;
	rename CODE_GENDER = Gender;
	rename FLAG_OWN_CAR = Car;
	rename FLAG_OWN_REALTY = Property;
	rename CNT_CHILDREN = ChldNo;
	rename AMT_INCOME_TOTAL = Inc;
	rename NAME_EDUCATION_TYPE = Edutp;
	rename NAME_FAMILY_STATUS = Famtp;
	rename NAME_HOUSING_TYPE = Houtp;
	rename FLAG_EMAIL = Email;
	rename NAME_INCOME_TYPE = Inctp;
	rename FLAG_MOBIL = Mobile;
	rename FLAG_WORK_PHONE = Wkphone;
	rename FLAG_PHONE = Phone;
	rename CNT_FAM_MEMBERS = Famsize;
	rename OCCUPATION_TYPE = Occyp;
run;

/* Count how many people in each dataset */
proc sql;
    select count(distinct ID) as Total_People
    from data;
quit;

proc sql;
    select count(distinct ID) as Total_People
    from record;
quit;

/* Numerically Encode STATUS */
data record;
    set record;
    if STATUS = '0' then Numeric_STATUS = 0;
    else if STATUS = '1' then Numeric_STATUS = 1;
    else if STATUS = '2' then Numeric_STATUS = 1;
    else if STATUS = '3' then Numeric_STATUS = 1;
    else if STATUS = '4' then Numeric_STATUS = 1;
    else if STATUS = '5' then Numeric_STATUS = 1;
    else if STATUS = 'C' then Numeric_STATUS = -1;
    else if STATUS = 'X' then Numeric_STATUS = -1;
run;

/* Calculate Average STATUS per ID */
proc sql;
    create table id_status_avg as
    select ID, round(mean(Numeric_STATUS)) as Avg_Status
    from record
    group by ID;
quit;

/* Merge Average STATUS Back to Original Data */
proc sql;
    create table analysis_data as
    select a.*, b.Avg_Status
    from record a
    left join id_status_avg b
    on a.ID = b.ID;
quit;

/* Inner Join data and analysis_data on ID */
proc sql;
    create table result as
    select a.*, b.Avg_Status
    from data as a
    inner join analysis_data as b
    on a.ID = b.ID;
quit;

/* Convert days_birth and employment_duration to years */
data result; 
    set result;
    Age = -DAYS_BIRTH / 365.25;
    Employment_Duration = -DAYS_EMPLOYED / 365.25;
    drop DAYS_BIRTH DAYS_EMPLOYED Mobile;
run;

/* Remove missing values and duplicates if necessary */
data result_clean;
	set result;
	if cmiss(of _all_) then delete;
run;

proc sql;
    create table clean_dataset as
    select distinct * 
    from result_clean;
quit;

/* EDA of pre-processed dataset */
proc contents data=clean_dataset;
run;

proc print data=clean_dataset(obs=10);
run;

proc means data=clean_dataset N NMISS mean stddev min max;
run;

proc freq data=clean_dataset;
	tables Avg_Status Gender Car Edutp Famtp Houtp Inctp Occyp Property Wkphone Phone Email;
run;

/* Multinomial Logistic Regression */
*ods select ParameterEstimates;
proc logistic data=clean_dataset;
	class Avg_Status (ref  "-1") Gender Car Property Inctp Edutp Famtp Houtp Wkphone Phone Email Occyp / param=ref;
	model Avg_Status = Gender Car Property ChldNo Inc Inctp Edutp Famtp Houtp Wkphone Phone Email Occyp Famsize Age Employment_Duration / link=glogit aggregate scale=none selection=backward;
	*ods output ParameterEstimates=Estimates;
run;

/* LASSO */
proc glmselect data=clean_dataset;
   class Avg_Status (ref="-1") Gender Car Property Inctp Edutp Famtp Houtp Wkphone Phone Email Occyp / param=ref;
   model Avg_Status = Gender Car Property ChldNo Inc Inctp Edutp Famtp Houtp Wkphone Phone Email Occyp Famsize Age Employment_Duration / selection=elasticnet;
run;

/* Ordinal Logistic Regression */
proc format;
	value as 1='(3) At risk ' 0='(2) Semi-risk' -1='(1) No risk';
run;

proc logistic data=clean_dataset;
	class Avg_Status Gender Car Property Inctp Edutp Famtp Houtp Wkphone Phone Email Occyp / param=ref;
	model Avg_Status(order=internal) = Gender Car Property ChldNo Inc Inctp Edutp Famtp Houtp Wkphone Phone Email Occyp Famsize Age Employment_Duration;
	output out=probs1 predicted=prob xbeta=logit;
	format Avg_Status as.;
	title3 "Logistic regression ascending predict less than or equal to";
run;

proc logistic data=clean_dataset;
	class Avg_Status Gender Car Property Inctp Edutp Famtp Houtp Wkphone Phone Email Occyp / param=ref;
	model Avg_Status(order=internal descending) = Gender Car Property ChldNo Inc Inctp Edutp Famtp Houtp Wkphone Phone Email Occyp Famsize Age Employment_Duration / link=glogit scale=none selection=backward;
	output out=probs1 predicted=prob xbeta=logit;
	title3 "Logistic regression descending predict greater than or equal to" ;
run;