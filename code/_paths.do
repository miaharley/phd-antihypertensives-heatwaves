/*=========================================================================
DO FILE NAME:			climate-antihypertensives-paths

AUTHOR:					Mia Harley
VERSION:				v1
DO-file required:		
					
DATABASE:				Japanese claims data

Aim: 					To set globals and file paths
*=============================================================================*/

*Extreme temperature and antihypertensives study dates
global studystartdate 01jan2014
global studyenddate 28feb2020
global studystartyear 2014
global studyendyear 2020

*temporary file location
global filepath		"Z:\Mia\antihyp"	
cd 					"$filepath"

*all other locations
global datafile 	"$filepath\datafile"
global codelists 	"$filepath\codelist"  
global logfiles		"$filepath\logfile"
global dofiles		"$filepath\dofile"
global writeup		"$filepath\writeup"
global output		"$filepath\output"


*covariates
global comorbid ischaemic_heart_disease heart_failure venous_thromboembolism cerebrovascular_disease diabetes chronic_renal_disease copd cancer cmd smi
global medications betablockers statins diabetes_medications oac antibiotics ppi antidepressants antipsychotics
