/*=========================================================================
DO FILE NAME:			6_create_antihyp_episodes

AUTHOR:					Angel Wong, adapted by Mia Harley

VERSION:				v1
			
DATABASE:				Japanese claims data

Aim: 					To identify episodes of drug exposure, allowing 30 day grace period
*=============================================================================*/

* create new log
cap log close
log using "${logfiles}/6_create_antihyp_episodes", text replace

/******************************************************************
Identify people with hypertension prescribed antihypertensives
*****************************************************************/
use "$datafile/antihyp_${drug}_rxall.dta", clear

*merge those with hypertension diagnosis
merge m:1 patid using "$datafile/hypertension_patients", keep(match) nogen
drop if rxst > obs_end
drop if rxen < obs_start

replace rxen=obs_end if rxen>obs_end
replace rxst=obs_start if rxst<obs_start

save "$datafile/hypertension_${drug}", replace

*save a record with only one patient per row
duplicates drop patid, force
save "$datafile/hypertension_${drug}_hc", replace

*generate a dataset to help identify if they have multiple diuretics
use "$datafile/hypertension_${drug}", clear
drop if year(rxst) < $studystartyear | year(rxst) > $studyendyear

preserve
sort patid rxst rxen drug_type
bysort patid rxst rxen drug_type: keep if _n==1
save "$datafile/hypertension_${drug}_rd", replace
restore

/******************************************************************
Identify episodes of antihypertensives among people with hypertension
*****************************************************************/

*identify all antihypertensive prescriptions among hypertensive patients
*handle overlapping prescriptions

*Handle prescription gaps
sort patid rxst rxen
keep patid rxst rxen
drop if rxst > rxen

by patid: gen episode=_n

rename rxst timerxst
rename rxen timerxen

*Start the steps of handling overlapping by reshaping the data
reshape long time, i(patid episode) j(start_end) string

*Encode the start and end for ranking the order for "rxst" first
gen start_end2= 0 if start_end=="rxst"
replace start_end2=1 if start_end=="rxen"

by patid (time start_end2), sort: gen int in_proc = sum(start_end == "rxst") - sum(start_end == "rxen")
replace in_proc = 1 if in_proc > 1
by patid (time): gen block_num = 1 if in_proc == 1 & in_proc[_n-1] != 1
by patid (time): replace block_num = sum(block_num)

by patid block_num (time), sort: assert start_end == "rxst" if _n == 1
by patid block_num (time): assert start_end == "rxen" if _n == _N
by patid block_num (time): keep if _n == 1 | _n == _N

drop episode in_proc start_end2
reshape wide time, i(patid block_num) j(start_end) string
rename time* *
order rxst, before(rxen)

by patid: gen episode=_n
keep patid episode rxst rxen

rename rxst timerxst
rename rxen timerxen

reshape long time, i(patid episode) j(start_end) string

gen start_end2= 0 if start_end=="rxst"
replace start_end2=1 if start_end=="rxen"

by patid (time start_end2), sort: gen gap_num = 1 if start_end == "rxst" & (time- time[_n-1]<=1) //change the number of days here
replace gap_num = 1 if start_end == "rxen" & gap_num[_n+1] == 1
egen gap_num_max=max(gap_num), by (patid episode)

keep if (gap_num_max==1 & gap_num==.) | (gap_num==. & gap_num_max ==.)

drop gap_num gap_num_max episode start_end2

*change the episode no as rx for reshaping the wide form
egen rx =seq(), f(1) b(2)
reshape wide time, i(patid rx) j(start_end) string
rename time* *
order rxst, before(rxen)

count 

keep patid rxst rxen

*Further combining Rxs for their gap >30 between Rxs 
by patid: gen episode=_n
keep patid episode rxst rxen

rename rxst timerxst
rename rxen timerxen

reshape long time, i(patid episode) j(start_end) string

gen start_end2= 0 if start_end=="rxst"
replace start_end2=1 if start_end=="rxen"

by patid (time start_end2), sort: gen gap_num = 1 if start_end == "rxst" & (time- time[_n-1]<=${graceperiod}) //30 day grace period
replace gap_num = 1 if start_end == "rxen" & gap_num[_n+1] == 1
egen gap_num_max=max(gap_num), by (patid episode)

keep if (gap_num_max==1 & gap_num==.) | (gap_num==. & gap_num_max ==.)

drop gap_num gap_num_max episode start_end2

*change the episode no as rx for reshaping the wide form
egen rx =seq(), f(1) b(2)
reshape wide time, i(patid rx) j(start_end) string
rename time* *
order rxst, before(rxen)

count 

keep patid rxst rxen

sort patid rxst rxen

merge m:1 patid using "$datafile/hypertension_patients.dta", keepusing(obs_start obs_end)

*remove people with  drug date outside observation period
drop if rxen < obs_start
drop if rxst > obs_end

replace rxst = obs_start if rxst < obs_start
replace rxen = obs_end if rxen > obs_end
drop if rxst > rxen

rename rxst rxst_${drug}
rename rxen rxen_${drug}

keep patid rxst_${drug} rxen_${drug} obs_start obs_end

save "$datafile/hypertension_${drug}_episodes", replace


/**********************************************************************
identify dataset containing people with hypertension without antihypertensives, who experienced heatwave 
**********************************************************************/
use "$datafile/hypertension_${drug}_episodes", clear
duplicates drop patid, force
tempfile hypertension_${drug}
save `hypertension_${drug}'

*people without antihypertensives
use "$datafile/hypertension_heatwave", clear
merge m:1 patid using `hypertension_${drug}', keep(master) nogen
save "$datafile/hypertension_heatwave_${drug}_noantihyp", replace

log close
