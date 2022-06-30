module util

import os
import net.http
import crypto.md5
import encoding.base64
import readline

pub fn github_update(username string, repo string, file string) {
	println('Checking for updates... ')

	md5_curr := md5.sum(os.read_bytes(os.args[0]) or {
		println('Error checking for update. Aborting.')
		return
	}).hex()
	println('MD5 current: $md5_curr')

	res := http.head('http://github.com/$username/$repo/releases/latest/download/$file') or {
		println('Error checking for update. Aborting.')
		return
	}

	if res.status_code == 200 {
		md5_latest := base64.decode(res.header.custom_values('Content-MD5')[0]).hex()
		println('MD5 latest:  $md5_latest')

		if compare_strings(md5_curr, md5_latest) != 0 {
			mut user_in := readline.read_line('An update is available, download now? [y/N] ') or {
				println('Error checking for update. Aborting.')
				return
			}

			if compare_strings(user_in, 'y\n') == 0 {
				print('[1/4] Backing up old version... ')
				os.mv('$file', '${file}.bak') or {
					println("[FAIL]\nError moving file '$file'. Aborting")
					return
				}
				println('\t[DONE]')

				print('[2/4] Downloading update...')
				http.download_file('http://github.com/$username/$repo/releases/latest/download/$file',
					'$file') or {
					println('[FAIL]\nError downloading update. Aborting.')
					return
				}
				println('\t\t[DONE]')

				print('[3/4] Verifying MD5 of download...')
				md5_new := md5.sum(os.read_bytes(file) or {
					println('Error checking MD5. Aborting.')
					return
				}).hex()

				if compare_strings(md5_new, md5_latest) == 0 {
					println('\t[DONE]')
				} else {
					println('\t[FAIL]')
					print('[4/4] Restoring backup...')
					os.mv('xertask_bak', 'xertask') or {
						println('[FAIL]\nError moving file. Aborting')
						return
					}
					println('\t\t[DONE]')
					return
				}

				print('[4/4] Deleting old version...')
				os.rm('${file}.bak') or {
					println("[FAIL]\nError deleting file '${file}.bak'. Aborting")
					return
				}
				println('\t\t[DONE]')
			} else {
				println('Update aborted.')
			}
		} else {
			println('You are runnning the latest version. No updates are available.')
		}
	} else {
		println('Error checking for update. Aborting.')
	}
}