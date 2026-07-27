# Code

This folder contains the Stata code used to create the study cohort and perform the analyses.

## Workflow

The analysis is run using:
- `_paths.do` - defines global macros and file paths.
- `_masterdo_v4.do` - runs all the scripts in the correct order

The remaining do-files are executed by the master script to create the study cohort and perform the statistical analyses.
