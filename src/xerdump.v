// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
import os

fn main()
{
	dir_elems := os.ls(".") or {panic(err)}
	
	mut xer_files := []string{}

	println("Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.")
	println("Use of this source code (/program) is governed by an MIT license,")
	println("that can be found in the LICENSE file.")
	println("")
	
	for file in dir_elems
	{
		if file.ends_with(".xer")
		{
			xer_files << file
		}
	}

	for index,_ in xer_files
	{
		println("[Analyzing]  ${xer_files[index]}")

		lines := os.read_lines(xer_files[index]) or {panic(err)}

		dir_name := xer_files[index].all_before_last(".xer")
		os.mkdir(dir_name) or {} // Okay if dir exists.

		mut line_index := 0
		mut table_header := ""
		
		for i:=line_index; i<lines.len; i++
		{
			line_index++
			if lines[i].starts_with("%T")
			{
				table_header = lines[i].find_between("%T\t","\n")
				mut file_out := os.create(dir_name + "/" + 
									table_header + ".txt") or {panic(err)}
				
				for j:=line_index; j<lines.len; j++
				{
					if lines[j].starts_with("%T") // reached new table
					{
						file_out.close()
						break
					}
					file_out.writeln(lines[j]) ?
				}
			}
		}
	}

	println("[Done]")
	println("")
}