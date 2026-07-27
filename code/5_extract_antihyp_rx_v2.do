/*=========================================================================
DO FILE NAME:			5_extract_antihyp_rx_v2

AUTHOR:					Mia Harley
VERSION:				v1			
DATABASE:				Japanese claims data

Aim: 					To extract all antihypertensive prescription records
*=============================================================================*/

* create new log
cap log close
log using "${logfiles}/5_extract_antihyp_rx.log", text replace

/******************************************************************
Diuretics (C03)
*****************************************************************/

use "$datafile/drug.dta", clear
keep if substr(who_atc, 1, 3) == "C03" | substr(who_atc, 1, 5) == "C09BA"  | substr(who_atc, 1, 5) == "C09DA"
duplicates drop

* EDIT: drop loop diuretics (short half-life)
drop if substr(who_atc, 1, 5) == "C03CA"

*inspect drug types
tab who_atc

*gen variable for drug type
gen drug_type=.
replace drug_type = 1 if substr(who_atc, 1, 5) == "C03AA"
replace drug_type = 2 if substr(who_atc, 1, 5) == "C03BA"
replace drug_type = 4 if substr(who_atc, 1, 5) == "C03DA"
replace drug_type = 5 if substr(who_atc, 1, 5) == "C03XA"
replace drug_type = 12 if substr(who_atc, 1, 5) == "C09DA"

*gen variable for drug name
drop drug_name
gen drug_name=""

replace drug_name="hydrochlorothiazide" if substr(who_atc, 1, 7) == "C03AA03"
replace drug_name="trichlormethiazide" if substr(who_atc, 1, 7) == "C03AA06"

replace drug_name="mefruside" if substr(who_atc, 1, 7) == "C03BA05"
replace drug_name="meticrane" if substr(who_atc, 1, 7) == "C03BA09"
replace drug_name="indapamide" if substr(who_atc, 1, 7) == "C03BA11"

replace drug_name="spironolactone" if substr(who_atc, 1, 7) == "C03DA01"
replace drug_name="potassium canrenoate" if substr(who_atc, 1, 7) == "C03DA02"
replace drug_name="eplerenone" if substr(who_atc, 1, 7) == "C03DA04"
replace drug_name="tolvaptan" if substr(who_atc, 1, 7) == "C03XA01"

replace drug_name="losartan + diuretic" if substr(who_atc,1,7)=="C09DA01"
replace drug_name="valsartan + diuretic" if substr(who_atc,1,7)=="C09DA03"
replace drug_name="irbesartan + diuretic" if substr(who_atc,1,7)=="C09DA04"
replace drug_name="candesartan + diuretic" if substr(who_atc,1,7)=="C09DA06"
replace drug_name="telmisartan + diuretic" if substr(who_atc,1,7)=="C09DA07"

*gen variable for drug class
gen drug_class=1

save "$datafile/antihyp_C03_rxall.dta", replace

/******************************************************************
Calcium channel blockers (C08)
*****************************************************************/

use "$datafile/drug.dta", clear
keep if substr(who_atc, 1, 3) == "C08" | substr(who_atc, 1, 5) == "C09BB" | substr(who_atc, 1, 5) == "C09DB"
duplicates drop

*inspect drug types
tab who_atc

*gen variable for drug type
gen drug_type=.
replace drug_type = 6 if substr(who_atc, 1, 5) == "C08CA"
replace drug_type = 7 if substr(who_atc, 1, 5) == "C08DA"
replace drug_type = 8 if substr(who_atc, 1, 5) == "C08DB"
replace drug_type = 9 if substr(who_atc, 1, 5) == "C08EA"
replace drug_type = 13 if substr(who_atc, 1, 5) == "C09DB"

*gen variable for drug name
drop drug_name
gen drug_name=""
replace drug_name="amlodipine" if substr(who_atc, 1, 7) == "C08CA01"
replace drug_name="felodipine" if substr(who_atc, 1, 7) == "C08CA02"
replace drug_name="nicardipine" if substr(who_atc, 1, 7) == "C08CA04"
replace drug_name="nifedipine" if substr(who_atc, 1, 7) == "C08CA05"
replace drug_name="nisoldipine" if substr(who_atc, 1, 7) == "C08CA07"
replace drug_name="nitrendipine" if substr(who_atc, 1, 7) == "C08CA08"
replace drug_name="nilvadipine" if substr(who_atc, 1, 7) == "C08CA10"
replace drug_name="manidipine" if substr(who_atc, 1, 7) == "C08CA11"
replace drug_name="barnidipine" if substr(who_atc, 1, 7) == "C08CA12"
replace drug_name="cilnidipine" if substr(who_atc, 1, 7) == "C08CA14"
replace drug_name="benidipine" if substr(who_atc, 1, 7) == "C08CA15"

replace drug_name="verapamil" if substr(who_atc, 1, 7) == "C08DA01"
replace drug_name="diltiazem" if substr(who_atc, 1, 7) == "C08DB01"
replace drug_name="bepridil" if substr(who_atc, 1, 7) == "C08EA02"

replace drug_name="valsartan + amlodipine" if substr(who_atc, 1, 7) == "C09DB01"
replace drug_name="telmisartan + amlodipine" if substr(who_atc, 1, 7) == "C09DB04"
replace drug_name="irbesartan + amlodipine" if substr(who_atc, 1, 7) == "C09DB05"
replace drug_name="candesartan + amlodipine" if substr(who_atc, 1, 7) == "C09DB07"

*gen variable for drug class
gen drug_class=2

save "$datafile/antihyp_C08_rxall.dta", replace

/******************************************************************
ARBs/ACEis (C09)
*****************************************************************/

use "$datafile/drug.dta", clear
keep if substr(who_atc, 1, 3) == "C09"
duplicates drop

*inspect drug types
tab who_atc

*gen variable for drug type
gen drug_type=.
replace drug_type = 10 if substr(who_atc, 1, 5) == "C09AA"
replace drug_type = 11 if substr(who_atc, 1, 5) == "C09CA"
replace drug_type = 12 if substr(who_atc, 1, 5) == "C09DA"
replace drug_type = 13 if substr(who_atc, 1, 5) == "C09DB"
replace drug_type = 14 if substr(who_atc, 1, 5) == "C09DX"
replace drug_type = 15 if substr(who_atc, 1, 5) == "C09XA"

*gen variable for drug name
drop drug_name
gen drug_name=""
replace drug_name="captopril" if substr(who_atc,1,7)=="C09AA01"
replace drug_name="enalapril" if substr(who_atc,1,7)=="C09AA02"
replace drug_name="lisinopril" if substr(who_atc,1,7)=="C09AA03"
replace drug_name="perindopril" if substr(who_atc,1,7)=="C09AA04"
replace drug_name="quinapril" if substr(who_atc,1,7)=="C09AA06"
replace drug_name="benazepril" if substr(who_atc,1,7)=="C09AA07"
replace drug_name="cilazapril" if substr(who_atc,1,7)=="C09AA08"
replace drug_name="trandolapril" if substr(who_atc,1,7)=="C09AA10"
replace drug_name="delapril" if substr(who_atc,1,7)=="C09AA12"
replace drug_name="temocapril" if substr(who_atc,1,7)=="C09AA14"
replace drug_name="imidapril" if substr(who_atc,1,7)=="C09AA16"

replace drug_name="losartan" if substr(who_atc,1,7)=="C09CA01"
replace drug_name="valsartan" if substr(who_atc,1,7)=="C09CA03"
replace drug_name="irbesartan" if substr(who_atc,1,7)=="C09CA04"
replace drug_name="candesartan" if substr(who_atc,1,7)=="C09CA06"
replace drug_name="telmisartan" if substr(who_atc,1,7)=="C09CA07"
replace drug_name="olmesartan medoxomil" if substr(who_atc,1,7)=="C09CA08"
replace drug_name="azilsartan medoxomil" if substr(who_atc,1,7)=="C09CA09"

replace drug_name="losartan + diuretic" if substr(who_atc,1,7)=="C09DA01"
replace drug_name="valsartan + diuretic" if substr(who_atc,1,7)=="C09DA03"
replace drug_name="irbesartan + diuretic" if substr(who_atc,1,7)=="C09DA04"
replace drug_name="candesartan + diuretic" if substr(who_atc,1,7)=="C09DA06"
replace drug_name="telmisartan + diuretic" if substr(who_atc,1,7)=="C09DA07"

replace drug_name="valsartan + amlodipine" if substr(who_atc,1,7)=="C09DB01"
replace drug_name="telmisartan + amlodipine" if substr(who_atc,1,7)=="C09DB04"
replace drug_name="irbesartan + amlodipine" if substr(who_atc,1,7)=="C09DB05"
replace drug_name="candesartan + amlodipine" if substr(who_atc,1,7)=="C09DB07"

replace drug_name="aliskiren" if substr(who_atc,1,7)=="C09XA02"

*gen variable for drug class
gen drug_class=3

save "$datafile/antihyp_C09_rxall.dta", replace


/******************************************************************
All classes
*****************************************************************/
* merge drug datasets
use  "$datafile/antihyp_C03_rxall.dta", clear
append using "$datafile/antihyp_C08_rxall.dta"
append using "$datafile/antihyp_C09_rxall.dta"

*label drug types
label define drug_type 1 "Low ceiling, thiazide" 2 "Low ceiling, sulfonamide" 3 "High ceiling, sulfonamide" 4 "Aldosterone antagonist" 5 "Vasopressin antagonist" 6 "Dihydropyridine" 7 "Phenylamine" 8 "Benzothiazepine" 9 "Phenylalkylamine" 10 "ACEi" 11 "ARB" 12 "ARB+diuretic" 13 "ARB+CCB" 14 "ARB+othercombinations" 15 "Renin inhibitors"
label values drug_type drug_type

*label drug classes
label define drug_class 1 "Diuretic" 2 "CCB" 3 "ACEi/ARB"
label values drug_class drug_class

codebook drug_type
codebook drug_class

assert drug_class !=.
assert drug_type !=.
assert drug_name !="" if (strlen(who_atc)==7)

save "$datafile/antihyp_allclasses_rxall.dta", replace

log close
