/*=========================================================================
DO FILE NAME:			9_sccs_prepare_dataset

AUTHOR:					Angel Wong, adapted by Mia Harley

VERSION:				v1
			
DATABASE:				Japanese claims data, Tsukuba City tempature data

DESCRIPTION OF FILE:	Creates main analysis dataset by merging heatwave intervals with outcome
*=========================================================================*/

* create new log
cap log close
log using "${logfiles}/9_sccs_prepare_dataset_${drug}_${outcome}", text replace

/*****************************************************************/
* 1. Create main analysis dataset
*****************************************************************/
use "$datafile/hypertension_${drug}_heatwave_intervals_all", clear

rename st_st obs_start
rename st_en obs_end

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

save "$datafile\\sccs_main_analysis_dataset_${drug}_${outcome}", replace

/*****************************************************************/
* 2. Patient list for each SCCS analysis
*****************************************************************/

use "$datafile\sccs_main_analysis_dataset_${drug}_${outcome}", clear

* Create variable for exposure status
bysort patid: egen maxexposed = max(drugexposed)
bysort patid: egen minexposed = min(drugexposed)
gen exposure = 0 if maxexposed==0
replace exposure = 1 if minexposed==0 & maxexposed==1
replace exposure = 2 if minexposed==1
duplicates drop patid, force

* Calculate age at start of observation period (as oppose to age at interval)
gen age_index = (obs_start-dob)/365.25
gen     cat_age=1 if age_index>=18 & age_index<40
replace cat_age=2 if age_index>=40 & age_index<50
replace cat_age=3 if age_index>=50 & age_index<60
replace cat_age=4 if age_index>=60 & age_index<70
replace cat_age=5 if age_index>=70 
cou if cat_age ==.

* Gen obs duration in years
gen obs_duration = (obs_end-obs_start)/365.25

keep patid obs_start obs_end obs_duration gender dob exposure cat_age age_index
save "$datafile\sccs_main_analysis_patientlist_${drug}_${outcome}", replace


log close