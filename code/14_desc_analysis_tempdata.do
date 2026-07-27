/*=========================================================================
DO FILE NAME:			15_desc_analysis_tempdata

AUTHOR:					Mia Harley

VERSION:				v1	
					
DATABASE:				Temperature data Tsukuba City

DESCRIPTION OF FILE:	Descriptive analysis of tempature data in Tsukuba City
*=========================================================================*/

* create new log
cap log close
log using "${logfiles}/15_desc_analysis_tempdata.log", text replace

/*****************************************************************
Monthly temp data
*****************************************************************/

putexcel set "$output/desc_analysis_tempdata.xlsx", sheet("monthly_temp") modify

putexcel B1 = "2014"
putexcel C1 = "2015"
putexcel D1 = "2016"
putexcel E1 = "2017"
putexcel F1 = "2018"
putexcel G1 = "2019"
putexcel H1 = "2014-2019"

putexcel A2 = "January"
putexcel A3 = "February"
putexcel A4 = "March"
putexcel A5 = "April"
putexcel A6 = "May"
putexcel A7 = "June"
putexcel A8 = "July"
putexcel A9 = "August"
putexcel A10 = "September"
putexcel A11 = "October"
putexcel A12 = "November"
putexcel A13 = "December"

local 2014 B
local 2015 C
local 2016 D
local 2017 E
local 2018 F
local 2019 G

foreach year of numlist 2014/2019 {
foreach month of numlist 1/12{
use "$datafile\tsukuba_temp_data.dta", clear
keep if month==`month' & year==`year'
summarize mean_temp, detail
local median = r(p50)
local p25 = r(p25)
local p75 = r(p75)
local median_iqr = string(`median', "%9.1f") + " (" + string(`p25', "%9.1f") + " - " + string(`p75', "%9.1f") + ")"
local row = `month' + 1
putexcel ``year''`row' = "`median_iqr'"
}
}

foreach month of numlist 1/12{
use "$datafile\tsukuba_temp_data.dta", clear
keep if month==`month'
summarize mean_temp, detail
local median = r(p50)
local p25 = r(p25)
local p75 = r(p75)
local median_iqr = string(`median', "%9.1f") + " (" + string(`p25', "%9.1f") + " - " + string(`p75', "%9.1f") + ")"
local row = `month' + 1
putexcel H`row' = "`median_iqr'"
}

/*****************************************************************
Heatwave temp data
*****************************************************************/

putexcel set "$output/desc_analysis_tempdata.xlsx", sheet("heatwave_temp") modify

putexcel B1 = "2014"
putexcel C1 = "2015"
putexcel D1 = "2016"
putexcel E1 = "2017"
putexcel F1 = "2018"
putexcel G1 = "2019"
putexcel H1 = "2014-2019"

putexcel A2 = "Pre-heatwave"
putexcel A3 = "Min, Max"
putexcel A4 = "Median (IQR)"

putexcel A5 = "Heatwave"
putexcel A6 = "Min, Max"
putexcel A7 = "Median (IQR)"

putexcel A8 = "Post-heatwave"
putexcel A9 = "Min, Max"
putexcel A10 = "Median (IQR)"

local 2014 B
local 2015 C
local 2016 D
local 2017 E
local 2018 F
local 2019 G

*pre-heatwave
foreach year of numlist 2014/2019 {
use "$datafile\MEANT_heatwave_tsukuba_date", clear
gen pre_hw_start = hw_start - 5
gen pre_hw_end = hw_start - 1
drop hw_start hw_end
gen year= year(pre_hw_start)
keep if year==`year'
joinby year using "$datafile\tsukuba_temp_data.dta"
keep if date >= pre_hw_start & date <= pre_hw_end
summarize min_temp
local min = r(min)
summarize max_temp
local max = r(max)
local min_max = string(`min', "%9.1f") + ", " + string(`max', "%9.1f")
putexcel ``year''3 = "`min_max'"
summarize mean_temp, detail
local median = r(p50)
local p25 = r(p25)
local p75 = r(p75)
local median_iqr = string(`median', "%9.1f") + " (" + string(`p25', "%9.1f") + " - " + string(`p75', "%9.1f") + ")"
putexcel ``year''4 = "`median_iqr'"
}

*heatwave
foreach year of numlist 2014/2019 {
use "$datafile\MEANT_heatwave_tsukuba_date", clear
gen year= year(hw_start)
keep if year==`year'
joinby year using "$datafile\tsukuba_temp_data.dta"
keep if date >= hw_start & date <= hw_end
summarize min_temp
local min = r(min)
summarize max_temp
local max = r(max)
local min_max = string(`min', "%9.1f") + ", " + string(`max', "%9.1f")
putexcel ``year''6 = "`min_max'"
summarize mean_temp, detail
local median = r(p50)
local p25 = r(p25)
local p75 = r(p75)
local median_iqr = string(`median', "%9.1f") + " (" + string(`p25', "%9.1f") + " - " + string(`p75', "%9.1f") + ")"
putexcel ``year''7 = "`median_iqr'"
}

*post-heatwave
foreach year of numlist 2014/2019 {
use "$datafile\MEANT_heatwave_tsukuba_date", clear
gen post_hw_start = hw_end + 1
gen post_hw_end = hw_end + 5
drop hw_start hw_end
gen year= year(post_hw_start)
keep if year==`year'
joinby year using "$datafile\tsukuba_temp_data.dta"
keep if date >= post_hw_start & date <= post_hw_end
summarize min_temp
local min = r(min)
summarize max_temp
local max = r(max)
local min_max = string(`min', "%9.1f") + ", " + string(`max', "%9.1f")
putexcel ``year''9 = "`min_max'"
summarize mean_temp, detail
local median = r(p50)
local p25 = r(p25)
local p75 = r(p75)
local median_iqr = string(`median', "%9.1f") + " (" + string(`p25', "%9.1f") + " - " + string(`p75', "%9.1f") + ")"
putexcel ``year''10 = "`median_iqr'"
}

** 2014-2019

*pre-heatwave
use "$datafile\MEANT_heatwave_tsukuba_date", clear
gen pre_hw_start = hw_start - 5
gen pre_hw_end = hw_start - 1
drop hw_start hw_end
gen year= year(pre_hw_start)
joinby year using "$datafile\tsukuba_temp_data.dta"
keep if date >= pre_hw_start & date <= pre_hw_end
summarize min_temp
local min = r(min)
summarize max_temp
local max = r(max)
local min_max = string(`min', "%9.1f") + ", " + string(`max', "%9.1f")
putexcel H3 = "`min_max'"
summarize mean_temp, detail
local median = r(p50)
local p25 = r(p25)
local p75 = r(p75)
local median_iqr = string(`median', "%9.1f") + " (" + string(`p25', "%9.1f") + " - " + string(`p75', "%9.1f") + ")"
putexcel H4 = "`median_iqr'"

* heatwave
use "$datafile\MEANT_heatwave_tsukuba_date", clear
gen year= year(hw_start)
joinby year using "$datafile\tsukuba_temp_data.dta"
keep if date >= hw_start & date <= hw_end
summarize min_temp
local min = r(min)
summarize max_temp
local max = r(max)
local min_max = string(`min', "%9.1f") + ", " + string(`max', "%9.1f")
putexcel H6 = "`min_max'"
summarize mean_temp, detail
local median = r(p50)
local p25 = r(p25)
local p75 = r(p75)
local median_iqr = string(`median', "%9.1f") + " (" + string(`p25', "%9.1f") + " - " + string(`p75', "%9.1f") + ")"
putexcel H7 = "`median_iqr'"

*post-heatwave
use "$datafile\MEANT_heatwave_tsukuba_date", clear
gen post_hw_start = hw_end + 1
gen post_hw_end = hw_end + 5
drop hw_start hw_end
gen year= year(post_hw_start)
joinby year using "$datafile\tsukuba_temp_data.dta"
keep if date >= post_hw_start & date <= post_hw_end
summarize min_temp
local min = r(min)
summarize max_temp
local max = r(max)
local min_max = string(`min', "%9.1f") + ", " + string(`max', "%9.1f")
putexcel H9 = "`min_max'"
summarize mean_temp, detail
local median = r(p50)
local p25 = r(p25)
local p75 = r(p75)
local median_iqr = string(`median', "%9.1f") + " (" + string(`p25', "%9.1f") + " - " + string(`p75', "%9.1f") + ")"
putexcel H10 = "`median_iqr'"

log close