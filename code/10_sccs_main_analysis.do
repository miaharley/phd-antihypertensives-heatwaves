/*=========================================================================
DO FILE NAME:			11_sccs_main_analysis

AUTHOR:					Angel Wong, adapted by Mia Harley

VERSION:				v1
			
DATABASE:				Japanese claims data, Tsukuba City tempature data

DESCRIPTION OF FILE:	SCCS main analysis interaction between antihyp and heatwave on heat illness, without adjusting/stratifying by class of antihyp
*=========================================================================*/

* create new log
cap log close
log using "${logfiles}/11_sccs_main_analysis_${drug}_${outcome}", text replace


/*****************************************************************
Set up excel
*****************************************************************/

putexcel set "$output/sccs_main_analysis_${outcome}.xlsx", sheet("${drug}") modify

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

use "$datafile\\sccs_main_analysis_dataset_${drug}_${outcome}", clear

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

use "$datafile\\sccs_main_analysis_dataset_${drug}_${outcome}", clear
destring(patid), replace 

*interaction
xi i.intertype*i.drugexposed i.season i.age_gp
xtpoisson outcome_ind _Iintertype_*  _Idrugexpos_* _IintXdru_* _Iseason_* _Iage_gp_* , fe i(patid) offset(loginterval) irr
est store modA

di "With drug exposure in risk period 1"
lincom _Iintertype_1 + _IintXdru_1_1, eform 
putexcel D4 = (string(r(estimate), "%9.2f"))
putexcel E4 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))

di "With drug exposure in risk period 2"
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
xtpoisson outcome_ind _Iintertype_*  _Idrugexpos_* _Iseason_* _Iage_gp_* , fe i(patid) offset(loginterval) irr
est store modB

*interaction test
lrtest modA modB
putexcel J3 = (string(r(p), "%9.2f"))
