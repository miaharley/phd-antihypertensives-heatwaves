/*=========================================================================
DO FILE NAME:			17_sccs_sens_analysis_exclhosp_v2

AUTHOR:					Mia Harley

VERSION:				v1	
					
DATABASE:				Japanese claims data

DESCRIPTION OF FILE:	Runs SCCS (main and subgroup analysis) but remove inpatient follow up periods
*=========================================================================*/

* create new log
cap log close
log using "${logfiles}/17_sccs_sens_analysis_exclhosp_${drug}_${outcome}_v2", text replace

/*****************************************************************/
* 1. Identify in-patient episodes
/*****************************************************************/

* Get inpatient periods for total study population
use "$datafile/hypertension_allclasses_heatwave_intervals_all", clear

rename st_st obs_start
rename st_en obs_end

bysort patid: keep if _n==1

merge 1:m patid using "$datafile/diagnosis_inpatient.dta", keep(match) nogen
keep patid obs_start obs_end eventstart eventend
duplicates drop

drop if eventstart > eventend
drop if eventend < obs_start
drop if eventstart > obs_end
replace eventstart = obs_start if eventstart < obs_start
replace eventend = obs_end if eventend > obs_end

*Start the steps of handling overlapping by reshaping the data
keep patid eventstart eventend
sort patid eventstart eventend
by patid: gen episode=_n

rename eventstart timerxst
rename eventend timerxen

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

by patid (time start_end2), sort: gen gap_num = 1 if start_end == "rxst" & (time- time[_n-1]<=1)
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
rename rxst admission
rename rxen discharge

save "$datafile\hospitalisations.dta", replace

/*****************************************************************/
* 2. Recode in-patient stays during heatwave periods as baseline
/*****************************************************************/

use "$datafile/hypertension_allclasses_heatwave_intervals_all", clear

rename st_st obs_start
rename st_en obs_end

*combine with data on hospitalisation start and end dates
joinby patid using "$datafile\hospitalisations.dta", unmatched(master)

*drop unneccessary variables
keep patid obs_start obs_end interstart interend intertype unique_interval admission discharge

*drop baseline intervals
drop if intertype==0

*drop observations with hospitalisation data
drop if admission==.

*keep in patient periods overlapping with heatwave intervals
drop if admission > interend | discharge < interstart

*create new interval variables
gen new_intertype = intertype
gen new_interstart = interstart  
gen new_interend = interend
gen interval_change=.
gen in_patient=0
format new_interstart new_interend %td

*Case 1: hospitalization completely covers interval
replace interval_change=1 if admission<=interstart & discharge >=interend
replace new_intertype=0 if interval_change==1
replace in_patient=1 if interval_change==1

*Case 2: hospitalization starts within interval but extends beyond
replace interval_change=2 if interstart < admission & admission < interend

*Case 3: hospitalization starts before interval and ends during
replace interval_change=3 if admission <= interstart & discharge >= interstart & discharge < interend

*Case 4: hospitalization starts before interval and ends during
replace interval_change=4 if interstart < admission & discharge < interend

** Handle interval splitting

*Case 2 -> split into pre-hospitalisation interval + hospitalisation period
expand 2 if interval_change == 2
bysort patid unique_interval admission discharge: gen seq = _n if interval_change == 2
replace new_interstart = interstart if seq == 1
replace new_interend = admission - 1 if seq == 1
replace new_interstart = admission if seq == 2  
replace new_interend = interend if seq == 2
replace new_intertype = 0 if seq == 2
replace in_patient = 1 if seq == 2

*Case 3 -> split into hospitalisation period + post-hospitalisation interval
expand 2 if interval_change == 3
bysort patid unique_interval admission discharge: replace seq = _n if interval_change == 3 & seq == .
replace new_interstart = interstart if interval_change == 3 & seq == 1
replace new_interend = discharge if interval_change == 3 & seq == 1
replace new_intertype = 0 if interval_change == 3 & seq == 1
replace in_patient = 1 if interval_change == 3 & seq == 1
replace new_interstart = discharge + 1 if interval_change == 3 & seq == 2
replace new_interend = interend if interval_change == 3 & seq == 2

*Case 4 -> split into three intervals (pre + hospitalisation + post)
expand 3 if interval_change == 4
bysort patid unique_interval admission discharge: replace seq = _n if interval_change == 4 & seq == .
replace new_interstart = interstart if interval_change == 4 & seq == 1
replace new_interend = admission - 1 if interval_change == 4 & seq == 1
replace new_interstart = admission if interval_change == 4 & seq == 2
replace new_interend = discharge if interval_change == 4 & seq == 2  
replace new_intertype = 0 if interval_change == 4 & seq == 2
replace in_patient = 1 if interval_change == 4 & seq == 2
replace new_interstart = discharge + 1 if interval_change == 4 & seq == 3
replace new_interend = interend if interval_change == 4 & seq == 3

*only keep updated intervals
keep if interval_change!=.

*only keep neccessary variables
keep patid unique_interval interstart interend new_interstart new_interend new_intertype interval_change in_patient

*merge with original sccs intervals
merge m:1 unique_interval using "$datafile/hypertension_${drug}_heatwave_intervals_all", nogen

*integrate edited interval dates
replace interstart=new_interstart if new_interstart !=.
replace interend=new_interend if new_interend !=.
replace intertype=new_intertype if new_intertype !=.

*drop unncessary variables
drop new_interstart new_interend interval_change

*regenerate unique interval ids counting additional intervals
drop unique_interval
sort patid interstart
gen unique_interval = _n

/*****************************************************************/
* Create SCCS dataset
*****************************************************************/

di "Join with with $outcome events"
joinby patid using "$datafile\hypertension_${outcome}_multiple", unmatched(master)
drop icd10 day_diff cum_daydiff _merge

* Create outcome variable
replace eventstart = . if eventstart!=. & eventstart > obs_end
replace eventstart = . if eventstart!=. & eventstart < obs_start

gen outcome_ind = 1 if eventstart >= interstart & eventstart <= interend
replace outcome_ind = 0 if outcome_ind == .

* remove duplicates
gsort patid interstart interend -outcome_ind
bysort patid interstart interend: keep if _n == 1

* remove those who do not have an outcome during observation period
bysort patid: egen max_outcome = max(outcome_ind)
drop if max_outcome == 0
drop max_outcome

* Create variable for interval (offset)
gen interval = interend - interstart + 1
gen loginterval = log(interval)

* View number of event in each risk period
tab outcome_ind intertype,m

assert interstart <= obs_end
assert interend >= obs_start

cou if eventstart>obs_end & eventstart !=.
cou if eventstart<obs_start & eventstart !=.

drop unique_interval
gen unique_interval = _n

save "$datafile\sccs_sens_analysis_exclhosp_${drug}_${outcome}.dta", replace

/*****************************************************************
Set up excel
*****************************************************************/

putexcel set "$output/sccs_sens_analysis_exclhosp_${outcome}.xlsx", sheet("${drug}") modify

putexcel B1 = "With drug"
putexcel F1 = "Without drug"
putexcel B2 = "Events"
putexcel C2 = "Person years"
putexcel D2 = "IRR"
putexcel E2 = "95% CIs"
putexcel F2 = "Events"
putexcel G2 = "Person years"
putexcel H2 = "IRR"
putexcel I2 = "95% CIs"
putexcel J2 = "P-interaction"
putexcel A3 = "Baseline"
putexcel A4 = "Pre-heatwave"
putexcel A5 = "Heatwave"
putexcel A6 = "Post-heatwave"

/*****************************************************************
Fill in events and person years
*****************************************************************/

use "$datafile\sccs_sens_analysis_exclhosp_${drug}_${outcome}.dta", clear

********** With drug

* Baseline
preserve
keep if intertype==0 & drugexposed==1
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C3 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B3 = `events', nformat("#")
restore

* Pre-heatwave
preserve
keep if intertype==1 & drugexposed==1
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C4 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B4 = `events', nformat("#")
restore

* Heatwave
preserve
keep if intertype==2 & drugexposed==1
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C5 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B5 = `events', nformat("#")
restore

* Post-heatwave
preserve
keep if intertype==3 & drugexposed==1
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C6 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B6 = `events', nformat("#")
restore

********** Without drug

* Baseline
preserve
keep if intertype==0 & drugexposed==0
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel G3 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel F3 = `events', nformat("#")
restore

* Pre-heatwave
preserve
keep if intertype==1 & drugexposed==0
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel G4 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel F4 = `events', nformat("#")
restore

* Heatwave
preserve
keep if intertype==2 & drugexposed==0
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel G5 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel F5 = `events', nformat("#")
restore

* Post-heatwave
preserve
keep if intertype==3 & drugexposed==0
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel G6 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel F6 = `events', nformat("#")
restore

/*****************************************************************
Run SCCS using conditional Poisson regression
*****************************************************************/

use "$datafile\sccs_sens_analysis_exclhosp_${drug}_${outcome}.dta", clear
destring(patid), replace 

if "${drug}" == "C03" {	
local antihypadjust i.adjustantihyp_C08 i.adjustantihyp_C09
}

if "${drug}" == "C08" {	
local antihypadjust i.adjustantihyp_C03 i.adjustantihyp_C09
}

if "${drug}" == "C09" {	
local antihypadjust i.adjustantihyp_C03 i.adjustantihyp_C08
}

if "${drug}" == "allclasses" {	
}

*interaction
xi i.intertype*i.drugexposed i.season i.age_gp
xtpoisson outcome_ind _Iintertype_*  _Idrugexpos_* _IintXdru_* _Iseason_* _Iage_gp_* `antihypadjust', fe i(patid) offset(loginterval) irr
est store modA

di "With drug exposure in risk period of 1"
lincom _Iintertype_1 + _IintXdru_1_1, eform 
putexcel D4 = (string(r(estimate), "%9.2f"))
putexcel E4 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))

di "With drug exposure in risk period of 2"
lincom _Iintertype_2 + _IintXdru_2_1, eform 
putexcel D5 = (string(r(estimate), "%9.2f"))
putexcel E5 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

di "With drug exposure in risk period of 3"
lincom _Iintertype_3 + _IintXdru_3_1, eform 
putexcel D6 = (string(r(estimate), "%9.2f"))
putexcel E6 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f")) 

di "Without drug exposure in risk period of 1"
lincom _Iintertype_1, eform 
putexcel H4 = (string(r(estimate), "%9.2f"))
putexcel I4 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))

di "Without drug exposure in risk period of 2"
lincom _Iintertype_2, eform
putexcel H5 = (string(r(estimate), "%9.2f"))
putexcel I5 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

di "Without drug exposure in risk period of 3"
lincom _Iintertype_3, eform
putexcel H6 = (string(r(estimate), "%9.2f"))
putexcel I6 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f")) 

*no interaction
xtpoisson outcome_ind _Iintertype_*  _Idrugexpos_* _Iseason_* _Iage_gp_* `antihypadjust', fe i(patid) offset(loginterval) irr
est store modB

*interaction test
lrtest modA modB
putexcel J3 = (string(r(p), "%9.2f"))

log close
