// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
module xer
import os

pub fn parse_task(xer_file string) map[string]XER_task
{
	lines := os.read_lines(xer_file) or {panic(err)}
	mut line_index := 0
	mut delimited_row := []string{}
	mut xer_table := map[string]XER_task{}

	for line in lines
	{
		line_index++
		if compare_strings(line,"%T\tTASK") == 0
		{
			line_index++ // Skip header.
			for i:=line_index; i<lines.len; i++
			{
				if lines[i].starts_with("%T")
				{
					return xer_table
				}
				delimited_row = lines[i].split("\t")
				
				mut xer_struct := XER_task{}
				mut loop := 0
				$for field in XER_task.fields // Reflection
				{
					$if field.typ is string // Required check for compiler.
					{
						xer_struct.$(field.name) = delimited_row[loop]
						loop++
					}
				}
				xer_struct.xer_filename = xer_file

				// Map index of task_code, assigned to struct
				xer_table[delimited_row[14]] = xer_struct 
			}
		}
	}
	return xer_table
}

pub fn parse_project(xer_file string) map[string]XER_project
{
	lines := os.read_lines(xer_file) or {panic(err)}
	mut line_index := 0
	mut delimited_row := []string{}
	mut xer_table := map[string]XER_project{}

	for line in lines
	{
		line_index++
		if compare_strings(line,"%T\tPROJECT") == 0
		{
			line_index++ // Skip header.
			for i:=line_index; i<lines.len; i++
			{
				if lines[i].starts_with("%T")
				{
					return xer_table
				}
				delimited_row = lines[i].split("\t")
				
				mut xer_struct := XER_project{}
				mut loop := 0
				$for field in XER_project.fields // Reflection
				{
					$if field.typ is string // Required check for compiler.
					{
						xer_struct.$(field.name) = delimited_row[loop]
						loop++
					}
				}
				xer_struct.xer_filename = xer_file
				
				// Map index of task_code, assigned to struct
				// Key is the proj_id
				xer_table[delimited_row[1]] = xer_struct 
			}
		}
	}
	return xer_table
}

pub fn parse_calendar(xer_file string) map[string]XER_calendar
{
	lines := os.read_lines(xer_file) or {panic(err)}
	mut line_index := 0
	mut delimited_row := []string{}
	mut xer_table := map[string]XER_calendar{}

	for line in lines
	{
		line_index++
		if compare_strings(line,"%T\tCALENDAR") == 0
		{
			line_index++ // Skip header.
			for i:=line_index; i<lines.len; i++
			{
				if lines[i].starts_with("%T")
				{
					return xer_table
				}
				delimited_row = lines[i].split("\t")
				
				mut xer_struct := XER_calendar{}
				mut loop := 0
				$for field in XER_calendar.fields // Reflection
				{
					$if field.typ is string // Required check for compiler.
					{
						xer_struct.$(field.name) = delimited_row[loop]
						loop++
					}
				}
				xer_struct.xer_filename = xer_file

				// Map index of task_code, assigned to struct
				xer_table[delimited_row[1]] = xer_struct 
			}
		}
	}
	return xer_table
}

// Return the struct XER_calendar as a string array.
pub fn (t XER_calendar) to_array() []string
{
	mut res := []string{}
	$for field in XER_calendar.fields
	{
		$if field.typ is string
		{
			res << t.$(field.name).str()
		}
	}
	return res
}

// Return the struct XER_project as a string array.
pub fn (t XER_project) to_array() []string
{
	mut res := []string{}
	$for field in XER_project.fields
	{
		$if field.typ is string
		{
			res << t.$(field.name).str()
		}
	}
	return res
}

// Return the struct XER_task as a string array.
pub fn (t XER_task) to_array() []string
{
	mut res := []string{}
	$for field in XER_task.fields
	{
		$if field.typ is string
		{
			res << t.$(field.name).str()
		}
	}
	return res
}

// Returns tab delimited string from array
pub fn array_to_tab(array []string) string
{
	mut ret_str := ""
	for elem in array
	{
		ret_str += "$elem\t"
	}
	return ret_str.all_before_last("\t")
}

// XER calendar header, tab delimited
pub fn calendar_header() string
{
	mut res := ""
	$for field in XER_calendar.fields
	{
		res += "${field.name}\t"
	}
	return res.all_before_last("\t")
}

// XER project header, tab delimited
pub fn project_header() string
{
	mut res := ""
	$for field in XER_project.fields
	{
		res += "${field.name}\t"
	}
	return res.all_before_last("\t")
}

// XER task header, tab delimited
pub fn task_header() string
{
	mut res := ""
	$for field in XER_task.fields
	{
		res += "${field.name}\t"
	}
	return res.all_before_last("\t")
}

// Print the CALENDAR header starting from specified index.
pub fn print_calendar_header(start_idx int)
{
	print("\
		[CALENDAR]\n\
		INDEX\tLABEL\n\
		-----------------\n\
		")

	mut loop := 0

	$for field in XER_calendar.fields
	{
		println("${loop+start_idx}\t$field.name")
		loop++
	}
}

// Print the PROJECT header starting from specified index.
pub fn print_project_header(start_idx int)
{
	print("\
		[PROJECT]\n\
		INDEX\tLABEL\n\
		-----------------\n\
		")

	mut loop := 0
	$for field in XER_project.fields
	{
		println("${loop+start_idx}\t$field.name")
		loop++
	}
}

// Print the TASK header starting from specified index.
pub fn print_task_header(start_idx int)
{
	print("\
		[TASK]\n\
		INDEX\tLABEL\n\
		-----------------\n\
		")

	mut loop := 0
	$for field in XER_task.fields
	{
		println("${loop+start_idx}\t$field.name")
		loop++
	}
}

////////////////////////////////
//// XER struct definitions ////
////////////////////////////////
struct XER_calendar
{
	pub mut:
		xer_filename string
		clndr_id string
		default_flag string
		clndr_name string
		proj_id string
		base_clndr_id string
		last_chng_date string
		clndr_type string
		day_hr_cnt string
		week_hr_cnt string
		month_hr_cnt string
		year_hr_cnt string
		rsrc_private string
		clndr_data string
}

struct XER_task
{
	pub mut:
	 xer_filename string
	 task_id string
	 proj_id string
	 wbs_id string
	 clndr_id string
	 phys_complete_pct string
	 rev_fdbk_flag string
	 est_wt string
	 lock_plan_flag string
	 auto_compute_act_flag string
	 complete_pct_type string
	 task_type string
	 duration_type string
	 status_code string
	 task_code string
	 task_name string
	 rsrc_id string
	 total_float_hr_cnt string
	 free_float_hr_cnt string
	 remain_drtn_hr_cnt string
	 act_work_qty string
	 remain_work_qty string
	 target_work_qty string
	 target_drtn_hr_cnt string
	 target_equip_qty string
	 act_equip_qty string
	 remain_equip_qty string
	 cstr_date string
	 act_start_date string
	 act_end_date string
	 late_start_date string
	 late_end_date string
	 expect_end_date string
	 early_start_date string
	 early_end_date string
	 restart_date string
	 reend_date string
	 target_start_date string
	 target_end_date string
	 rem_late_start_date string
	 rem_late_end_date string
	 cstr_type string
	 priority_type string
	 suspend_date string
	 resume_date string
	 float_path string
	 float_path_order string
	 guid string
	 tmpl_guid string
	 cstr_date2 string
	 cstr_type2 string
	 driving_path_flag string
	 act_this_per_work_qty string
	 act_this_per_equip_qty string
	 external_early_start_date string
	 external_late_end_date string
	 cbs_id string
	 pre_pess_start_date string
	 pre_pess_finish_date string
	 post_pess_start_date string
	 post_pess_finish_date string
	 create_date string
	 update_date string
	 create_user string
	 update_user string
	 location_id string
	 control_updates_flag string
}

struct XER_project
{
	pub mut:
		xer_filename string
		proj_id string
		fy_start_month_num string
		rsrc_self_add_flag string
		allow_complete_flag string
		rsrc_multi_assign_flag string
		checkout_flag string
		project_flag string
		step_complete_flag string
		cost_qty_recalc_flag string
		batch_sum_flag string
		name_sep_char string
		def_complete_pct_type string
		proj_short_name string
		acct_id string
		orig_proj_id string
		source_proj_id string
		base_type_id string
		clndr_id string
		sum_base_proj_id string
		task_code_base string
		task_code_step string
		priority_num string
		wbs_max_sum_level string
		strgy_priority_num string
		last_checksum string
		critical_drtn_hr_cnt string
		def_cost_per_qty string
		last_recalc_date string
		plan_start_date string
		plan_end_date string
		scd_end_date string
		add_date string
		last_tasksum_date string
		fcst_start_date string
		def_duration_type string
		task_code_prefix string
		guid string
		def_qty_type string
		add_by_name string
		web_local_root_path string
		proj_url string
		def_rate_type string
		add_act_remain_flag string
		act_this_per_link_flag string
		def_task_type string
		act_pct_link_flag string
		critical_path_type string
		task_code_prefix_flag string
		def_rollup_dates_flag string
		use_project_baseline_flag string
		rem_target_link_flag string
		reset_planned_flag string
		allow_neg_act_flag string
		sum_assign_level string
		last_fin_dates_id string
		last_baseline_update_date string
		cr_external_key string
		apply_actuals_date string
		matrix_id string
		last_level_date string
		last_schedule_date string
		px_enable_publication_flag string
		px_last_update_date string
		px_priority string
		control_updates_flag string
		hist_interval string
		hist_level string
		schedule_type string
		location_id string
		loaded_scope_level string
		export_flag string
		new_fin_dates_id string
		baselines_to_export string
		baseline_names_to_export string
		sync_wbs_heir_flag string
		sched_wbs_heir_type string
		wbs_heir_levels string
		next_data_date string
		close_period_flag string
		sum_refresh_date string
		trsrcsum_loaded string
}
