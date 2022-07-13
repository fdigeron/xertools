// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by a GPLV3 license,
// that can be found in the LICENSE file. Do not remove this header.
import os
import x.json2
import util
import flag

fn main() {
	mut pre_built_str := ''
	$if prebuilt ? {
		pre_built_str = '[pre-built binary release (##DATE##)]\n'
	}

	mut fp := flag.new_flag_parser(os.args)
	fp.application('xer2json')

	fp.version('${pre_built_str}Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.\nUse of this source code (/program) is governed by a GPLV3 license,\nthat can be found in the LICENSE file.')

	fp.description('\nConverts contents of XER to JSON format.\nThis software will -NOT- make any changes to your XER files.')

	fp.skip_executable()

	update_arg := fp.bool('update', `u`, false, 'check for tool updates')
	force_update_arg := fp.bool('force-update', `z`, false, 'check for tool updates, auto-install if available')

	additional_args := fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}

	additional_args.join_lines()

	if update_arg {
		mut force_mode := false
		if force_update_arg {
			force_mode = true
		}
		$if linux {
			util.github_update('chipnetics', 'xertools', 'xer2json', force_mode)
		} $else {
			util.github_update('chipnetics', 'xertools', 'xer2json.exe', force_mode)
		}
		return
	}

	dir_elems := os.ls('.') or { panic(err) }

	mut xer_files := []string{}

	for file in dir_elems {
		if file.ends_with('.xer') {
			xer_files << file
		}
	}

	for index, _ in xer_files {
		println('[Analyzing]  ${xer_files[index]}')

		lines := os.read_lines(xer_files[index]) or { panic(err) }

		// JSON2 vars
		mut me := map[string]json2.Any{}
		mut xer_row := map[string]json2.Any{}
		mut xer_rows := []json2.Any{}

		mut line_index := 0
		mut header_arr := []string{}

		for i := line_index; i < lines.len; i++ {
			line_index++
			if lines[i].starts_with('%T') {
				table_name := lines[i].find_between('%T\t', '\n')
				println('\t\tTABLE: $table_name')

				for j := line_index; j < lines.len; j++ {
					// reached new table
					if lines[j].starts_with('%T') {
						break
					}
					// reached end of file
					else if lines[j].starts_with('%E') {
						break
					}

					// at the header
					if j == line_index {
						header_arr = lines[j].split('\t')
						continue
					}

					// If fell down here it is data for this header...
					line_arr := lines[j].split('\t')

					for idx, elem in header_arr {
						if is_ascii(line_arr[idx]) {
							xer_row[elem] = line_arr[idx]
						} else {
							xer_row[elem] = 'non-ascii'
						}
					}

					xer_rows << xer_row
					xer_row = map[string]json2.Any{}
				}

				me[table_name] = xer_rows
				xer_rows = []json2.Any{}
			}
		}

		print('[Writing JSON].... ')

		// Done walking this XER
		xer_name := xer_files[index].all_before_last('.xer')
		mut json_out := os.create(xer_name + '.json') or { panic(err) }
		json_out.writeln(me.str()) or { panic(err) }
		json_out.close()

		println('[Done]\n')
	}

	println('[Done Batch]')
	println('')
}

fn is_ascii(s string) bool {
	for a_char in s {
		if a_char > 127 {
			return false
		}
	}
	return true
}
