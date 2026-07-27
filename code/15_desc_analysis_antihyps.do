/*=========================================================================
DO FILE NAME:			14_desc_stats_antihyps

AUTHOR:					Mia
						
DATE CREATED:			18/06/2025

DESCRIPTION OF FILE:	Descriptive analysis of number, type and name of antihyps prescribed during study period
*=========================================================================*/

* create new log
cap log close
log using "${logfiles}/14_desc_stats_antihyps.log", text replace


foreach drug in C03 C08 C09 allclasses {

/******************************************************************
Drug interval durations
*****************************************************************/

putexcel set "$output/desc_anal_antihyp_intervals.xlsx", sheet("`drug'") modify
putexcel B1 = "drug_interval_duration"
putexcel C1 = "nodrug_interval_duration"
putexcel A2 = "mean"
putexcel A3 = "sd"
putexcel A4 = "median"
putexcel A5 = "p25"
putexcel A6 = "p75"

use "$datafile/hypertension_`drug'_intervals", clear

*drug intervals
preserve
keep if drugexposed==1
gen duration_interval = interend - interstart
tabstat duration_interval, stat(mean sd median p25 p75) save
return list
matrix list r(StatTotal)
matrix stats = r(StatTotal)
putexcel B2 = matrix(stats)
restore

*no drug intervals
preserve
keep if drugexposed==0
gen duration_interval = interend - interstart
tabstat duration_interval, stat(mean sd median p25 p75) save
return list
matrix list r(StatTotal)
matrix stats = r(StatTotal)
putexcel C2 = matrix(stats)
restore

}

/******************************************************************
Type and frequency of antihypertensives
*****************************************************************/

* C03
use "$datafile/antihyp_C03_rxall.dta", clear
drop if drug_name==""
drop if drug_name=="valsartan + diuretic" | drug_name=="telmisartan + diuretic" | drug_name=="irbesartan + diuretic" | drug_name=="losartan + diuretic" | drug_name=="candesartan + diuretic"

contract drug_name
rename _freq freq
summarize freq, meanonly
scalar total = r(sum)

gen percent = 100*freq/total
gen cum_percent=.
gsort -freq
replace cum_percent=100 if _n==1
gsort -freq
replace cum_percent=cum_percent[_n-1]-percent[_n-1] if cum_percent==.

replace percent=round(percent, 0.01)
replace cum_percent=round(cum_percent, 0.01)

merge 1:m drug_name using "$datafile/antihyp_C03_rxall.dta", keep(match) keepusing(who_atc) nogen
duplicates drop

order who_atc drug_name freq percent cum_percent
gsort -cum_percent
export excel using "$output/desc_anal_antihyp_type.xlsx", firstrow(variables) sheet("C03", modify)

* C08
use "$datafile/antihyp_C08_rxall.dta", clear
drop if drug_name==""
replace drug_name="amlodipine" if drug_name=="valsartan + amlodipine" | drug_name=="telmisartan + amlodipine" | drug_name=="irbesartan + amlodipine" | drug_name=="candesartan + amlodipine"

contract drug_name
rename _freq freq
summarize freq, meanonly
scalar total = r(sum)

gen percent = 100*freq/total
gen cum_percent=.
gsort -freq
replace cum_percent=100 if _n==1
gsort -freq
replace cum_percent=cum_percent[_n-1]-percent[_n-1] if cum_percent==.

replace percent=round(percent, 0.01)
replace cum_percent=round(cum_percent, 0.01)

merge 1:m drug_name using "$datafile/antihyp_C08_rxall.dta", keep(match) keepusing(who_atc) nogen
duplicates drop

order who_atc drug_name freq percent cum_percent
gsort -cum_percent
export excel using "$output/desc_anal_antihyp_type.xlsx", firstrow(variables) sheet("C08", modify)


* C09
use "$datafile/antihyp_C09_rxall.dta", clear

drop if drug_name==""
replace drug_name="valsartan" if drug_name=="valsartan + amlodipine" | drug_name=="valsartan + diuretic" 
replace drug_name="telmisartan" if drug_name=="telmisartan + amlodipine" | drug_name=="telmisartan + diuretic"
replace drug_name="irbesartan" if drug_name=="irbesartan + amlodipine" | drug_name=="irbesartan + diuretic"
replace drug_name="losartan" if drug_name=="losartan + diuretic"
replace drug_name="candesartan" if drug_name=="candesartan + amlodipine" | drug_name=="candesartan + diuretic"

contract drug_name
rename _freq freq
summarize freq, meanonly
scalar total = r(sum)

gen percent = 100*freq/total
gen cum_percent=.
gsort -freq
replace cum_percent=100 if _n==1
gsort -freq
replace cum_percent=cum_percent[_n-1]-percent[_n-1] if cum_percent==.

replace percent=round(percent, 0.01)
replace cum_percent=round(cum_percent, 0.01)

merge 1:m drug_name using "$datafile/antihyp_C09_rxall.dta", keep(match) keepusing(who_atc) nogen
duplicates drop

order who_atc drug_name freq percent cum_percent
gsort -cum_percent
export excel using "$output/desc_anal_antihyp_type.xlsx", firstrow(variables) sheet("C09", modify)

/******************************************************************
Antihypertensive prescription trends
*******************************************************************/
foreach drug in C03 C08 C09 allclasses {
use "$datafile/antihyp_`drug'_rxall.dta", clear
gen month = month(prescription_date)
gen year = year(prescription_date)
gen year_month = ym(year, month)
contract year_month
drop if year_month==650
format year_month %tm
rename _freq freq_`drug'
save "$datafile/desc_anal_antihyp_monthly_rx_`drug'.dta", replace
export excel using "$output/desc_anal_antihyp_monthly_rx.xlsx", firstrow(variables) sheet("`drug'", modify)

}

log close