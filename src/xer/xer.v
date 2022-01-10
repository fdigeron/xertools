// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
module xer
import os

pub const(
	 task_header = "task_id\tproj_id\twbs_id\t\
		clndr_id\tphys_complete_pct\trev_fdbk_flag\test_wt\tlock_plan_flag\t\
		auto_compute_act_flag\tcomplete_pct_type\ttask_type\tduration_type\t\
		status_code\ttask_code\ttask_name\trsrc_id\ttotal_float_hr_cnt\t\
		free_float_hr_cnt\tremain_drtn_hr_cnt\tact_work_qty\tremain_work_qty\t\
		target_work_qty\ttarget_drtn_hr_cnt\ttarget_equip_qty\tact_equip_qty\t\
		remain_equip_qty\tcstr_date\tact_start_date\tact_end_date\t\
		late_start_date\tlate_end_date\texpect_end_date\tearly_start_date\t\
		early_end_date\trestart_date\treend_date\ttarget_start_date\t\
		target_end_date\trem_late_start_date\trem_late_end_date\t\
		cstr_type\tpriority_type\tsuspend_date\tresume_date\tfloat_path\t\
		float_path_order\tguid\ttmpl_guid\tcstr_date2\tcstr_type2\t\
		driving_path_flag\tact_this_per_work_qty\tact_this_per_equip_qty\t\
		external_early_start_date\texternal_late_end_date\tcbs_id\t\
		pre_pess_start_date\tpre_pess_finish_date\tpost_pess_start_date\t\
		post_pess_finish_date\tcreate_date\tupdate_date\tcreate_user\t\
		update_user\tlocation_id\tcontrol_updates_flag\t\task_code\ttask_name"
)

pub fn parse_task(xer_file string) XER_task_map
{
	lines := os.read_lines(xer_file) or {panic(err)}
	mut line_index := 0
	mut delimited_row := []string{}
	mut xer_table := XER_task_map{}

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
				xer_struct.xer_filename = xer_file
				xer_struct.task_id = delimited_row[1]
				xer_struct.proj_id = delimited_row[2]
				xer_struct.wbs_id = delimited_row[3]
				xer_struct.clndr_id = delimited_row[4]
				xer_struct.phys_complete_pct = delimited_row[5]
				xer_struct.rev_fdbk_flag = delimited_row[6]
				xer_struct.est_wt = delimited_row[7]
				xer_struct.lock_plan_flag = delimited_row[8]
				xer_struct.auto_compute_act_flag = delimited_row[9]
				xer_struct.complete_pct_type = delimited_row[10]
				xer_struct.task_type = delimited_row[11]
				xer_struct.duration_type = delimited_row[12]
				xer_struct.status_code = delimited_row[13]
				xer_struct.task_code = delimited_row[14]
				xer_struct.task_name = delimited_row[15]
				xer_struct.rsrc_id = delimited_row[16]
				xer_struct.total_float_hr_cnt = delimited_row[17]
				xer_struct.free_float_hr_cnt = delimited_row[18]
				xer_struct.remain_drtn_hr_cnt = delimited_row[19]
				xer_struct.act_work_qty = delimited_row[20]
				xer_struct.remain_work_qty = delimited_row[21]
				xer_struct.target_work_qty = delimited_row[22]
				xer_struct.target_drtn_hr_cnt = delimited_row[23]
				xer_struct.target_equip_qty = delimited_row[24]
				xer_struct.act_equip_qty = delimited_row[25]
				xer_struct.remain_equip_qty = delimited_row[26]
				xer_struct.cstr_date = delimited_row[27]
				xer_struct.act_start_date = delimited_row[28]
				xer_struct.act_end_date = delimited_row[29]
				xer_struct.late_start_date = delimited_row[30]
				xer_struct.late_end_date = delimited_row[31]
				xer_struct.expect_end_date = delimited_row[32]
				xer_struct.early_start_date = delimited_row[33]
				xer_struct.early_end_date = delimited_row[34]
				xer_struct.restart_date = delimited_row[35]
				xer_struct.reend_date = delimited_row[36]
				xer_struct.target_start_date = delimited_row[37]
				xer_struct.target_end_date = delimited_row[38]
				xer_struct.rem_late_start_date = delimited_row[39]
				xer_struct.rem_late_end_date = delimited_row[40]
				xer_struct.cstr_type = delimited_row[41]
				xer_struct.priority_type = delimited_row[42]
				xer_struct.suspend_date = delimited_row[43]
				xer_struct.resume_date = delimited_row[44]
				xer_struct.float_path = delimited_row[45]
				xer_struct.float_path_order = delimited_row[46]
				xer_struct.guid = delimited_row[47]
				xer_struct.tmpl_guid = delimited_row[48]
				xer_struct.cstr_date2 = delimited_row[49]
				xer_struct.cstr_type2 = delimited_row[50]
				xer_struct.driving_path_flag = delimited_row[51]
				xer_struct.act_this_per_work_qty = delimited_row[52]
				xer_struct.act_this_per_equip_qty = delimited_row[53]
				xer_struct.external_early_start_date = delimited_row[54]
				xer_struct.external_late_end_date = delimited_row[55]
				xer_struct.cbs_id = delimited_row[56]
				xer_struct.pre_pess_start_date = delimited_row[57]
				xer_struct.pre_pess_finish_date = delimited_row[58]
				xer_struct.post_pess_start_date = delimited_row[59]
				xer_struct.post_pess_finish_date = delimited_row[60]
				xer_struct.create_date = delimited_row[61]
				xer_struct.update_date = delimited_row[62]
				xer_struct.create_user = delimited_row[63]
				xer_struct.update_user = delimited_row[64]
				xer_struct.location_id = delimited_row[65]
				xer_struct.control_updates_flag = delimited_row[66]

				// Map index of task_code, assigned to struct
				xer_table.xer_map[delimited_row[14]] = xer_struct 
			}
		}
	}
	return xer_table
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

pub fn (task_row XER_task) xer_task_array() []string
{
	mut ret_str := []string{}
	ret_str << task_row.xer_filename
	ret_str << task_row.task_id
	ret_str << task_row.proj_id
	ret_str << task_row.wbs_id
	ret_str << task_row.clndr_id
	ret_str << task_row.phys_complete_pct
	ret_str << task_row.rev_fdbk_flag
	ret_str << task_row.est_wt
	ret_str << task_row.lock_plan_flag
	ret_str << task_row.auto_compute_act_flag
	ret_str << task_row.complete_pct_type
	ret_str << task_row.task_type
	ret_str << task_row.duration_type
	ret_str << task_row.status_code
	ret_str << task_row.task_code
	ret_str << task_row.task_name
	ret_str << task_row.rsrc_id
	ret_str << task_row.total_float_hr_cnt
	ret_str << task_row.free_float_hr_cnt
	ret_str << task_row.remain_drtn_hr_cnt
	ret_str << task_row.act_work_qty
	ret_str << task_row.remain_work_qty
	ret_str << task_row.target_work_qty
	ret_str << task_row.target_drtn_hr_cnt
	ret_str << task_row.target_equip_qty
	ret_str << task_row.act_equip_qty
	ret_str << task_row.remain_equip_qty
	ret_str << task_row.cstr_date
	ret_str << task_row.act_start_date
	ret_str << task_row.act_end_date
	ret_str << task_row.late_start_date
	ret_str << task_row.late_end_date
	ret_str << task_row.expect_end_date
	ret_str << task_row.early_start_date
	ret_str << task_row.early_end_date
	ret_str << task_row.restart_date
	ret_str << task_row.reend_date
	ret_str << task_row.target_start_date
	ret_str << task_row.target_end_date
	ret_str << task_row.rem_late_start_date
	ret_str << task_row.rem_late_end_date
	ret_str << task_row.cstr_type
	ret_str << task_row.priority_type
	ret_str << task_row.suspend_date
	ret_str << task_row.resume_date
	ret_str << task_row.float_path
	ret_str << task_row.float_path_order
	ret_str << task_row.guid
	ret_str << task_row.tmpl_guid
	ret_str << task_row.cstr_date2
	ret_str << task_row.cstr_type2
	ret_str << task_row.driving_path_flag
	ret_str << task_row.act_this_per_work_qty
	ret_str << task_row.act_this_per_equip_qty
	ret_str << task_row.external_early_start_date
	ret_str << task_row.external_late_end_date
	ret_str << task_row.cbs_id
	ret_str << task_row.pre_pess_start_date
	ret_str << task_row.pre_pess_finish_date
	ret_str << task_row.post_pess_start_date
	ret_str << task_row.post_pess_finish_date
	ret_str << task_row.create_date
	ret_str << task_row.update_date
	ret_str << task_row.create_user
	ret_str << task_row.update_user
	ret_str << task_row.location_id
	ret_str << task_row.control_updates_flag

	return ret_str
}

struct XER_task_map
{
	pub mut:
		xer_map map[string]XER_task
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