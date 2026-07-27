/*=========================================================================
DO FILE NAME:			1_import_temp_data

AUTHOR:					Angel Wong, adapted by Mia Harley
						
VERSION:				v1
					
DATABASE:				Temperature data Tsukuba City
	
DESCRIPTION OF FILE:	identify heatwave from temperature dataset

DATASETS USED:		"$datafile/mean_temp_tsukuba.csv"

DATASETS CREATED: 	"$datafile/MEANT_heatwave_date"									

MORE INFORMATION:	1. Load the temperature data to Stata
					2. Identify heatwave dates using the temperature dataset

*=========================================================================*/

* create new log
cap log close
log using "${logfiles}/1_import_temp_data.log", text replace

/******************************************************************
Process climate data
*****************************************************************/

use "Z:\Mia\Original data\temp_data_Tsukuba.dta", clear

gen day= day(date)
gen month= month(date)
gen year= year(date)

keep if year >= 2014 & year <=2019

order date day month year mean_temp min_temp max_temp

drop city

save "$datafile\tsukuba_temp_data.dta", replace

/******************************************************************
Identify heatwaves
*****************************************************************/

*Use heatwave definition of >= 2 consecutive days with daily mean temperature 
*exceeding 95% percentile of the year round from recent data
*https://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1002629
*find the temperature 95% percentile for each year

use "$datafile\tsukuba_temp_data.dta", clear
drop max_temp min_temp

preserve
keep if year == 2014
su mean_temp, detail
return list
restore

gen over_95_temp = 1 if year == 2014 & mean_temp >= r(p95)

forval yr = 2014/2019 {
preserve
keep if year == `yr'
bysort year: su mean_temp, detail
return list
restore
replace over_95_temp = 1 if year == `yr' & mean_temp >= r(p95)
}

sort date

gen heatwave_95 = 1 if over_95_temp==1 & (over_95_temp[_n-1]==1 | over_95_temp[_n+1]==1)

save "$datafile\MEANT_tsukuba_final.dta", replace

*generate a heatwave dataset
keep if heatwave_95 == 1 
clonevar date_end=date
rename date date_start
gen Referencekey = 1
sort Referencekey date_start date_end
by Referencekey: gen episode=_n

keep Referencekey date_start date_end episode

rename date_start timerxst
rename date_end timerxen

/************************************************************************
**************************************************************************
Start the steps of handling overlapping by reshaping the data
************************************************************************
*************************************************************************/
reshape long time, i(Referencekey episode) j(start_end) string

*Encode the start and end for ranking the order for "rxst" first
gen start_end2= 0 if start_end=="rxst"
replace start_end2=1 if start_end=="rxen"

by Referencekey (time start_end2), sort: gen int in_proc = sum(start_end == "rxst") - sum(start_end == "rxen")
replace in_proc = 1 if in_proc > 1
by Referencekey (time): gen block_num = 1 if in_proc == 1 & in_proc[_n-1] != 1
by Referencekey (time): replace block_num = sum(block_num)

by Referencekey block_num (time), sort: assert start_end == "rxst" if _n == 1
by Referencekey block_num (time): assert start_end == "rxen" if _n == _N
by Referencekey block_num (time): keep if _n == 1 | _n == _N

drop episode in_proc start_end2
reshape wide time, i(Referencekey block_num) j(start_end) string
rename time* *
order rxst, before(rxen)

by Referencekey: gen episode=_n
keep Referencekey episode rxst rxen

rename rxst timerxst
rename rxen timerxen

reshape long time, i(Referencekey episode) j(start_end) string

gen start_end2= 0 if start_end=="rxst"
replace start_end2=1 if start_end=="rxen"

by Referencekey (time start_end2), sort: gen gap_num = 1 if start_end == "rxst" & (time- time[_n-1]<=1) //change the number of days here
replace gap_num = 1 if start_end == "rxen" & gap_num[_n+1] == 1
egen gap_num_max=max(gap_num), by (Referencekey episode)

keep if (gap_num_max==1 & gap_num==.) | (gap_num==. & gap_num_max ==.)

drop gap_num gap_num_max episode start_end2

*change the episode no as rx for reshaping the wide form
egen rx =seq(), f(1) b(2)
reshape wide time, i(Referencekey rx) j(start_end) string
rename time* *
order rxst, before(rxen)

count 

keep rxst rxen

rename rxst hw_start
rename rxen hw_end

gen obs=1

save "$datafile\MEANT_heatwave_tsukuba_date", replace

log close