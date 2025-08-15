<div align="center">
  <h1>BatchTriDFusion</h1>
  <p><strong>The BatchTriDFusion</strong> is a tool that launches a batch of imaging studies and executes the TriDFusion workflow in parallel, processing them in defined batches. The tool is provided by <a href="https://daniellafontaine.com/">Daniel Lafontaine</a>.</p>
</div>

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/dicomtools/BatchTriDFusion)
[![GPLv3 license](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://github.com/dicomtools/BatchTriDFusion/blob/main/LICENSE)

![BatchTriDFusion](images/BatchTriDFusionMain.png)

## MATLAB tested version

* MATLAB 2024a
* MATLAB 2025a

## Installation

* https://github.com/dicomtools/BatchTriDFusion/wiki/Source-code-version-of-BatchTriDFusion

Visit https://daniellafontaine.com/ for more information


## Application Requirement
* TriDFusion is required.
Download it from:
	https://github.com/dicomtools/TriDFusion
	

## Command Example
"C:\Program Files\BatchTriDFusion\2025a\BatchTriDFusion.exe" ^
  -p "C:\Program Files\TriDFusion\2025a" ^
  -w setFDGBrownFatFullAIExportToExcelCallback ^
  -e 2 ^
  -c "C:\Program Files\BatchTriDFusion\2025a\BATCH-conditions.xml" ^
  -l "C:\Users\Public\batch_progress_log.txt" ^
  "dicom_folder1" "dicom_folder2" ... "dicom_folderN"
