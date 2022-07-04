// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
/// Necessary imports for pre-built updating functionality
import os
import xer
import util
import flag
import time
import math

fn main() {
	mut pre_built_str := ''
	$if prebuilt ? {
		pre_built_str = '[pre-built binary release (##DATE##)]\n'
	}

	mut fp := flag.new_flag_parser(os.args)
	fp.application('xertask')

	fp.version('${pre_built_str}Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.\nUse of this source code (/program) is governed by an MIT license,\nthat can be found in the LICENSE file.')

	fp.description("\nPerforms analytics on Primavera XER Schedules.\nAnalytics are on the 'TASK' table in XER schedules.\nHowever other tables 'CALENDAR','PROJECT' can be ajoined.\nThis software will -NOT- make any changes to your XER files.")

	fp.skip_executable()

	mut pivot_column_arg := fp.string('pivot', `p`, '1,14,15', 'specify list of pivot indexes')
	mut header_column_arg := fp.string('header', `h`, '17-21,30,31,33,34,37,38', 'specify list of header indexes')
	column_mapping_arg := fp.bool('mapping', `m`, false, 'output available columns (with indexes)')
	analytics_arg := fp.bool('analytics', `a`, false, 'perform analytics on latest TASK table')
	update_arg := fp.bool('update', `u`, false, 'check for tool updates')

	additional_args := fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}

	additional_args.join_lines()

	if update_arg {
		util.github_update('chipnetics', 'xertools', 'xertask.exe')
		return
	}

	if column_mapping_arg {
		println('You may use the below indexes as arguments to xertask.exe.')
		println('If no arguments are provided, the default is:\n\t-p 1,14,15\n\t-h 17-21,30,31,33,34,37,38\n')
		xer.print_task_header(0)
		println('\n')
		xer.print_calendar_header(67)
		println('\n')
		xer.print_project_header(81)
		return
	}

	dir_elems := os.ls('.') or { panic(err) }
	mut xer_files := []string{}

	for file in dir_elems {
		if file.ends_with('.xer') {
			xer_files << file
		}
	}

	xer_files.sort()

	if analytics_arg {
		analysis_on_tasks_xers(xer_files)
	} else {
		pivot_column := expand_int_string(pivot_column_arg)
		header_column := expand_int_string(header_column_arg)

		unpivot_tasks_xers(xer_files, pivot_column, header_column)
	}
}

fn analysis_on_tasks_xers(xer_files []string) {
	println('xer_filename\tproj_id\ttask_id\ttask_code\ttask_name\ttask_type\tlast_recalc\tis_active\tcurr_duration_days\tcurr_start\tcurr_finish\tprev_appears\tprev_duration_days\tprev_start\tprev_finish\tini_appears\tini_duration_days\tini_start\tini_finish\tsnap_dur_growth_days\tsnap_start_delta_days\tsnap_start_delta_hist\tsnap_start_slip_freq\tsnap_end_delta_days\tsnap_end_delta_hist\tsnap_end_slip_freq\tsnap_has_delta\ttotal_start_delta_days\ttotal_end_delta_days\ttotal_dur_growth\tis_completed\tsnap_completed\trealized_duration\trealized_accuracy\ttotal_float_hr_cnt\ttotal_float_hr_cnt_hist\tfree_float_hr_cnt\tfree_float_hr_cnt_hist')

	mut xer_combined := []map[string]xer.XER_task{}

	for xer_file in xer_files {
		xer_combined << xer.parse_task(xer_file)
	}

	latest_xer := xer_combined[xer_files.len - 1].clone() // points to latest XER struct
	prev_xer := xer_combined[xer_files.len - 2].clone() // points to previous XER struct
	project_map := xer.parse_project(xer_files[xer_files.len - 1]) // for last-recalc

	// history data (start dates, end dates, and float)
	mut start_delta_history := map[string][]f64{}
	mut end_delta_history := map[string][]f64{}
	mut total_float_history := map[string][]int{}
	mut free_float_history := map[string][]int{}
	for idx, _ in xer_combined {
		for task_id, _ in xer_combined[idx] {
			total_float_history[task_id] << xer_combined[idx][task_id].total_float_hr_cnt.int()
			free_float_history[task_id] << xer_combined[idx][task_id].free_float_hr_cnt.int()

			// Only do some operations for the first file (float history)
			// We do not do curr/prev time comparisons on first file (idx 0)
			if idx == 0 {
				continue
			}

			mut has_previous_start := true
			mut has_previous_end := true

			curr_start_time := time.parse('${xer_combined[idx][task_id].target_start_date}:00') or {
				time.Time{}
			}

			prev_start_time := time.parse('${xer_combined[idx - 1][task_id].target_start_date}:00') or {
				has_previous_start = false
				time.Time{}
			}

			curr_end_time := time.parse('${xer_combined[idx][task_id].target_end_date}:00') or {
				time.Time{}
			}

			prev_end_time := time.parse('${xer_combined[idx - 1][task_id].target_end_date}:00') or {
				has_previous_end = false
				time.Time{}
			}

			if has_previous_start {
				start_delta_history[task_id] << math.round(((curr_start_time - prev_start_time).hours() / 24))
			} else {
				start_delta_history[task_id] << 0.00
			}

			if has_previous_end {
				end_delta_history[task_id] << math.round(((curr_end_time - prev_end_time).hours() / 24))
			} else {
				end_delta_history[task_id] << 0.00
			}
		}
	}

	// slip frequencies.
	mut start_slip_freq := map[string]f64{}
	mut end_slip_freq := map[string]f64{}
	for task_id, _ in latest_xer {
		mut start_slips := 0.00
		for starts in start_delta_history[task_id] {
			if starts != 0 {
				start_slips++
			}
		}
		start_slip_freq[task_id] = start_slips / (start_delta_history[task_id].len)

		mut end_slips := 0.00
		for ends in end_delta_history[task_id] {
			if ends != 0 {
				end_slips++
			}
		}

		end_slip_freq[task_id] = end_slips / (end_delta_history[task_id].len)
	}

	// Do analytics on latest XER only
	for key, value in latest_xer {
		// xer_filename, proj_id, task_code, task_name, task_type
		print('$value.xer_filename\t$value.proj_id\t$value.task_id\t$value.task_code\t$value.task_name\t$value.task_type\t')

		// last_recalc, is_active,curr_duration_days, current_start, current_finish
		recalc_time := time.parse('${project_map[value.proj_id].last_recalc_date}:00') or {
			time.Time{}
		}

		curr_start_time := time.parse('$value.target_start_date:00') or { time.Time{} }
		curr_end_time := time.parse('$value.target_end_date:00') or { time.Time{} }
		curr_dur_days := ((curr_end_time - curr_start_time).hours() / 24)

		mut is_active := false
		if recalc_time > curr_start_time && recalc_time < curr_end_time {
			is_active = true
		}

		print('${project_map[value.proj_id].last_recalc_date}\t$is_active\t${curr_dur_days:0.1f}\t$value.target_start_date\t$value.target_end_date\t')

		// prev_appears, prev_duration_days, prev_start, prev_finish
		prev_start_time := time.parse('${prev_xer[key].target_start_date}:00') or { time.Time{} }
		prev_end_time := time.parse('${prev_xer[key].target_end_date}:00') or { time.Time{} }
		prev_dur_days := ((prev_end_time - prev_start_time).hours() / 24)

		if compare_strings(prev_xer[key].target_start_date, '') == 0 {
			print('New\t')
		} else {
			print('${prev_xer[key].xer_filename}\t')
		}

		print('${prev_dur_days:0.1f}\t${prev_xer[key].target_start_date}\t${prev_xer[key].target_end_date}\t')

		// ini_appears, ini_duration_days, ini_start, ini_finish
		mut ini_start_time := time.Time{}
		mut ini_end_time := time.Time{}
		mut ini_dur_days := 0.0

		for xer in xer_combined {
			if xer.keys().contains(key) {
				ini_start_time = time.parse('${xer[key].target_start_date}:00') or {
					eprintln('Unable to parse date.')
					exit(0)
				}
				ini_end_time = time.parse('${xer[key].target_end_date}:00') or {
					eprintln('Unable to parse date.')
					exit(0)
				}
				ini_dur_days = ((ini_end_time - ini_start_time).hours() / 24)

				print('${xer[key].xer_filename}\t${ini_dur_days:0.1f}\t$ini_start_time\t$ini_end_time\t')

				break
			}
		}

		mut movement_lastsnap := false
		if start_delta_history[key][start_delta_history[key].len - 1] != 0
			|| end_delta_history[key][end_delta_history[key].len - 1] != 0 {
			movement_lastsnap = true
		}
		print('${curr_dur_days - prev_dur_days:0.1f}\t${start_delta_history[key][start_delta_history[key].len - 1]}\t${start_delta_history[key]}\t${start_slip_freq[key]:0.2f}\t${end_delta_history[key][end_delta_history[key].len - 1]}\t${end_delta_history[key]}\t${end_slip_freq[key]:0.2f}\t$movement_lastsnap\t')

		// total_start_delta_days, total_end_delta_days, total_dur_growth
		total_start_delta_days := ((curr_start_time - ini_start_time).hours() / 24)
		total_end_delta_days := ((curr_end_time - ini_end_time).hours() / 24)
		total_dur_growth := curr_dur_days - ini_dur_days
		print('${total_start_delta_days:0.1f}\t${total_end_delta_days:0.1f}\t${total_dur_growth:0.1f}\t')

		// is_completed, snap_completed
		mut is_completed := false
		mut snap_completed := false
		if compare_strings(value.phys_complete_pct, '100') == 0 {
			is_completed = true
		}
		if compare_strings(prev_xer[key].phys_complete_pct, '100') != 0 && is_completed == true {
			snap_completed = true
		}
		print('$is_completed\t$snap_completed\t')

		// realized_duration
		if is_completed {
			print('${curr_dur_days:0.1f}\t')

			// realized accuracy
			if ini_dur_days < 0.001 && curr_dur_days < 0.001 {
				print('1.00\t')
			} else {
				print('${curr_dur_days / ini_dur_days:0.2f}\t')
			}
		} else {
			print('\t\t') // Tab over as not yet completed...
		}

		print('$value.total_float_hr_cnt\t${total_float_history[key]}\t')
		print('$value.free_float_hr_cnt\t${free_float_history[key]}')

		print('\n')
	}
}

// Takes a list of XER files and unpivots based on the user-select columns.
// The list of available columns can be printed with -m flag.
// Function not only unpivots the entries in TASK table, but will also
// ajoin CALENDAR and PROJECT tables, such that users can add those column
// items to their output.
fn unpivot_tasks_xers(xer_files []string, p_col []int, h_col []int) {
	// Print the header once...
	mut delimited_header := xer.task_header().split('\t')

	// Push CALENDAR, PROJECT header data to end of TASK header
	delimited_header << xer.calendar_header().split('\t')
	delimited_header << xer.project_header().split('\t')

	// Print to stdout the columns headers.
	print('xer_filename\t')
	for cols in p_col {
		print('${delimited_header[cols]}\t')
	}
	println('unpivot_col\tunpivot_val')

	for index, _ in xer_files {
		// for each xer, parse the CALENDAR and PROJECT tables
		calendar_map := xer.parse_calendar(xer_files[index])
		project_map := xer.parse_project(xer_files[index])

		lines := os.read_lines(xer_files[index]) or { panic(err) }

		mut line_index := 0

		for line in lines {
			line_index++
			if compare_strings(line, '%T\tTASK') == 0 {
				line_index++ // Advance passed header...
				for i := line_index; i < lines.len; i++ {
					if lines[i].starts_with('%T') {
						break
					}

					mut delimited_row := lines[i].split('\t')

					// Push CALENDAR, PROJECT row data to end of TASK array
					delimited_row << calendar_map[delimited_row[4]].to_array()
					delimited_row << project_map[delimited_row[2]].to_array()

					mut pivot_col_string := '${xer_files[index]}\t'

					for cols in p_col {
						pivot_col_string += delimited_row[cols] + '\t'
					}

					for heads in h_col {
						print(pivot_col_string)
						print(delimited_header[heads])
						print('\t')
						print(delimited_row[heads])
						print('\n')
					}
				}
			}
		}
	}
}

// "1,2,5-10,8"  ==> [1,2,5,6,7,8,9,10,8]
fn expand_int_string(ranges string) []int {
	ranges_split := ranges.split(',')
	mut return_arr := []int{}

	for elem in ranges_split {
		if elem.contains('-') {
			elem_split := elem.split('-')

			mut lower_bound := elem_split[0].int()
			upper_bound := elem_split[1].int()

			for i := lower_bound; i <= upper_bound; i++ {
				return_arr << i
			}
		} else {
			return_arr << elem.int()
		}
	}

	return return_arr
}
