// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
import os
import flag

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
		recurse(mut tree_arr,pred_map,key, key,value,0)
	}

	tree_arr.sort(b.concat > a.concat)

	for elem in tree_arr
	{
		println("${elem.task_id}\t${elem.depth}\t${elem.parent_node}\t${elem.child_node}")
	}

}

fn recurse(mut tree []Tree,pred_map map[string][]string, root_key string, parent string,children []string,levels int)
{
	if children.len==1 || children.len==0
	{
		return
	}
	if levels == 5
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

		recurse(mut tree,pred_map, root_key, elem, pred_map[elem],levels+1)
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
