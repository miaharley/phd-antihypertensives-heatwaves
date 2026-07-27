/*=========================================================================
DO FILE NAME:			_describe_data

AUTHOR:					Mia Harley
VERSION:				v1
DO-file required:		
					
DATABASE:				Japanese claims data

Aim: 					Describes all variables in each dataset
*=============================================================================*/

/******************************************************************
All datafiles
******************************************************************/

cd "Z:\Mia\antihyp\datafile"

local filelist : dir . files "*.dta"

log using "Z:\Mia\antihyp\describe_data\describe_datafiles", text replace

foreach f in `filelist' {
use "`f'", clear
describe
summarize
}

log close

/******************************************************************
All covariate datafiles
******************************************************************/

cd "Z:\Mia\antihyp\datafile\covariates"

local filelist : dir . files "*.dta"

log using "Z:\Mia\antihyp\describe_data\describe_datafiles_covariates", text replace

foreach f in `filelist' {
use "`f'", clear
describe
summarize
}

log close

/******************************************************************
Original data
******************************************************************/

cd "Z:\Mia\Original data"

local filelist : dir . files "*.dta"

log using "Z:\Mia\antihyp\describe_data\describe_Originaldata", text replace

foreach f in `filelist' {
use "`f'", clear
describe
summarize
}

log close