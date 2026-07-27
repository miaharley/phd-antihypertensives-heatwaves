/*=========================================================================
DO FILE NAME:			19_sccs_sens_analysis_nointeraction

AUTHOR:					Mia Harley

VERSION:				v1	
					
DATABASE:				Japanese claims data

DESCRIPTION OF FILE:	1. Runs SCCS for heatwaves and risk of heat illness in total study population, with no drug intreaction
						2. Run SCCS for heatwaves and risk of heat illness stratified by sex
*=========================================================================*/

* create new log
cap log close
log using "${logfiles}/19_sccs_sens_analysis_nointeraction_${outcome}", text replace


/*****************************************************************
* 1. Heatwave intervals for all hypertension patients regardless of drug exposure
*****************************************************************/	

* People with hypertension who experienced heatwave regardless of antihypertensive
use "$datafile/hypertension_heatwave.dta", clear

rename obs_start st_st
rename obs_end st_en

keep patid dob exp_st exp_en st_st st_en 

sort patid exp_st exp_en
format st_st %td
bysort patid (exp_st): gen nextfirstrx = exp_st[_n+1] 
bysort patid (exp_st): gen prevepiend = exp_en[_n-1] if _n != 1
format nextfirstrx prevepiend %td

* Create interval for pre-exposure period, for each risk period, and for end of risk periods
expand (2 + 2)
bysort patid exp_st: gen intertype = _n - 1
*label values intertype intertype_lbl

* Create interval dates for pre-exposure period
gen interstart = exp_st - 5 if intertype == 1 //change 5 as length of pre-exposure period
gen interend = exp_st - 1 if intertype == 1

format interstart interend %td

* Create interval dates for current exposure period
replace interstart = exp_st if intertype == 2
replace interend = exp_en if intertype == 2

* Create interval date for post exposure period
replace interstart = exp_en + 1 if intertype == 3
replace interend = exp_en + 5 if intertype == 3 //change 5 as length of post-exposure period

* Create interval dates for non-risk period
bysort patid: gen lastpostinterval = interend[_n-1]
bysort patid: gen nextpreinterval = interstart[_n+1]
format lastpostinterval nextpreinterval %td
replace interstart = lastpostinterval + 1 if intertype == 0 & lastpostinterval!=.
replace interend = nextpreinterval - 1 if intertype == 0 & lastpostinterval!=.

* Create first non-risk period from study start
preserve
keep if intertype == 0 & lastpostinterval==.
tempfile lastnonriskperiod
save `lastnonriskperiod'
restore

replace interstart = st_st if intertype == 0 & lastpostinterval==.
replace interend = nextpreinterval - 1 if intertype == 0 & lastpostinterval==.
drop if interstart> interend & intertype == 0 

append using `lastnonriskperiod'

* Create last non-risk period until study end
sort patid interstart
drop lastpostinterval nextpreinterval
replace interstart = interend[_n-1] + 1 if intertype == 0 & interstart ==.
replace interend = st_en if intertype == 0 & interend ==.

* Drop intervals that are not valid
drop if interstart > interend
drop if interend < st_st
replace interend = st_en if interend > st_en
replace interstart = st_st if interstart <st_st
drop if interstart > interend
drop if interend < st_st

assert interstart <= st_en 
assert interend >= st_st

* Handle pre-risk periods when they overlap with last post-risk period
* In favor of keeping post-risk period than pre-risk period
* Sort by interstart interned initially
sort patid interstart interend
bysort patid: gen lastpost_st = interstart[_n-1]
bysort patid: gen lastpost_en = interend[_n-1]
format lastpost_st lastpost_en %td

* Remove pre-risk period if it completely overlap with last post-risk period
drop if intertype == 1 & interstart < = lastpost_st & lastpost_st!=.

* Edit the pre-risk period if it partially overlap with last post-risk period
replace interstart = lastpost_en + 1 if intertype == 1 &  lastpost_st < = interstart & interstart < = lastpost_en & lastpost_en!=.

drop if interstart > interend & intertype == 1

drop lastpost_st lastpost_en

* Resort the dataset as some pre-risk period end date occur before the end date of last post-risk period
* Then repeat the same procedures as above
gsort patid interstart -interend
bysort patid: gen lastpost_st = interstart[_n-1]
bysort patid: gen lastpost_en = interend[_n-1]
format lastpost_st lastpost_en %td

drop if intertype == 1 & interstart < = lastpost_st & lastpost_st!=. 
replace interstart = lastpost_en + 1 if intertype == 1 &  lastpost_st < = interstart & interstart < = lastpost_en & lastpost_en!=.

drop if interstart > interend & intertype == 1

drop lastpost_st lastpost_en

* Edit the last post-risk period after cleaning the pre-risk period as above
sort patid interstart interend
bysort patid: gen nextpost_st = interstart[_n+1]
bysort patid: gen nextpost_en = interend[_n+1]

format nextpost_st nextpost_en %td

replace interend = nextpost_st - 1

drop nextpost_st nextpost_en

* Handle pre-risk periods when they overlap with last exposure risk period
* In favor of keeping exposure risk period than pre-risk period
sort patid interstart interend
bysort patid: gen lastpost_st = interstart[_n-1]
bysort patid: gen lastpost_en = interend[_n-1]
format lastpost_st lastpost_en %td

* Remove pre-risk period if it completely overlap with last exposure period
drop if intertype == 1 & interstart < = lastpost_st  & lastpost_st!=.

* Edit the pre-risk period if it partially overlap with last exposure period
replace interstart = lastpost_en + 1 if intertype == 1 &  lastpost_st < = interstart & interstart < = lastpost_en  & lastpost_en!=.

drop if interstart > interend & intertype == 1

drop lastpost_st lastpost_en

* Resort the dataset as some pre-risk period end date occur before the end date of last post-risk period
* Then repeat the same procedures as above
gsort patid interstart -interend
bysort patid: gen lastpost_st = interstart[_n-1]
bysort patid: gen lastpost_en = interend[_n-1]
format lastpost_st lastpost_en %td

drop if intertype == 1 & interstart < = lastpost_st & lastpost_st!=.
replace interstart = lastpost_en + 1 if intertype == 1 &  lastpost_st < = interstart & interstart < = lastpost_en & lastpost_en!=.

drop if interstart > interend & intertype == 1

drop lastpost_st lastpost_en

* Edit the last post-risk period after cleaning the pre-risk period as above
sort patid interstart interend
bysort patid: gen nextpost_st = interstart[_n+1]
bysort patid: gen nextpost_en = interend[_n+1]

format nextpost_st nextpost_en %td

replace interend = nextpost_st - 1

drop nextpost_st nextpost_en

* Edit the last non-risk window for the end date
replace interend = st_en if interend == . & intertype == 0

* Edit the first start date of episode for each person as st_st and the last end date of episode as st_en
bysort patid: gen indiv_order = _n
bysort patid: gen total_episode = _N
replace interstart = st_st if indiv_order == 1
bysort patid: replace interend = st_en if _n == _N

* Validity checks
assert interstart <= interend
bysort patid exp_st interstart: assert _n == 1
assert interstart == floor(interstart)

sort patid interstart interend
bysort patid: gen nextpost_st = interstart[_n+1]
format nextpost_st %td

assert interend + 1 == nextpost_st if nextpost_st != .

sort patid interstart interend
bysort patid: gen lastpost_en = interend[_n-1]
format lastpost_en %td

assert lastpost_en + 1 == interstart if lastpost_en != .

* Save relevant data
keep patid intertype st_st st_en interstart interend dob
order patid dob st_st st_en intertype interstart interend
save "$datafile/temp_exposure_intervals.dta", replace

/*****************************************************************
* 2. Create season intervals
*****************************************************************/
use "$datafile/temp_exposure_intervals.dta", clear

* Divide the intervals by season
* Handle overlapping period between date of season and intervals
forval year =  $studystartyear/$studyendyear {
gen winter_`year'=mdy(12,01,`year')
gen spring_`year'=mdy(03,01,`year')
gen summer_`year'=mdy(06,01,`year')
gen autumn_`year'=mdy(09,01,`year')
format winter_`year' spring_`year' summer_`year' autumn_`year' %td
}

gen keepflag = .
forval year = $studystartyear/$studyendyear {
	foreach season in spring summer autumn winter {
replace keepflag = 1 if (interstart<=`season'_`year' & `season'_`year'<interend)
	}
}

preserve
keep if keepflag == 1
drop keepflag
save "$datafile/period_overlap.dta", replace
restore

keep if keepflag == .
drop keepflag
save "$datafile/period_nonoverlap.dta", replace

use "$datafile/period_overlap.dta", clear

forval year =  $studystartyear/$studyendyear {
	foreach season in spring summer autumn winter {

preserve
replace interend=`season'_`year' - 1 if interstart<=`season'_`year' & `season'_`year'<interend
save "$datafile/`season'_`year'_partI.dta", replace
restore

replace interstart=`season'_`year' if interstart<=`season'_`year' & `season'_`year'<interend

append using "$datafile/`season'_`year'_partI.dta"

bysort patid interstart interend: keep if _n == 1
}
}

* Add non-overlap period
append using "$datafile/period_nonoverlap.dta"

* Remove unnecessary files
forval year = $studystartyear/$studyendyear {
	foreach season in spring summer autumn winter {
		erase "$datafile/`season'_`year'_partI.dta"
	}
}

* Validity checks
replace interstart = st_st if interstart < st_st & interend >= st_st
drop if interstart > st_en | interend < st_st
replace interend = st_en if interend > st_en & interstart <= st_en
drop if interend < interstart 
 
drop winter* summer* autumn* spring*

sort patid interstart interend

bysort patid interstart: assert _n == 1
assert interstart == floor(interstart)

sort patid interstart interend
bysort patid: gen nextpost_st = interstart[_n+1]
format nextpost_st %td

assert interend + 1 == nextpost_st if nextpost_st != .

sort patid interstart interend
bysort patid: gen lastpost_en = interend[_n-1]
format lastpost_en %td

assert lastpost_en + 1 == interstart if lastpost_en != .

drop nextpost_st lastpost_en

* Create month variable
gen month = 1 if month(interstart) == 1
replace month = 2 if month(interstart) == 2
replace month = 3 if month(interstart) == 3
replace month = 4 if month(interstart) == 4
replace month = 5 if month(interstart) == 5
replace month = 6 if month(interstart) == 6
replace month = 7 if month(interstart) == 7
replace month = 8 if month(interstart) == 8
replace month = 9 if month(interstart) == 9
replace month = 10 if month(interstart) == 10
replace month = 11 if month(interstart) == 11
replace month = 12 if month(interstart) == 12

* Create season variable
gen season = 1 if month(interstart) == 12 | ///
					month(interstart) == 1 | ///
					month(interstart) == 2
replace season = 2 if month(interstart) == 3 | ///
					month(interstart) == 4 | ///
					month(interstart) == 5
replace season = 3 if month(interstart) == 6 | ///
					month(interstart) == 7 | ///
					month(interstart) == 8
replace season = 4 if month(interstart) == 9 | ///
					month(interstart) == 10 | ///
					month(interstart) == 11

label variable season "Season category"
label define seasonlbl 1 "Winter" 2 "Spring" 3 "Summer" 4 "Autumn"
label values season seasonlbl

keep patid intertype st_st st_en interstart interend dob season month
order patid dob st_st st_en intertype interstart interend season month

save "$datafile/temp_season_intervals.dta", replace

/*****************************************************************
* 3. Create age categorical intervals (5 years age band)
*****************************************************************/

* Divide the intervals by age in 5 year band
* Handle overlapping period between date of current age and intervals

gen birth_month = month(dob)
gen birth_day = day(dob)

forval i = $studystartyear/$studyendyear {
gen birthyear`i'=mdy(birth_month,birth_day,`i')
format birthyear`i' %td
}

* Create age variable
gen age = year(interstart) - year(dob)
assert age != .

su age, detail //max: 102 years

gen keepflag = .
forval year =  $studystartyear/$studyendyear {
replace keepflag = 1 if (interstart<=birthyear`year' & birthyear`year'<interend) ///
 & (age == 22 | age == 27 | age == 32 | age == 37 | age == 42 | age == 47 ///
 | age == 52 | age == 57 | age == 62 | age == 67 | age == 72 | age == 77 ///
 | age == 82 | age == 87 | age == 92 | age == 110)
	}

preserve
keep if keepflag == 1
drop keepflag
save "$datafile/period_overlap.dta", replace
restore

keep if keepflag == .
drop keepflag
save "$datafile/period_nonoverlap.dta", replace

use "$datafile/period_overlap.dta", clear

forval year =  $studystartyear/$studyendyear {
preserve
replace interend=birthyear`year' - 1 if interstart<=birthyear`year' & ///
birthyear`year'<interend
save "$datafile/birthyear`year'_partI.dta", replace
restore

replace interstart=birthyear`year' if interstart<=birthyear`year' & birthyear`year'<interend

append using "$datafile/birthyear`year'_partI.dta"

bysort patid interstart interend: keep if _n == 1
}

* Add non-overlap period
append using "$datafile/period_nonoverlap.dta"

* Remove unnecessary files
forval year =  $studystartyear/$studyendyear {
		erase "$datafile/birthyear`year'_partI.dta"
	}

* Validity checks
replace interstart = st_st if interstart < st_st & interend >= st_st
drop if interstart > st_en | interend < st_st
replace interend = st_en if interend > st_en & interstart <= st_en
drop if interend < interstart 
 
drop birthyear*

sort patid interstart interend

bysort patid interstart: assert _n == 1
assert interstart == floor(interstart)

sort patid interstart interend
bysort patid: gen nextpost_st = interstart[_n+1]
format nextpost_st %td

assert interend + 1 == nextpost_st if nextpost_st != .

drop nextpost_st

sort patid interstart interend
bysort patid: gen lastpost_en = interend[_n-1]
format lastpost_en %td

assert lastpost_en + 1 == interstart if lastpost_en != .

* Create new age variable
gen newage = year(interstart) - year(dob)
assert newage != .

* Create age variable for 5 years band
gen age_gp = 1 if 18 <= newage & newage <= 22
replace age_gp = 2 if 23 <= newage & newage <= 27
replace age_gp = 3 if 28 <= newage & newage <= 32
replace age_gp = 4 if 33 <= newage & newage <= 37
replace age_gp = 5 if 38 <= newage & newage <= 42
replace age_gp = 6 if 43 <= newage & newage <= 47
replace age_gp = 7 if 48 <= newage & newage <= 52
replace age_gp = 8 if 53 <= newage & newage <= 57
replace age_gp = 9 if 58 <= newage & newage <= 62
replace age_gp = 10 if 63 <= newage & newage <= 67
replace age_gp = 11 if 68 <= newage & newage <= 72
replace age_gp = 12 if 73 <= newage & newage <= 77
replace age_gp = 13 if 78 <= newage & newage <= 82
replace age_gp = 14 if 83 <= newage & newage <= 87
replace age_gp = 15 if 88 <= newage & newage <= 92
replace age_gp = 16 if 93 <= newage & newage <= 110
assert age_gp != .



keep patid intertype st_st st_en interstart interend dob season month age_gp
order patid dob st_st st_en intertype interstart interend season month age_gp


save "$datafile/sens_analysis_hypertension_heatwave_intervals", replace

erase "$datafile/temp_exposure_intervals.dta"
erase "$datafile/temp_season_intervals.dta"

/*****************************************************************/
* 4. Create SCCS dataset
*****************************************************************/

use "$datafile\sccs_main_analysis_patientlist_totalstudypop", clear
drop obs_start obs_end 

merge 1:m patid using "$datafile/sens_analysis_hypertension_heatwave_intervals", keep(match) nogen

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

save "$datafile\sccs_sens_analysis_nointeraction_${outcome}.dta", replace

/*****************************************************************
SCCS using conditional Poisson regression - no drug interaction
*****************************************************************/

use "$datafile\sccs_sens_analysis_nointeraction_${outcome}.dta", clear
destring(patid), replace 

putexcel set "$output/sens_analysis_nointeraction_${outcome}.xlsx", sheet("overall") modify

putexcel B1 = "Regardless of drug use"
putexcel B2 = "Events"
putexcel C2 = "Person years"
putexcel D2 = "IRR"
putexcel E2 = "95% CIs"
putexcel A3 = "Baseline"
putexcel A4 = "Pre-heatwave"
putexcel A5 = "Heatwave"
putexcel A6 = "Post-heatwave"

* Baseline
preserve
keep if intertype==0
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C3 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B3 = `events', nformat("#")
restore

* Pre-heatwave
preserve
keep if intertype==1
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C4 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B4 = `events', nformat("#")
restore

* Heatwave
preserve
keep if intertype==2
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C5 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B5 = `events', nformat("#")
restore

* Post-heatwave
preserve
keep if intertype==3
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C6 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B6 = `events', nformat("#")
restore

*without interaction
xi i.intertype i.season i.age_gp
xtpoisson outcome_ind _Iintertype_* _Iseason_* _Iage_gp_*, fe i(patid) offset(loginterval) irr

di "Pre-heatwave"
lincom _Iintertype_1, eform 
putexcel D4 = (string(r(estimate), "%9.2f"))
putexcel E4 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))

di "Heatwave"
lincom _Iintertype_2, eform 
putexcel D5 = (string(r(estimate), "%9.2f"))
putexcel E5 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

di "Post-heatwave"
lincom _Iintertype_3, eform 
putexcel D6 = (string(r(estimate), "%9.2f"))
putexcel E6 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f")) 

/*****************************************************************
Run SCCS using conditional Poisson regression interaction for sex
*****************************************************************/

use "$datafile\sccs_sens_analysis_nointeraction_${outcome}.dta", clear
destring(patid), replace 

putexcel set "$output/sens_analysis_nointeraction_${outcome}.xlsx", sheet("sex_strat") modify

putexcel B1 = "Females"
putexcel F1 = "Males"
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


********** Females

* Baseline
preserve
keep if intertype==0 & gender==2
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C3 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B3 = `events', nformat("#")
restore

* Pre-heatwave
preserve
keep if intertype==1 & gender==2
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C4 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B4 = `events', nformat("#")
restore

* Heatwave
preserve
keep if intertype==2 & gender==2
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C5 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B5 = `events', nformat("#")
restore

* Post-heatwave
preserve
keep if intertype==3 & gender==2
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C6 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B6 = `events', nformat("#")
restore

********** Males

* Baseline
preserve
keep if intertype==0 & gender==1
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel G3 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel F3 = `events', nformat("#")
restore

* Pre-heatwave
preserve
keep if intertype==1 & gender==1
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel G4 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel F4 = `events', nformat("#")
restore

* Heatwave
preserve
keep if intertype==2 & gender==1
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel G5 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel F5 = `events', nformat("#")
restore

* Post-heatwave
preserve
keep if intertype==3 & gender==1
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel G6 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel F6 = `events', nformat("#")
restore

*interaction with sex
xi i.intertype*i.gender i.season i.age_gp
xtpoisson outcome_ind _Iintertype_*  _Igender_* _IintXgen_* _Iseason_* _Iage_gp_* , fe i(patid) offset(loginterval) irr
est store modA

di "Female risk period 1"
lincom _Iintertype_1 + _IintXgen_1_2, eform 
putexcel D4 = (string(r(estimate), "%9.2f"))
putexcel E4 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))

di "Female risk period 2"
lincom _Iintertype_2 + _IintXgen_2_2, eform 
putexcel D5 = (string(r(estimate), "%9.2f"))
putexcel E5 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

di "Female risk period of 3"
lincom _Iintertype_3 + _IintXgen_3_2, eform 
putexcel D6 = (string(r(estimate), "%9.2f"))
putexcel E6 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f")) 

di "Male risk period of 1"
lincom _Iintertype_1, eform 
putexcel H4 = (string(r(estimate), "%9.2f"))
putexcel I4 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))

di "Male risk period of 2"
lincom _Iintertype_2, eform
putexcel H5 = (string(r(estimate), "%9.2f"))
putexcel I5 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

di "Male risk period of 3"
lincom _Iintertype_3, eform
putexcel H6 = (string(r(estimate), "%9.2f"))
putexcel I6 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f")) 

*no interaction
xtpoisson outcome_ind _Iintertype_*  _Igender_* _Iseason_* _Iage_gp_* , fe i(patid) offset(loginterval) irr
est store modB

*interaction test
lrtest modA modB
putexcel J3 = (string(r(p), "%9.2f"))

/*****************************************************************
Run SCCS using conditional Poisson regression interaction for age
*****************************************************************/

use "$datafile\sccs_sens_analysis_nointeraction_${outcome}.dta", clear
destring(patid), replace 

putexcel set "$output/sens_analysis_nointeraction_${outcome}.xlsx", sheet("age_strat") modify

putexcel B1 = "18-39"
putexcel D1 = "40-49"
putexcel F1 = "50-59"
putexcel H1 = "60-69"
putexcel J1 = "≥70"

putexcel B2 = "IRR"
putexcel C2 = "95% CIs"
putexcel D2 = "IRR"
putexcel E2 = "95% CIs"
putexcel F2 = "IRR"
putexcel G2 = "95% CIs"
putexcel H2 = "IRR"
putexcel I2 = "95% CIs"
putexcel J2 = "IRR"
putexcel K2 = "95% CIs"
putexcel L2 = "P-interaction"

putexcel A3 = "Baseline"
putexcel A4 = "Pre-heatwave"
putexcel A5 = "Heatwave"
putexcel A6 = "Post-heatwave"


* 18-39
preserve
keep if intertype==0 & cat_ag==1
bysort patid: keep if _n==1
count
local sample = `r(N)'
putexcel C1 = `sample', nformat("#")
restore

* 40-49
preserve
keep if intertype==0 & cat_ag==2
bysort patid: keep if _n==1
count
local sample = `r(N)'
putexcel E1 = `sample', nformat("#")
restore

* 50-59
preserve
keep if intertype==0 & cat_ag==3
bysort patid: keep if _n==1
count
local sample = `r(N)'
putexcel G1 = `sample', nformat("#")
restore

* 60-69
preserve
keep if intertype==0 & cat_ag==4
bysort patid: keep if _n==1
count
local sample = `r(N)'
putexcel I1 = `sample', nformat("#")
restore

* ≥70
preserve
keep if intertype==0 & cat_ag==5
bysort patid: keep if _n==1
count
local sample = `r(N)'
putexcel K1 = `sample', nformat("#")
restore

*interaction with sex
xi i.intertype*i.cat_age i.season i.age_gp
xtpoisson outcome_ind _Iintertype_* _IintXcat_* _Iseason_* _Iage_gp_* , fe i(patid) offset(loginterval) irr
est store modA

di "18-39 risk period of 1"
lincom _Iintertype_1, eform 
putexcel B4 = (string(r(estimate), "%9.2f"))
putexcel C4 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))

di "18-39 risk period of 2"
lincom _Iintertype_2, eform
putexcel B5 = (string(r(estimate), "%9.2f"))
putexcel C5 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

di "18-39 risk period of 3"
lincom _Iintertype_3, eform
putexcel B6 = (string(r(estimate), "%9.2f"))
putexcel C6 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f")) 

di "40-49 period 1"
lincom _Iintertype_1 + _IintXcat_1_2, eform 
putexcel D4 = (string(r(estimate), "%9.2f"))
putexcel E4 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))

di "40-49 period 2"
lincom _Iintertype_2 + _IintXcat_2_2, eform 
putexcel D5 = (string(r(estimate), "%9.2f"))
putexcel E5 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

di "40-49 period of 3"
lincom _Iintertype_3 + _IintXcat_3_2, eform 
putexcel D6 = (string(r(estimate), "%9.2f"))
putexcel E6 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))

di "50-59 period 1"
lincom _Iintertype_1 + _IintXcat_1_3, eform 
putexcel F4 = (string(r(estimate), "%9.2f"))
putexcel G4 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))

di "50-59 period 2"
lincom _Iintertype_2 + _IintXcat_2_3, eform 
putexcel F5 = (string(r(estimate), "%9.2f"))
putexcel G5 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

di "50-59 period of 3"
lincom _Iintertype_3 + _IintXcat_3_3, eform 
putexcel F6 = (string(r(estimate), "%9.2f"))
putexcel G6 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

di "60-69 period 1"
lincom _Iintertype_1 + _IintXcat_1_4, eform 
putexcel H4 = (string(r(estimate), "%9.2f"))
putexcel I4 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))

di "60-69 period 2"
lincom _Iintertype_2 + _IintXcat_2_4, eform 
putexcel H5 = (string(r(estimate), "%9.2f"))
putexcel I5 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

di "60-69 period of 3"
lincom _Iintertype_3 + _IintXcat_3_4, eform 
putexcel H6 = (string(r(estimate), "%9.2f"))
putexcel I6 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

di "≥70 period 1"
lincom _Iintertype_1 + _IintXcat_1_4, eform 
putexcel J4 = (string(r(estimate), "%9.2f"))
putexcel K4 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))

di "≥70 period 2"
lincom _Iintertype_2 + _IintXcat_2_4, eform 
putexcel J5 = (string(r(estimate), "%9.2f"))
putexcel K5 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

di "≥70 period of 3"
lincom _Iintertype_3 + _IintXcat_3_4, eform 
putexcel J6 = (string(r(estimate), "%9.2f"))
putexcel K6 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

*no interaction
xtpoisson outcome_ind _Iintertype_*  _Icat_age_* _Iseason_* _Iage_gp_* , fe i(patid) offset(loginterval) irr
est store modB

*interaction test
lrtest modA modB
putexcel L3 = (string(r(p), "%9.2f"))

log close