// Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.
// Use of this source code (/program) is governed by an MIT license,
// that can be found in the LICENSE file. Do not remove this header.
import os
import util
import flag
import xer

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

	master_arg := fp.bool('consolidated', `c`, false, 'extract all possible combinations of ACTVTYPE and ACTVCODE')

	append_arg := fp.bool('append', `a`, false, 'append results to each file (instead of one for each XER)')
	// sql_arg := fp.bool('sql', `s`, false, 'create an sqlite database for querying')
	// xer_arg := fp.bool('xer', `x`, false, 'specify an XER instead of using all')
	update_arg := fp.bool('update', `u`, false, 'check for tool updates')

	additional_args := fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}

	additional_args.join_lines()

	if update_arg {
		util.github_update('chipnetics', 'xertools', 'xerdump.exe')
		return
	}

	dir_elems := os.ls('.') or { panic(err) }

	mut xer_files := []string{}

	for file in dir_elems {
		if file.ends_with('.xer') {
			xer_files << file
		}
	}

	if master_arg {
		generate_master_table(xer_files)
		println('[Done]\n')
		return
	}

	if append_arg {
		generate_appended(xer_files)
		println('[Done]\n')
		return
	}

	// Else if fall through to here, just execute normal behaviour of dumping
	// contents to respective folders.
	for index, _ in xer_files {
		println('[Analyzing]  ${xer_files[index]}')

		lines := os.read_lines(xer_files[index]) or { panic(err) }

		dir_name := xer_files[index].all_before_last('.xer')
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
					file_out.writeln(lines[j])?
				}
			}
		}
	}

	println('[Done]')
	println('')
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
		println('[Analyzing]  ${xer_files[index]}')

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
	for xer_file in xer_files {
		map_actvtype := xer.parse_actvtype(xer_file)
		map_actvcode := xer.parse_actvcode(xer_file)
		map_task := xer.parse_task_idkey(xer_file)
		arr_taskactv := xer.parse_taskactv(xer_file)

		// xer_filename,task_id,actv_code_type_id,actv_code_id,proj_id
		// TODO: should sort arr_taskactv
		for task in arr_taskactv {
			actv_code_type := map_actvtype[task.actv_code_type_id].actv_code_type
			actv_code_name := map_actvcode[task.actv_code_id].actv_code_name
			short_name := map_actvcode[task.actv_code_id].short_name

			print('$xer_file\t$actv_code_type\t$actv_code_name\t$short_name')

			data_arr := map_task[task.task_id].to_array()

			for elem in data_arr[1..] {
				print('\t$elem')
			}

			println('')
		}
	}
}
