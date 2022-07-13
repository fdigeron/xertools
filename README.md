![image](assets/logo.png)
# Primavera XER Tools

A repository of small utilities that will help in analyzing the project schedules (.xer files) output by the scheduling software "Oracle Primavera".

These command-line utilities can be ran manually, or integrated into an automated-process/work-flow.  In general these utilities follow the [UNIX philosophy](https://en.wikipedia.org/wiki/Unix_philosophy) much as possible.

# Project Motivation

Small and nimble utilities for analyzing XER files can aid in quickly identifying changes, trends, or mistakes in project schedules; especially in large projects where manual data manipulation in Excel is too time consuming and error-prone.

The output from these utilities are intended to be useful for promoting discussions when looked upon in isolation; but can also be useful for embedding in data viz (BI tools) or importing into SQL databases.  

By default, these utilities will output only what's _relevant_.  What is meant by this, is that when output is used in BI tools or SQL, the output should be joined (as a table relationship) with other data sets to garner a complete perspective of the data.  However, as this may not always be sufficient for some users, the utility (where possible) will include the functionality to output a greater verbosity of data.

# Pre-Compiled Binaries

Binaries (.exe) for Windows and Linux have been pre-compiled and can be found in the [Releases on Github](https://github.com/chipnetics/xertools/releases).

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
3. Type the name of the exe along with the optional argument (i.e. `xerdump.exe --help` ).

For users who cannot learn the command line, or have no intention of automating their work process via batch-file scripting, there is a graphical front-end available [here](https://github.com/chipnetics/xertools_gui).  *However, it is highly recommended to use the tools via command line for maximum flexibility.*

# XER Ordering and Date Conventions

When there's more than one .xer input file expected, and you haven't manually specified the order to analyze files, the input files are parsed alphabetically. 

Therefore it is important that file naming follow the [ISO8601](https://en.wikipedia.org/wiki/ISO_8601) date convention. Input files should be named starting with YYYYMMDD or YYYY-MM-DD, as these are guaranteed to sort chronologically as well as alphabetically.

# Comparing to Baselines

With the date conventions above in mind, it is possible to generate comparisons to baselines by ensuring the baseline schedule sorts first alphabetically, or is specified as the first file.

# Viewing Large Files

The author recommends the excellent tool _EmEditor_ by Emurasoft for manually editing or viewing large text-based files for data science & analytics. Check out the tool [here](https://www.emeditor.com/).  _EmEditor_ is paid software but well worth the investment to increase effeciency.

*** 

# Utilities

All utilities can be updated via the command line.  This will check the Releases for the latest pre-built binaries and download it for that tool.

## XER Difference
### xerdiff.exe (Windows) | xerdiff (Linux)
> Identify what task codes have been added or deleted between 2 or more XER files. The utility will parse each successive pair of .xer files.  That is, if you have three xer files (A.xer, B.xer, C.xer) it will compare A-with-B and then B-with-C.  There is no limit to the number of .xer files that can be inputted.

**Input:** Two or more .xer files

**Output:** `xerdiff_output.txt`, in the same directory as xerdiff.exe

**Optional Command Line Arguments** 

```
Options:
  -f, --xerlist <string>    specify a file with a list of XER files to process
  -u, --update              check for tool updates
  -z, --force-update        check for tool updates, auto-install if available
  -h, --help                display this help and exit
  --version                 output version information and exit
```
---
## XER Dump
### xerdump.exe (Windows) | xerdump (Linux)
> Extract all embedded tables within a .xer to either individual .txt files, single .txt files, or a SQLite database. It will continue this process for all .xer files. There is no limit to the number of .xer files that can be inputted.

**Input:** One or more .xer files

**Output:** 

*Individual mode* ::: xerdump will create an individual folder for each XER, and extract all tables in the xer (i.e. ACTVCODE, ACTVTYPE, TASK, etc...) to the respective folders.

*Append mode* ::: xerdump will create 1 folder named 'combined' and extract all tables in the xers (i.e. ACTVCODE, ACTVTYPE, TASK, etc...) to respective .txt files; appending to them for each xer. 

*Consolidated mode* ::: xerdump will create a file `xerdump_consolidated.txt` with all possible combinations of ACTVTYPE, ACTVCODE and TASK.

*SQL mode* ::: xerdump will create a database `primavera.db` with all the tables from all the XERs dumped

NB: You can run more than one mode at once.

**Optional Command Line Arguments** 

```
Options:
  -i, --individual          extract tables into respective folders
  -a, --append              append tables together in a single folder
  -c, --consolidated        extract all combinations of ACTVTYPE and ACTVCODE
  -s, --sql                 create an sqlite database for querying
  -f, --xerlist <string>    specify a file with a list of XER files to process
  -u, --update              check for tool updates
  -z, --force-update        check for tool updates, auto-install if available
  -h, --help                display this help and exit
  --version                 output version information and exit
```
----

## XER Task
### xertask.exe (Windows) | xertask (Linux)
>  Transform XER TASK data, with options to ajoin the PROJECT and CALENDAR tables.  This tool can also perform a detailed analysis on the XER TASK table as an alternative mode of operation.

**Input:** One or more .xer files

**Output:** 

*Normal mode* ::: xertask outputs to standard output the requested columns along with the requested unpivot columns.

*Analytics mode* ::: xertask will output analytical data to `xertask_analytics.txt`.

**Optional Command Line Arguments** 

```
Options:
  -p, --pivot <string>      specify list of pivot indexes
  -h, --header <string>     specify list of header indexes
  -m, --mapping             output available columns (with indexes)
  -a, --analytics           perform analytics on latest TASK table
  -o, --output <string>     specify a filename for the output
  -f, --xerlist <string>    specify a file with a list of XER files to process
  -u, --update              check for tool updates
  -z, --force-update        check for tool updates, auto-install if available
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
| snap_start_delta_hist | The history of snap_start_delta_days (from oldest to newest)      |
| snap_start_slip_freq | # of non-zero values in snap_start_delta_hist *divided by* # elements |
| snap_end_delta_days   | curr_finish *less* prev_finish        |
| snap_end_delta_hist | The history of snap_end_delta_days (from oldest to newest)      |
| snap_end_slip_freq | # of non-zero values in snap_end_delta_hist *divided by* # elements |
| snap_has_delta   | True if  snap_start_delta_days > 0 or snap_end_delta_days > 0   |
| total_start_delta_days   | curr_start *less* ini_start        |
| total_end_delta_days   | curr_finish *less*  ini_finish       |
| total_dur_growth   | curr_duration_days *less* ini_duration_days        |
| is_completed   | True if phys_complete_pct = 100        |
| snap_completed   | True if is-completed and previous phys_complete_pct < 100   |
| realized_duration   | Final curr_duration_days when is_completed = true        |
| realized_accuracy   | curr_duration_days *divided by* ini_duration_days        |
| total_float_hr_cnt   | The latest total float hour count       |
| total_float_hr_cnt_hist   | The history of total float hour count (from oldest to newest)        |
| free_float_hr_cnt   | The latest free float hour count       |
| free_float_hr_cnt_hist   | The history of free float hour count (from oldest to newest)        |

----

## XER Predecessors
### xerpred.exe (Windows) | xerpred (linux)
>  Tool that will output a list of every task code with all its predecessors, descending recursively to the specified depth.  For instance if activity A has predecessors B and C; the tool will continue to show the predecessors of B and C (say D, E, F), and then the predecessors of D,E,F - continuing on and on until there are none left to process.  _As complex and long schedules can lead to very large file sizes, you can specify the depth limit to process up until._

>This tool can also output the list of schedule drivers; such as those indicated by the "Driver" flag in the relationships table in P6, and display analytics regarding how drivers were added or deleted from XER-to-XER.

**Input:** One or more .xer files.

**Output:** 

*Predecessors mode:* :: Outputs to `xerpred_predecessors.txt` the complete list of predecessors to the specified depth level [default depth of 5].

*Drivers mode:* :: Output the list of schedule drivers to `xerpred_drivers.txt` and `xerpred_drivers_analysis.txt`.

**Optional Command Line Arguments** 

```  
Options:
  -p, --predecessors        output schedule predecessors
  -l, --depth <int>         specify max predecessor depth [default:5]
  -m, --minimal             output only task-id records
  -d, --drivers             output schedule drivers
  -f, --xerlist <string>    specify a file with a list of XER files to process
  -u, --update              check for tool updates
  -z, --force-update        check for tool updates, auto-install if available
  -h, --help                display this help and exit
  --version                 output version information and exit
```  
 
**Basic example with full output, and no depth specified (default of 5)**

`xerpred.exe myprojectschedule.xer`

**Basic example with full output, and depth of 10**

>Note that file sizes can start to get large at this depth...

`xerpred.exe myprojectschedule.xer --depth 10`

**Example with minimal output**
> Useful when you intend to join the results with other data tables, such as those from xerdump.exe, to minimize disk space usage.

`xerpred.exe myprojectschedule.xer --minimal`

**Example of outputting the schedule drivers only**

`xerpred.exe myprojectschedule.xer --drivers`

--------
## XER to JSON (xer2json)
### xer2json.exe (windows) | xer2json (linux)
>  Convert an XER file to JSON format for usage in other tools.

**Input:** One or more .xer files.

**Output:** Writes a json file with the same filename as the XER.  Such that abc.xer will be written as JSON to abc.json.

**Optional Command Line Arguments** 

```  
Options:
  -u, --update              check for tool updates
  -z, --force-update        check for tool updates, auto-install if available
  -h, --help                display this help and exit
  --version                 output version information and exit
```  
------------

