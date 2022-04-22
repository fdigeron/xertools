// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
import os
import x.json2

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

		// JSON2 vars
		mut me := map[string]json2.Any{}
		mut xer_row := map[string]json2.Any{}
    	mut xer_rows := []json2.Any{}

		mut line_index := 0
		mut header_arr := []string{}

		for i:=line_index; i<lines.len; i++
		{
			line_index++
			if lines[i].starts_with("%T")
			{
				table_name := lines[i].find_between("%T\t","\n")
				println("\t\tTABLE: $table_name")
				
				for j:=line_index; j<lines.len; j++
				{
					if lines[j].starts_with("%T") // reached new table
					{
						break
					}
					else if lines[j].starts_with("%E") // reached end of file
					{
						break
					}

					if j == line_index // at the header
					{
						header_arr = lines[j].split("\t")
						continue
					}

					// If fell down here it is data for this header...
					line_arr := lines[j].split("\t")

					for idx, elem in header_arr
					{	
						if is_ascii(line_arr[idx])
						{
							xer_row[elem] = line_arr[idx]
						}
						else
						{
							xer_row[elem] = "non-ascii"
						}
					}

					xer_rows << xer_row
					xer_row = map[string]json2.Any{}
				}

				me[table_name] = xer_rows
				xer_rows = []json2.Any{}
			}
		}

		print("[Writing JSON].... ")
		
		// Done walking this XER
		xer_name := xer_files[index].all_before_last(".xer")
		mut json_out := os.create(xer_name + ".json") or {panic(err)}
		json_out.writeln(me.str()) or {panic(err)}
		json_out.close()

		println("[Done]\n")
	}

	println("[Done Batch]")
	println("")
}

fn is_ascii(s string) bool 
{
    for char in s 
	{
        if char > 127 {
            return false
        }
    }
    return true
}