# Primavera XER Tools

A repository of small utilities that will help in analyzing the project schedules (.xer files) output by the scheduling software "Oracle Primavera".

These command-line utilities can be ran manually, or integrated into an automated-process/work-flow.  In general these utilities follow the [UNIX philosophy](https://en.wikipedia.org/wiki/Unix_philosophy) much as possible.

# Project Motivation

Small and nimble utilities for analyzing XER files can aid in quickly identifying changes, trends, or mistakes in project schedules; especially in large projects where manual data manipulation in Excel is too time consuming and error-prone.

The output from these utilities are intended to be useful for promoting discussions when looked upon in isolation; but can also be useful for embedding in data viz (BI tools) or importing into SQL databases.  

By default, these utilities will output only what's _relevant_.  What is meant by this, is that when output is used in BI tools or SQL, the output should be joined (as a table relationship) with other data sets to garner a complete perspective of the data.  However, as this may not always be sufficient for some users, the utility (where possible) will include the functionality to output a greater verbosity of data.

# Pre-Compiled Binaries

Binaries (.exe) for Windows OS have been pre-compiled and can be found in the 'bin' folder.

With git, you can download all the latest source and binaries with `git clone https://github.com/chipnetics/xertools`

Alternatively, if you don't have git installed:

1. Download the latest release [here](https://github.com/chipnetics/xertools/releases)
2. Unzip to a local directory.
3. Navigate to 'bin' directory for executables.

# Compiling from Source

Utilities are written in the V programming language and will compile under Windows, Linux, and MacOS.

V is syntactically similar to Go, while equally fast as C.  You can read about V [here](https://vlang.io/).

Each utility is its own .v file, so after installing the [latest V compiler](https://github.com/vlang/v/releases/), it's as easy as executing the below.  _Be sure that the V compiler root directory is part of your PATH environment._

```
git clone https://github.com/chipnetics/xertools
cd src
v build filename.v
```
Alternatively, if you don't have git installed:

1. Download the bundled source [here](https://github.com/chipnetics/xertools/archive/refs/heads/main.zip)
2. Unzip to a local directory
3. Navigate to src directory and run `v build filename.v`

Please see the [V language documentation](https://github.com/vlang/v/blob/master/doc/docs.md) for further help if required.

# Running Optional Command Line Arguments

For Windows users, if you want to pass optional command line arguments to an executable:

1. Navigate to the directory of the utility.
2. In Windows Explorer type 'cmd' into the path navigation bar.
3. Type the name of the exe along with the optional argument (i.e. `utilityname.exe --help` ).

# Date Conventions

When there's more than one .xer input file expected, input files are parsed alphabetically. Therefore it is important that file naming follow the [ISO8601](https://en.wikipedia.org/wiki/ISO_8601) date convention.

Simply stated, this means input files should be named starting with YYYYMMDD or YYYY-MM-DD, as these are guaranteed to sort chronologically as well as alphabetically.  Notwithstanding, this simply amounts to respectfully sane file organization.

# Comparing to Baselines

With the date conventions above in mind, it is possible to generate comparisons to baselines by ensuring the baseline schedule sorts first alphabetically. As a suggestion, an easy way to flag your baseline .xer and have it sort first is by simple naming it `0000.xer` (as one example).

# Viewing Large Files

As an aside, the author recommends the excellent tool _EmEditor_ by Emurasoft for manually editing or viewing large text-based files for data science & analytics. Check out the tool [here](https://www.emeditor.com/).  _EmEditor_ is paid software but well worth the investment to increase effeciency.

*** 

# Utilities

## XER Difference
### bin/xerdiff.exe 
> Identify what task codes have been added or deleted between 2 or more XER files. The utility will parse each successive pair of .xer files.  That is, if you have three xer files (A.xer, B.xer, C.xer) it will compare A-with-B and then B-with-C.  Files are parsed alphabetically.  There is no limit to the number of .xer files that can be inputted.

**Input:** Two or more .xer files, in the same directory as xerdiff.exe

**Output:** xerdiff.txt, in the same directory as xerdiff.exe

**Optional Command Line Arguments** 

> `xerdiff.exe --full`  
Outputs all field columns from XER TASK table (default is Task Code and Task Name only).

---
## XER Dump
### bin/xerdump.exe 
> Extract all embedded tables within a .xer to individual .txt files.  That is, if the input file is XYZ.xer, xerdump will create a folder 'XYZ' and extract all tables in the xer (i.e. ACTVCODE, ACTVTYPE, TASK, etc...) within that folder.  It will continue this process for all .xer files in the directory. There is no limit to the number of .xer files that can be inputted.

**Input:** One or more .xer files, in the same directory as xerdump.exe

**Output:** Various .txt files for each input XER, in individual folders, in the same directory as xerdump.exe

**Optional Command Line Arguments** 

_No optional arguments at this time._

----

## XER Task
### bin/xertask.exe 
>  Transform XER TASK data, and also ajoin it to the PROJECT and CALENDAR tables.  This tool can also perform a detailed analysis on the XER TASK table as an alternative mode of operation.

**Input:** One or more .xer files, in the same directory as xertask.exe

**Output:** Outputs to standard output the requested columns along with the requested unpivot columns.  Or in analytics mode (specified with -a flag), will output analytical data to standard output (stdout).

**Optional Command Line Arguments** 

```  
Options:
  -p, --pivot <string>      specify list of pivot indexes
  -h, --header <string>     specify list of header indexes
  -m, --mapping             output available columns (with indexes)
  -a, --analytics           perform analytics on latest TASK table
  -h, --help                display this help and exit
  --version                 output version information and exit
```  
**Examples using pivot (-p), header (-h), and mapping (-m) flags:**

> To get a list of all the available columns to select in your query:

`xertask.exe --mapping`

>To get an output of {late,early,target}_{start,end}_dates:

`xertask.exe -p 1,14,15,70,75 -h 30,31,33,34,37,38`

Would output the columns 
- xer_filename
- task_id
- task_code
- task_name
- clndr_name
- day_hr_cnt

Along with two additional columns of the unpivot header and values for
- late_start_date
- late_end_date
- early_start_date
- early_end_date
- target_start_date
- target_end_date

> To get an output of {total,free}_float_hr_cnt

`xertask.exe -p 1,14,15,70,75 -h 17-18`

Would output the columns 
- xer_filename
- task_id
- task_code
- task_name
- clndr_name
- day_hr_cnt

Along with two additional columns of the unpivot header and values for

- total_float_hr_cnt
- free_float_hr_cnt

**Examples using analytics (-a) flag:**

`xertask.exe -a`

> Analytics flag will output the following columns, with the below definitions

| Analytics Column      | Description |
| ----------- | ----------- |
| xer_filename      | Filename of XER the analysis is upon       |
| proj_id   | Line item project ID        |
| task_code   | Line item task code  |
| task_name   | Line item task name  |
| task_type   | Line item task type  |
| last_recalc   | Line item last re-calc date (from PROJECT table)        |
| is_active   | True if last_recalc between curr_start & curr_finish        |
| curr_duration_days   | curr_start *less* curr_finish        |
| curr_start   | Line item target start date        |
| curr_finish   | Line item target end date        |
| prev_appears   | Filename of previous XER that line item appears in       |
| prev_duration_days   | Previous curr_start *less* curr_finish        |
| prev_start   | Previous line item target start date        |
| prev_finish   | Previous line item target end date        |
| ini_appears   | Filename of initial XER that line item appears in        |
| ini_duration_days   | Initial curr_start *less* curr_finish |
| ini_start   | Initial line item target start date        |
| ini_finish   | Initial line item target end date        |
| snap_dur_growth_days   |   curr_duration_days *less* prev_duration_days     |
| snap_start_delta_days   | curr_start *less*  prev_start      |
| snap_end_delta_days   | curr_finish *less* prev_finish        |
| snap_has_delta   | True if  snap_start_delta_days > 0 or snap_end_delta_days > 0   |
| total_start_delta_days   | curr_start *less* ini_start        |
| total_end_delta_days   | curr_finish *less*  ini_finish       |
| total_dur_growth   | curr_duration_days *less* ini_duration_days        |
| is_completed   | True if phys_complete_pct = 100        |
| snap_completed   | True if is-completed and previous phys_complete_pct < 100   |
| realized_duration   | Final curr_duration_days when is_completed = true        |
| realized_accuracy   | curr_duration_days *divided by* ini_duration_days        |

----

## XER Predecessors
### bin/xerpred.exe 
>  Tool that will output a list of every task code with all its predecessors, descending recursively to the specified depth.  For instance if activity A has predecessors B and C; the tool will continue to show the predecessors of B and C (say D, E, F), and then the predecessors of D,E,F - continuing on and on until there are none left to process.  _As complex and long schedules can lead to very large file sizes, you can specify the depth limit to process up until._

>This tool can also output the list of schedule drivers; such as those indicated by the "Driver" flag in the relationships table in P6.

**Input:** One .xer files, in the same directory as xerpred.exe

**Output:** Outputs to standard output the complete list of predecessors to the specified depth level [default depth of 5].  Or in drivers mode (specified with -d flag), will output the list of schedule drivers to standard output (stdout).

**Optional Command Line Arguments** 

```  
Options:
  -f, --xer <string>        specify the XER for analysis
  -m, --minimal             output only task-id records
  -l, --depth <int>         specify max predecessor depth [default:5]
  -d, --drivers             output schedule drivers and exit
  -h, --help                display this help and exit
  --version                 output version information and exit
```  
**Basic example with full output**

`xerpred.exe -f myprojectschedule.xer`

**Example with minimal output**
> Useful when you intend to join the results with other data tables, such as those from xerdump.exe, to minimize redundancy.

`xerpred.exe -f myprojectschedule.xer --minimal`

**Example of outputting the schedule drivers only**

`xerpred.exe -f myprojectschedule.xer --drivers`
