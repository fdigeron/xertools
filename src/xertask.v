// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
import os
import xer
import flag
import time

fn main()
{
	mut fp := flag.new_flag_parser(os.args)
    fp.application('xertask')
	
    fp.version('v0.0.1\nCopyright (c) 2022 jeffrey -at- ieee.org. All rights \
	reserved.\nUse of this source code (/program) is governed by an MIT \
	license,\nthat can be found in the LICENSE file.')

    fp.description('\nPerforms analytics on Primavera XER Schedules.\n\
	Analytics are on the \'TASK\' table in XER schedules.\n\
	However other tables \'CALENDAR\',\'PROJECT\' can be ajoined.\n\
	This software will -NOT- make any changes to your XER files.')

    fp.skip_executable()

    mut pivot_column_arg := fp.string('pivot', `p`, "1,14,15", 
								'comma-separated list of pivot indexes.')
	mut header_column_arg := fp.string('header', `h`, "17-21,30,31,33,34,37,38", 
								'comma-separated list of header indexes.')
	column_mapping_arg := fp.bool('mapping', `m`, false, 
								'print XER TASK header with indexes.')

	additional_args := fp.finalize() or {
        eprintln(err)
        println(fp.usage())
        return
    }

	additional_args.join_lines()

	if column_mapping_arg
	{
		println("You may use the below indexes as arguments to xertask.exe.")
		println("If no arguments are provided, the default is:\n\
		\t-p 1,14,15\n\
		\t-h 17-21,30,31,33,34,37,38\n")
		xer.print_task_header(0)
		println("\n")
		xer.print_calendar_header(67)
		println("\n")
		xer.print_project_header(81)
		return
	}				

	dir_elems := os.ls(".") or {panic(err)}
	mut xer_files := []string{}

	for file in dir_elems
	{
		if file.ends_with(".xer")
		{
			xer_files << file
		}
	}

	pivot_column := expand_int_string(pivot_column_arg)
	header_column := expand_int_string(header_column_arg)

	unpivot_tasks_xers(xer_files,pivot_column,header_column)

	//analysis_on_tasks_xers(xer_files)
}

fn analysis_on_tasks_xers(xer_files []string)
{
	mut xer_combined := []map[string]xer.XER_task{}

	for xer_file in xer_files
	{
		xer_combined << xer.parse_task(xer_file)
	}

	latest_xer := xer_combined[xer_files.len-1].clone() // points to latest XER struct
	prev_xer := xer_combined[xer_files.len-2].clone() // points to previous XER struct
	first_xer := xer_combined[0].clone() // points to first (base) XER struct

	//println("${latest_xer.xer_map["HB-EC-1000-49-10562"].task_code}")

	for key,value in latest_xer  // Do analytics on latest XER only
	{
		print("\
		$value.xer_filename\t\
		$value.proj_id\t\
		$value.task_code\t\
		$value.task_name\t\
		$value.task_type\t\
		$value.task_type\t\
		")

		start_time := time.parse("${value.target_start_date}:00") or 
					{eprintln("Unable to parse date.") exit(0)}
		end_time := time.parse("${value.target_end_date}:00") or 
					{eprintln("Unable to parse date.") exit(0)}
		diff_days := ((end_time - start_time).hours()/24)

		print("\
		${diff_days:.0}\t\
		$value.target_start_date\t\
		$value.target_end_date\n\
		")

		last_start := prev_xer[key].target_start_date
		last_end := prev_xer[key].target_end_date

	}
}

// Takes a list of XER files and unpivots based on the user-select columns.
// The list of available columns can be printed with -m flag.
// Function not only unpivots the entries in TASK table, but will also
// ajoin CALENDAR and PROJECT tables, such that users can add those column
// items to their output.
fn unpivot_tasks_xers(xer_files []string, p_col []int, h_col []int)
{
	// Print the header once...
	mut delimited_header := xer.task_header().split("\t")

	// Push CALENDAR, PROJECT header data to end of TASK header
	delimited_header << xer.calendar_header().split("\t")
	delimited_header << xer.project_header().split("\t")

	//Print to stdout the columns headers.
	print("xer_filename\t")
	for cols in p_col
	{
		print("${delimited_header[cols]}\t")
	}
	println("unpivot_col\tunpivot_val")

	for index,_ in xer_files
	{
		// for each xer, parse the CALENDAR and PROJECT tables
		calendar_map := xer.parse_calendar(xer_files[index])
		project_map := xer.parse_project(xer_files[index])

		lines := os.read_lines(xer_files[index]) or {panic(err)}
		
		mut line_index := 0

		for line in lines
		{	
			line_index++
			if compare_strings(line,"%T\tTASK") == 0
			{
				line_index++ // Advance passed header...

				for i:=line_index; i<lines.len; i++
				{
					if lines[i].starts_with("%T")
					{
						break
					}

					mut delimited_row := lines[i].split("\t")
					
					// Push CALENDAR, PROJECT row data to end of TASK array
					delimited_row << calendar_map[delimited_row[4]].to_array()
					delimited_row << project_map[delimited_row[2]].to_array()

					mut pivot_col_string := "${xer_files[index]}\t"

					for cols in p_col
					{
						pivot_col_string += delimited_row[cols] + "\t"
					}

					for heads in h_col
					{
						print(pivot_col_string)
						print(delimited_header[heads])
						print("\t")
						print(delimited_row[heads])
						print("\n")
					}
				}		
			}
		}

	}
}

// "1,2,5-10,8"  ==> [1,2,5,6,7,8,9,10,8]
fn expand_int_string(ranges string) []int
{
	ranges_split := ranges.split(",")
	mut return_arr := []int{}

	for elem in ranges_split
	{
		if elem.contains("-")
		{
			elem_split := elem.split("-")

			mut lower_bound:= elem_split[0].int()
			upper_bound:= elem_split[1].int()

			for i:=lower_bound; i<=upper_bound; i++
			{
				return_arr << i
			}
		}
		else
		{
			return_arr << elem.int()
		}
	}

	return return_arr
}