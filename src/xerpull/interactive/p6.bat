@echo off
set /P id=Enter Schedule ID:

echo Fetching XER File from project %id%....
"./etc/sed.exe" "s/PROJECT_ID_TAG/%id%/g" "./etc/p6_export_template.xml" > "./etc/p6_export.xml"

"C:\Program Files\Oracle\Primavera P6\P6 Professional\PM.exe" /username=your_username /password=your_password /actionScript=etc/p6_export.xml /logfile=etc/log.txt
