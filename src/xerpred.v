// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
import os
import flag
import xer
import time

fn main()
{
	mut fp := flag.new_flag_parser(os.args)
    fp.application('xerpred')
	
    fp.version('v2022.02.24\nCopyright (c) 2022 jeffrey -at- ieee.org. All rights \
	reserved.\nUse of this source code (/program) is governed by an MIT \
	license,\nthat can be found in the LICENSE file.')

    fp.description('\nLogic-traces all the XER predecessor line items.\n\
	Output is of [parent-node]->[child-node] relations, up to specified depth.\n\
	This software will -NOT- make any changes to your XER files.')

    fp.skip_executable()

    mut xer_arg := fp.string('xer', `f`, "", 
								'specify the XER for analysis')
	mut minimal_output_arg := fp.bool('minimal', `m`, false, 
								'output only task-id records')
	mut max_levels_arg := fp.int('depth', `l`, 5, 
	'specify max predecessor depth [default:5]')
	mut drivers_arg := fp.bool('drivers', `d`, false, 
	'output schedule drivers and exit')
										
	additional_args := fp.finalize() or {
        eprintln(err)
        println(fp.usage())
        return
    }

	additional_args.join_lines()
	
	if xer_arg.len==0
	{
		eprintln("[ERROR] You must specify an XER file for analysis.\nSee usage below.\n")
		println(fp.usage())
		exit(0)
		return
	}		

	if drivers_arg
	{
		print_drivers(xer_arg)
	}

	lines := os.read_lines(xer_arg) or {panic(err)}
		
	mut line_index := 0

	mut pred_map := map[string][]string

	for line in lines
	{	
		line_index++
		if compare_strings(line,"%T\tTASKPRED") == 0
		{
			line_index++ // Advance passed header...

			for i:=line_index; i<lines.len; i++
			{
				if lines[i].starts_with("%T")
				{
					break
				}

				mut delimited_row := lines[i].split("\t")

				pred_map[delimited_row[2]] << delimited_row[3]
				
			}		
		}
	}

	mut tree_arr := []Tree{}

	for key,mut value in pred_map
	{
		recurse(mut tree_arr,pred_map,key, key,value,0,max_levels_arg)
	}

	tree_arr.sort(b.concat > a.concat)

	mut task_items := map[string] xer.XER_task
	if !minimal_output_arg
	{
		task_items = xer.parse_task_idkey(xer_arg)
	}

	// Print output Header....
	print("node\tdepth\tparent\tchild")
	if minimal_output_arg
	{
		println("")
	}
	else
	{
		print("\tnode_task_code\tnode_task_name\tparent_task_code\tparent_task_name\tchild_task_code\tchild_task_name\n")
	}


	for elem in tree_arr
	{
		
		print("${elem.task_id}\t${elem.depth}\t${elem.parent_node}\t${elem.child_node}")

		if minimal_output_arg
		{
			println("")
		}
		else
		{
			print("\t\
				 ${task_items[elem.task_id].task_code}\t\
				 ${task_items[elem.task_id].task_name}\t\
				 ${task_items[elem.parent_node].task_code}\t\
				 ${task_items[elem.parent_node].task_name}\t\
				 ${task_items[elem.child_node].task_code}\t\
				 ${task_items[elem.child_node].task_name}\
				 \n")
			}
	}
}

fn print_drivers(xer_file string)
{
	task_items := xer.parse_task_idkey(xer_file)
	pred_items := xer.parse_pred(xer_file)

	mut driver_map := map[string][]Drivers{}

	for _,value in pred_items
	{
		mut a_driver := Drivers{}
		a_driver.pred_task_id = value.pred_task_id
		a_driver.pred_type = value.pred_type
		a_driver.early_finish = value.aref
		a_driver.late_start = value.arls
		driver_map[value.task_id] << a_driver
	}


	println("task_id\t\
						driver_id\t\
						pred_type\t\
						task_code\t\
						task_name\t\
						driver_code\t\
						driver_name\t\
						pred_early_start\t\
						pred_early_end\t\
						pred_late_start\t\
						pred_late_end\t\
						succ_early_start\t\
						succ_early_end\t\
						succ_late_start\t\
						succ_late_end\t\
						rel_early_finish\t\
						rel_late_start\t\
						rel_free_float\
				")

	// key is the task_id in pred_map
	// key is the successor, 
	// value is []Drivers, are the predeccessors
	for key,mut value in driver_map
	{
		driver_threshold := 96
		// value is []Drivers
		for elem in value
		{
			mut rel_free_float := 0.00
			mut is_driver := false

			if compare_strings(elem.pred_type,"PR_FS")==0
			{
				// Worst case float is relationship early finish less pred late start....
				dc4 := time.parse("${elem.early_finish}:00") or {time.Time{}}
				dc3 := time.parse("${task_items[elem.pred_task_id].late_start_date}:00") or {time.Time{}}
				rel_free_float = (dc4 - dc3).hours()

				//Otherwise... early date of successor less relationship early finish
				if rel_free_float > driver_threshold || rel_free_float < 0
				{
					dc9 := time.parse("${task_items[key].early_start_date}:00") or {time.Time{}}
					dc10 := time.parse("${elem.early_finish}:00") or {time.Time{}}
					rel_free_float = (dc9 - dc10).hours()
				}
			}
			else if compare_strings(elem.pred_type,"PR_SS")==0
			{
				// Worst case float is relationship early finish less pred late start....
				dc4 := time.parse("${elem.early_finish}:00") or {time.Time{}}
				dc3 := time.parse("${task_items[elem.pred_task_id].late_start_date}:00") or {time.Time{}}
				rel_free_float = (dc4 - dc3).hours()

				//Otherwise... early date of successor less relationship early finish
				if rel_free_float > driver_threshold || rel_free_float < 0
				{
					dc12 := time.parse("${task_items[key].early_start_date}:00") or {time.Time{}}
					dc13 := time.parse("${elem.early_finish}:00") or {time.Time{}}
					rel_free_float = (dc12 - dc13).hours()

				}
			}
			else if compare_strings(elem.pred_type,"PR_SF")==0
			{
				dc7 := time.parse("${task_items[elem.pred_task_id].early_start_date}:00") or {time.Time{}}
				dc8 := time.parse("${task_items[key].early_end_date}:00") or {time.Time{}}
				rel_free_float = (dc8 - dc7).hours()

				//Otherwise... early date of successor less relationship early finish
				if rel_free_float > driver_threshold || rel_free_float < 0
				{
					dc12 := time.parse("${task_items[key].early_start_date}:00") or {time.Time{}}
					dc13 := time.parse("${elem.early_finish}:00") or {time.Time{}}
					rel_free_float = (dc12 - dc13).hours()

				}
			}
			else if compare_strings(elem.pred_type,"PR_FF")==0
			{
				dc7 := time.parse("${task_items[elem.pred_task_id].early_end_date}:00") or {time.Time{}}
				dc8 := time.parse("${task_items[key].early_end_date}:00") or {time.Time{}}
				rel_free_float = (dc8 - dc7).hours()

				//Otherwise... early date of successor less relationship early finish
				if rel_free_float > driver_threshold || rel_free_float < 0
				{
					dc12 := time.parse("${task_items[key].early_start_date}:00") or {time.Time{}}
					dc13 := time.parse("${elem.early_finish}:00") or {time.Time{}}
					rel_free_float = (dc12 - dc13).hours()

				}
			}

			if rel_free_float < driver_threshold && rel_free_float >= 0 
			{ 
				is_driver = true 
			}
			
			//$is_driver\t\
			if is_driver
			{
				println("$key\t\
						${elem.pred_task_id}\t\
						${elem.pred_type}\t\
						${task_items[key].task_code}\t\
						${task_items[key].task_name}\t\
						${task_items[elem.pred_task_id].task_code}\t\
						${task_items[elem.pred_task_id].task_name}\t\
						${task_items[elem.pred_task_id].early_start_date}\t\
						${task_items[elem.pred_task_id].early_end_date}\t\
						${task_items[elem.pred_task_id].late_start_date}\t\
						${task_items[elem.pred_task_id].late_end_date}\t\
						${task_items[key].early_start_date}\t\
						${task_items[key].early_end_date}\t\
						${task_items[key].late_start_date}\t\
						${task_items[key].late_end_date}\t\
						${elem.early_finish}\t\
						${elem.late_start}\t\
						$rel_free_float")
			}
		}
	}

	exit(0)
}

struct Drivers
{
	mut:
		pred_task_id string
		pred_type string
		early_finish string
		late_start string
}


fn recurse(mut tree []Tree,pred_map map[string][]string, root_key string, parent string,children []string,levels int,max_levels int)
{
	if children.len==1 || children.len==0
	{
		return
	}
	if levels == max_levels
	{
		return
	}

	//println("called level, $root_key, $children")
	for elem in children
	{
		//println("recurse $elem with child ${pred_map[elem]}")
		mut a_tree := Tree{}
		a_tree.concat = root_key + levels.str() // for sorting only
		a_tree.task_id = root_key
		a_tree.depth = levels
		a_tree.parent_node = parent
		a_tree.child_node = elem
		tree << a_tree

		recurse(mut tree,pred_map, root_key, elem, pred_map[elem],levels+1,max_levels)
	}
}

struct Tree
{
	mut:
	concat string // for sorting only.
	task_id string
	depth int
	parent_node string
	child_node string
}