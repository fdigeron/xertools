import sqlite
import os
import flag
import util

fn main() {
	mut pre_built_str := ''
	$if prebuilt ? {
		build_date := $env('DATE')
		pre_built_str = '[pre-built binary release ($build_date)]\n'
	}

	mut fp := flag.new_flag_parser(os.args)
	fp.application('sqlrunner')

	fp.version('${pre_built_str}Copyright (c) 2022 jeffrey -at- ieee.org. All rights reserved.\nUse of this source code (/program) is governed by a GPLV3 license,\nthat can be found in the LICENSE file.')

	fp.description('\nExecutes .sql commands on a selected SQLite database, outputting the results to txt files.')

	fp.skip_executable()

	database_arg := fp.string('database', `d`, '', 'specify SQLite database')
	sql_arg := fp.string('sqllist', `f`, '', 'specify a file with a list of SQL commands to process')
	output_arg := fp.string('output', `o`, '', 'specify the output folder for query results. [Default: current]')
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
			util.github_update('chipnetics', 'xertools', 'sqlrunner', force_mode)
		} $else {
			util.github_update('chipnetics', 'xertools', 'sqlrunner.exe', force_mode)
		}
		return
	}

	if database_arg.len == 0 {
		println("[ERROR] You must specify a SQLite database with the '-d' flag.\nSee '-h' for help.")
		exit(0)
	}

	mut sql_files := []string{}

	// File with a list of sql filenames was specified....
	if sql_arg.len > 0 {
		sql_file_list := os.read_lines(sql_arg) or {
			println("Error. Could not open '$sql_arg' to get sql list. Aborting")
			return
		}
		for file in sql_file_list {
			if file.ends_with('.sql') {
				sql_files << file
			}
		}
	}

	// Some non-consumed flag args remain....
	// Add them to sql_files if they are sqls (even if we specified some with -f)
	if fp.args.len > 0 {
		// remaining non flag args are files (or should be)
		for file in fp.args {
			if file.ends_with('.sql') {
				sql_files << file
			}
		}
	}

	// All fp args were consumed....
	// No sql list of files was specified....
	// So do all sqls in directory
	if fp.args.len == 0 && sql_arg.len == 0 {
		dir_elems := os.ls('.') or {
			println('Could not get list of files in directory. Aborting')
			return
		}
		for file in dir_elems {
			if file.ends_with('.sql') {
				sql_files << file
			}
		}
		sql_files.sort()
	}

	println('Processing SQL files...         ')
	process_sql_arr(sql_files, database_arg, output_arg)
	println('[DONE]')
}

fn process_sql_arr(sql_files []string, database string, output_arg string) {
	db := sqlite.connect(database) or {
		println("[ERROR]\nCould not open database named '$database'.")
		return
	}

	if output_arg.len > 0 {
		os.mkdir(output_arg) or {}
	}

	for sql_file in sql_files {
		sql_commands := os.read_file(sql_file) or {
			eprintln("Could not read '$sql_file'. Skipping")
			continue
		}

		// Split by semi-colons for end of statements
		// incase statements wrap many lines.
		sql_cmd_lines := sql_commands.split(';')

		// If more then one command in each file, we will use idx to make a file
		// for each.
		mut sql_txt := ''
		for idx, line in sql_cmd_lines {
			// Short line, probably carriage returns/newlines
			if line.len <= 3 {
				continue
			}

			results, rescode := db.exec(line)

			if rescode != 101 {
				eprintln("[ERROR] executing '$line' in '$sql_file', code '$rescode' returned. Skipping.")
				continue
			}

			// Because we split with ;, will always have extra element, so
			// check if GT 2 (and not 1)
			if sql_cmd_lines.len > 2 {
				sql_txt = '${os.file_name(sql_file).all_before_last('.')}_${idx}.txt'
			} else {
				sql_txt = '${os.file_name(sql_file).all_before_last('.')}.txt'
			}

			mut folder_pre := ''
			if output_arg.len > 0 {
				folder_pre = '$output_arg/'
			}

			mut fout := os.create('$folder_pre$sql_txt') or {
				eprintln('[ERROR] Could not create output txt file. Skipping.')
				continue
			}

			for res in results {
				fout.writeln(res.vals.join('\t')) or {}
			}

			fout.close()
		}
	}
}
