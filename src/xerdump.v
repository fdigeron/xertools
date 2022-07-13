// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
import os
import util
import flag
import xer
import sqlite

fn main() {
	mut pre_built_str := ''
	$if prebuilt ? {
		pre_built_str = '[pre-built binary release (##DATE##)]\n'
	}

	mut fp := flag.new_flag_parser(os.args)
	fp.application('xerdump')

	fp.version('${pre_built_str}Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.\nUse of this source code (/program) is governed by an MIT license,\nthat can be found in the LICENSE file.')

	fp.description('\nDumps all the contents of one or more XER files to respective folders.\nThis software will -NOT- make any changes to your XER files.')

	fp.skip_executable()

	individual_arg := fp.bool('individual', `i`, false, 'extract tables into respective folders')
	append_arg := fp.bool('append', `a`, false, 'append tables together in a single folder')
	consolidated_arg := fp.bool('consolidated', `c`, false, 'extract all combinations of ACTVTYPE and ACTVCODE')
	sql_arg := fp.bool('sql', `s`, false, 'create an sqlite database for querying')
	xer_arg := fp.string('xerlist', `f`, '', 'specify a file with a list of XER files to process')
	update_arg := fp.bool('update', `u`, false, 'check for tool updates')

	additional_args := fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}

	additional_args.join_lines()

	if update_arg {
		$if linux {
			util.github_update('chipnetics', 'xertools', 'xerdump')
		} $else {
			util.github_update('chipnetics', 'xertools', 'xerdump.exe')
		}

		return
	}

	mut xer_files := []string{}

	// File with a list of XER filenames was specified...
	if xer_arg.len > 0 {
		xer_file_list := os.read_lines(xer_arg) or {
			println("Error. Could not open '$xer_arg' to get XER list. Aborting")
			return
		}
		for file in xer_file_list {
			if file.ends_with('.xer') {
				xer_files << file
			}
		}
	}

	// Some non-consumed flag args remain...
	// Add them to xer_files if they are XERs (even if we specified some with -f)
	if fp.args.len > 0 {
		// remaining non flag args are files (or should be)
		for file in fp.args {
			if file.ends_with('.xer') {
				xer_files << file
			}
		}
	}

	// All fp args were consumed....
	// No XER list of files was specified....
	// So do all XERs in directory
	if fp.args.len == 0 && xer_arg.len == 0 {
		dir_elems := os.ls('.') or {
			println('Could not get list of files in directory. Aborting')
			return
		}
		for file in dir_elems {
			if file.ends_with('.xer') {
				xer_files << file
			}
		}
		xer_files.sort()
	}

	if consolidated_arg == false && append_arg == false && sql_arg == false
		&& individual_arg == false {
		println("[ERROR] You must use at least one of the flags '-i','-a','-c','s'.")
		exit(0)
	}

	println('Running on files: $xer_files')

	if consolidated_arg {
		print('Generating Consolidated...       ')
		flush_stdout()
		generate_master_table(xer_files)
		println('[Done]')
		flush_stdout()
	}

	if append_arg {
		print('Generating Appended...           ')
		flush_stdout()
		generate_appended(xer_files)
		println('[Done]')
		flush_stdout()
	}

	if sql_arg {
		println('Generating SQLite...           ')
		generate_database(xer_files)
		println('... [Done]')
	}

	if individual_arg {
		print('Generating Individuals....       ')
		generate_individuals(xer_files)
		println('[Done]')
	}
}

fn generate_individuals(xer_files []string) {
	for index, _ in xer_files {
		lines := os.read_lines(xer_files[index]) or { panic(err) }

		dir_name := os.file_name(xer_files[index].all_before_last('.xer'))

		os.mkdir(dir_name) or {} // Okay if dir exists.

		mut line_index := 0
		mut table_header := ''

		for i := line_index; i < lines.len; i++ {
			line_index++
			if lines[i].starts_with('%T') {
				table_header = lines[i].find_between('%T\t', '\n')
				mut file_out := os.create(dir_name + '/' + table_header + '.txt') or { panic(err) }

				for j := line_index; j < lines.len; j++ {
					// reached new table
					if lines[j].starts_with('%T') {
						file_out.close()
						break
					}
					file_out.writeln(lines[j]) or { panic(err) }
				}
			}
		}
	}
}

fn generate_appended(xer_files []string) {
	dir_name := 'combined'

	// Check if combined dir already exists, and if so, remove it
	if os.exists(dir_name) {
		os.rmdir_all(dir_name) or {
			println("Failed to deleted existing 'combined' directory.\nResults will be appended to existing.")
		}
	}

	os.mkdir(dir_name) or {}

	for index, filename in xer_files {
		lines := os.read_lines(xer_files[index]) or { panic(err) }

		mut line_index := 0
		mut table_header := ''

		for i := line_index; i < lines.len; i++ {
			line_index++
			if lines[i].starts_with('%T') {
				table_header = lines[i].find_between('%T\t', '\n')

				mut file_out := os.File{}
				if os.exists(dir_name + '/' + table_header + '.txt') == false {
					file_out = os.create(dir_name + '/' + table_header + '.txt') or { panic(err) }
				} else {
					file_out = os.open_append(dir_name + '/' + table_header + '.txt') or {
						panic(err)
					}
				}

				for j := line_index; j < lines.len; j++ {
					// reached new table
					if lines[j].starts_with('%T') {
						file_out.close()
						break
					}
					file_out.writeln('$filename\t${lines[j]}') or {}
				}
			}
		}
	}
}

fn generate_master_table(xer_files []string) {
	mut file_out := os.create('xerdump_consolidated.txt') or { panic(err) }

	defer {
		file_out.close()
	}

	for xer_file in xer_files {
		map_actvtype := xer.parse_actvtype(xer_file) or {
			eprintln("[ERROR] Could not parse ACTVTYPE table in '$xer_file'. Skipping")
			continue
		}
		map_actvcode := xer.parse_actvcode(xer_file) or {
			eprintln("[ERROR] Could not parse ACTVCODE table in '$xer_file'. Skipping")
			continue
		}
		map_task := xer.parse_task_idkey(xer_file) or {
			eprintln("[ERROR] Could not parse TASK table in '$xer_file'. Skipping")
			continue
		}

		// parse_taskactv will sort based on actv_code_type_id, actv_code_id.
		arr_taskactv := xer.parse_taskactv(xer_file) or {
			eprintln("[ERROR] Could not parse TASKACTV table in '$xer_file'. Skipping")
			continue
		}

		// xer_filename,task_id,actv_code_type_id,actv_code_id,proj_id
		for task in arr_taskactv {
			actv_code_type := map_actvtype[task.actv_code_type_id].actv_code_type
			actv_code_name := map_actvcode[task.actv_code_id].actv_code_name
			short_name := map_actvcode[task.actv_code_id].short_name

			file_out.write_string('$xer_file\t$actv_code_type\t$actv_code_name\t$short_name') or {
				panic(err)
			}

			data_arr := map_task[task.task_id].to_array()

			for elem in data_arr[1..] {
				file_out.write_string('\t$elem') or { panic(err) }
			}

			file_out.writeln('') or { panic(err) }
		}
	}
}

// Generate an SQLite database from XER files.
// Does not rely on XER library to generate.
fn generate_database(xer_files []string) {
	print('\tCompiling INSERT commands...       ')
	mut sql_tables := ['TASK', 'PROJECT', 'CALENDAR', 'TASKPRED', 'TASKACTV', 'ACTVCODE', 'ACTVTYPE']

	mut sql_cmds := []string{}
	for filename in xer_files {
		lines := os.read_lines(filename) or {
			println('\nError reading file. Perhaps it does not exist? Skipped.')
			continue
		}
		mut line_index := 0
		mut delimited_row := []string{}

		mut insert_str := ''

		for line in lines {
			line_index++

			if !line.starts_with('%T') {
				continue
			}

			for table_name in sql_tables {
				if compare_strings(line, '%T\t$table_name') == 0 {
					// Skip header.
					line_index++
					for i := line_index; i < lines.len; i++ {
						if lines[i].starts_with('%T') {
							break
						}
						delimited_row = lines[i].split('\t')

						// Replace %F %R nonsense in XER with the filename...
						delimited_row[0] = filename

						insert_str = 'insert into $table_name values ('
						for elem in delimited_row {
							insert_str += "'$elem',"
						}
						insert_str = insert_str.all_before_last(',')
						insert_str += ')'

						sql_cmds << insert_str
					}
				}
			}
		}
	}
	println('[DONE]')

	// Check if database exists, and if so, remove it
	if os.exists('primavera.db') {
		println('\tDeleting existing datase....       [DONE]')
		os.rm('primavera.db') or {
			println('\tFailed to remove primavera.db. Aborting.')
			return
		}
	}
	db := sqlite.connect('primavera.db') or {
		println('\tError! Could not open database.')
		return
	}

	// Primary key for tables is combination of xer_filename and the p6-unique-id for the specific table
	// As collating multiple XER files may result in repeated identifiers.
	print('\tExecuting CREATE TABLE commands... ')
	db.exec('CREATE TABLE `TASK` (`xer_filename` TEXT, `task_id` TEXT, `proj_id` TEXT, `wbs_id` TEXT, `clndr_id` TEXT, `phys_complete_pct` TEXT, `rev_fdbk_flag` TEXT, `est_wt` TEXT, `lock_plan_flag` TEXT, `auto_compute_act_flag` TEXT, `complete_pct_type` TEXT, `task_type` TEXT, `duration_type` TEXT, `status_code` TEXT, `task_code` TEXT, `task_name` TEXT, `rsrc_id` TEXT, `total_float_hr_cnt` TEXT, `free_float_hr_cnt` TEXT, `remain_drtn_hr_cnt` TEXT, `act_work_qty` TEXT, `remain_work_qty` TEXT, `target_work_qty` TEXT, `target_drtn_hr_cnt` TEXT, `target_equip_qty` TEXT, `act_equip_qty` TEXT, `remain_equip_qty` TEXT, `cstr_date` TEXT, `act_start_date` TEXT, `act_end_date` TEXT, `late_start_date` TEXT, `late_end_date` TEXT, `expect_end_date` TEXT, `early_start_date` TEXT, `early_end_date` TEXT, `restart_date` TEXT, `reend_date` TEXT, `target_start_date` TEXT, `target_end_date` TEXT, `rem_late_start_date` TEXT, `rem_late_end_date` TEXT, `cstr_type` TEXT, `priority_type` TEXT, `suspend_date` TEXT, `resume_date` TEXT, `float_path` TEXT, `float_path_order` TEXT, `guid` TEXT, `tmpl_guid` TEXT, `cstr_date2` TEXT, `cstr_type2` TEXT, `driving_path_flag` TEXT, `act_this_per_work_qty` TEXT, `act_this_per_equip_qty` TEXT, `external_early_start_date` TEXT, `external_late_end_date` TEXT, `cbs_id` TEXT, `pre_pess_start_date` TEXT, `pre_pess_finish_date` TEXT, `post_pess_start_date` TEXT, `post_pess_finish_date` TEXT, `create_date` TEXT, `update_date` TEXT, `create_user` TEXT, `update_user` TEXT, `location_id` TEXT, `control_updates_flag` TEXT, PRIMARY KEY(`xer_filename`,`task_id`))')
	db.exec('CREATE TABLE `PROJECT` (`xer_filename` TEXT, `proj_id` TEXT, `fy_start_month_num` TEXT, `rsrc_self_add_flag` TEXT, `allow_complete_flag` TEXT, `rsrc_multi_assign_flag` TEXT, `checkout_flag` TEXT, `project_flag` TEXT, `step_complete_flag` TEXT, `cost_qty_recalc_flag` TEXT, `batch_sum_flag` TEXT, `name_sep_char` TEXT, `def_complete_pct_type` TEXT, `proj_short_name` TEXT, `acct_id` TEXT, `orig_proj_id` TEXT, `source_proj_id` TEXT, `base_type_id` TEXT, `clndr_id` TEXT, `sum_base_proj_id` TEXT, `task_code_base` TEXT, `task_code_step` TEXT, `priority_num` TEXT, `wbs_max_sum_level` TEXT, `strgy_priority_num` TEXT, `last_checksum` TEXT, `critical_drtn_hr_cnt` TEXT, `def_cost_per_qty` TEXT, `last_recalc_date` TEXT, `plan_start_date` TEXT, `plan_end_date` TEXT, `scd_end_date` TEXT, `add_date` TEXT, `last_tasksum_date` TEXT, `fcst_start_date` TEXT, `def_duration_type` TEXT, `task_code_prefix` TEXT, `guid` TEXT, `def_qty_type` TEXT, `add_by_name` TEXT, `web_local_root_path` TEXT, `proj_url` TEXT, `def_rate_type` TEXT, `add_act_remain_flag` TEXT, `act_this_per_link_flag` TEXT, `def_task_type` TEXT, `act_pct_link_flag` TEXT, `critical_path_type` TEXT, `task_code_prefix_flag` TEXT, `def_rollup_dates_flag` TEXT, `use_project_baseline_flag` TEXT, `rem_target_link_flag` TEXT, `reset_planned_flag` TEXT, `allow_neg_act_flag` TEXT, `sum_assign_level` TEXT, `last_fin_dates_id` TEXT, `last_baseline_update_date` TEXT, `cr_external_key` TEXT, `apply_actuals_date` TEXT, `matrix_id` TEXT, `last_level_date` TEXT, `last_schedule_date` TEXT, `px_enable_publication_flag` TEXT, `px_last_update_date` TEXT, `px_priority` TEXT, `control_updates_flag` TEXT, `hist_interval` TEXT, `hist_level` TEXT, `schedule_type` TEXT, `location_id` TEXT, `loaded_scope_level` TEXT, `export_flag` TEXT, `new_fin_dates_id` TEXT, `baselines_to_export` TEXT, `baseline_names_to_export` TEXT, `sync_wbs_heir_flag` TEXT, `sched_wbs_heir_type` TEXT, `wbs_heir_levels` TEXT, `next_data_date` TEXT, `close_period_flag` TEXT, `sum_refresh_date` TEXT, `trsrcsum_loaded` TEXT, PRIMARY KEY(`xer_filename`,`proj_id`))')
	db.exec('CREATE TABLE `CALENDAR` (`xer_filename` TEXT, `clndr_id` TEXT, `default_flag` TEXT, `clndr_name` TEXT, `proj_id` TEXT, `base_clndr_id` TEXT, `last_chng_date` TEXT, `clndr_type` TEXT, `day_hr_cnt` TEXT, `week_hr_cnt` TEXT, `month_hr_cnt` TEXT, `year_hr_cnt` TEXT, `rsrc_private` TEXT, `clndr_data` TEXT, PRIMARY KEY(`xer_filename`,`clndr_id`))')
	db.exec('CREATE TABLE `TASKPRED` (`xer_filename` TEXT, `task_pred_id` TEXT, `task_id` TEXT, `pred_task_id` TEXT, `proj_id` TEXT, `pred_proj_id` TEXT, `pred_type` TEXT, `lag_hr_cnt` TEXT, `float_path` TEXT, `aref` TEXT, `arls` TEXT, PRIMARY KEY(`xer_filename`,`task_pred_id`))')
	db.exec('CREATE TABLE `TASKACTV` (`xer_filename` TEXT, `task_id` TEXT, `actv_code_type_id` TEXT, `actv_code_id` TEXT, `proj_id` TEXT)')
	db.exec('CREATE TABLE `ACTVCODE` (`xer_filename` TEXT, `actv_code_id` TEXT, `parent_actv_code_id` TEXT, `actv_code_type_id` TEXT, `actv_code_name` TEXT, `short_name` TEXT, `seq_num` TEXT, `color` TEXT, `total_assignments` TEXT, PRIMARY KEY(`xer_filename`,`actv_code_id`))')
	db.exec('CREATE TABLE `ACTVTYPE` (`xer_filename` TEXT, `actv_code_type_id` TEXT, `actv_short_len` TEXT, `seq_num` TEXT, `actv_code_type` TEXT, `proj_id` TEXT, `wbs_id` TEXT, `actv_code_type_scope` TEXT, PRIMARY KEY(`xer_filename`,`actv_code_type_id`))')
	println('[DONE]')

	db.synchronization_mode(sqlite.SyncMode.off)
	db.journal_mode(sqlite.JournalMode.off)

	print('\tExecuting INSERT commands...       ')
	println('')

	cnt_sql := sql_cmds.len
	for idx, command in sql_cmds {
		if idx % 10000 == 0 {
			print('\e[1A') // Move cursor up one row.
			print('\e[2K') // Erase entire current line.
			println('\tInserting...                       [${f64(idx) / cnt_sql * 100.0:0.1f}%]')
		}
		db.exec_none('$command')
	}
	print('\e[1A') // Move cursor up one row.
	print('\e[2K') // Erase entire current line.
	println('\t[DONE EXECUTION]')
}

// fn C.sqlite3_exec(&C.sqlite3,&char,voidptr,voidptr,&&errmsg) int

// pub fn (db DB) fast_exec(query string) int {

// 	code := C.sqlite3_exec(db.conn,&char(query.str),C.NULL,C.NULL,C.NULL)

// 	return code
// }
