/*=========================================================================
DO FILE NAME:			1_import_clinical_data

AUTHOR:					Mia Harley
VERSION:				v1
DO-file required:		
					
DATABASE:				Japanese claims data

Aim: 					Process clinical data
*=============================================================================*/

* create new log
cap log close
log using "${logfiles}/1_import_clinical_data.log", text replace

/******************************************************************
Patient data
******************************************************************/
use "Z:\Mia\Original data\Denominator_in_Tsukuba_city.dta", clear

* Reformat and rename variables
tostring bid2022, gen(patid)
tostring Observation_start, gen(observation_start)
tostring Observation_end, gen(observation_end)
tostring BirthYearMonthDate, gen(dob)
rename Gender gender

* Format date of birth
gen dob_format = date(dob, "YMD")
format dob_format %td
drop dob
rename dob_format dob

* Set observation start date as end date of the month (2012, 2016, 2020 and 2024 are the leap year)
gen ob_start_year = substr(observation_start, 1, 4)
gen ob_start_month = substr(observation_start, 5, 6)

gen ob_start_day = 31 if ob_start_month == "01" | ///
 ob_start_month == "03" | ob_start_month == "05" | ob_start_month == "07" | ///
  ob_start_month == "08" | ob_start_month == "10" | ob_start_month == "12" 
  
replace ob_start_day = 30 if ob_start_month == "04" | ///
 ob_start_month == "06" | ob_start_month == "09" | ob_start_month == "11" 
 
replace ob_start_day = 28 if ob_start_month == "02"
 
replace ob_start_day = 29 if ob_start_month == "02" & ///
(ob_start_year == "2012" | ob_start_year == "2016" | ob_start_year == "2020" | ob_start_year == "2024")

destring ob_start_year, replace
destring ob_start_month, replace

gen regstart = mdy(ob_start_month,ob_start_day,ob_start_year)
format regstart %td

* Set observation end date as start date of the month
gen ob_end_year = substr(observation_end, 1, 4)
gen ob_end_month = substr(observation_end, 5, 6)

gen ob_end_day = 1 

destring ob_end_year, replace
destring ob_end_month, replace

gen regend = mdy(ob_end_month,ob_end_day,ob_end_year)
format regend %td

keep patid gender dob regstart regend
save "$datafile/patient.dta", replace

/******************************************************************
In-patient diagnoses
******************************************************************/
use "Z:\Mia\Original data\diagnosis_inpatient.dta", clear

* Reformat and rename variables
tostring bid2022, gen(patid)

* Format eventstart date
gen eventstart = date(date_admission, "YMD")
format eventstart %td

* Format eventend date
gen eventend = date(data_discharge, "YMD")
format eventend %td

keep patid icd10 eventstart eventend claim_id
order patid eventstart eventend icd10 claim_id
save "$datafile/diagnosis_inpatient.dta", replace

/******************************************************************
Out-patient diagnoses
******************************************************************/

use "Z:\Mia\Original data\diagnosis_outpatient.dta", clear

* Reformat and rename variables
tostring bid2022, gen(patid)

* Format eventstart date
tostring first_diagnosis_date, replace
gen eventstart = date(first_diagnosis_date, "YMD")
format eventstart %td

keep patid icd10 eventstart claim_id
order patid eventstart icd10 claim_id
save "$datafile/diagnosis_outpatient.dta", replace

/******************************************************************
All diagnoses
******************************************************************/

use "$datafile/diagnosis_inpatient.dta", clear
append using "$datafile/diagnosis_outpatient.dta"
replace eventend=eventstart if eventend==.
save "$datafile/diagnosis_all.dta", replace

/******************************************************************
Drug data
******************************************************************/

use "Z:\Mia\Original data\drug.dta", clear

* Reformat and rename variables
tostring bid2022, gen(patid)
rename whoatc_drug_code who_atc    
rename Japanese_drug_name drug_name 
rename amount_per_day daily_dose
rename number_of_days duration

* Format prescription date
tostring date_prescription, replace
gen prescription_date = date(date_prescription, "YMD")
format prescription_date %td

* Format dispensing date
tostring date_dispensation, replace
gen rxst = date(date_dispensation, "YMD")
gen rxen = rxst + duration - 1
format rxst rxen %td

keep patid who_atc prescription_date rxst rxen drug_name daily_dose duration total_amount  claim_id claim_type
order patid who_atc prescription_date rxst rxen drug_name daily_dose duration total_amount  claim_id claim_type
save "$datafile/drug.dta", replace

/******************************************************************
Annual health checkup
******************************************************************/

use "Z:\Mia\Original data\healthchekup_250616Yuta\healthcheckup.dta", clear
rename bid2022 patid
tostring patid, replace
tostring checkup_date, replace

gen check_up_year = substr(checkup_date, 1, 4)
gen check_up_month = substr(checkup_date, 5, 2)
gen check_up_date = substr(checkup_date, 7, 2)

destring check_up_year, replace
destring check_up_month, replace
destring check_up_date, replace

gen checkup_date1 = mdy(check_up_month, check_up_date, check_up_year)
format checkup_date1 %td

drop check_up_year check_up_month check_up_date checkup_date
rename checkup_date1 checkup_date

save "$datafile/annual_health_checkup.dta", replace

log close