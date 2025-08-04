import paramiko

def sftp_login(host, port, username, password):
    """
    Logs into an SFTP server and returns the SFTP client object.
    """
    try:
        # Create SSH client
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        # Connect to the server
        print(f"Connecting to {host}:{port}...")
        ssh.connect(hostname=host, port=port, username=username, password=password)
        
        # Start SFTP session
        sftp = ssh.open_sftp()
        print("SFTP connection established.")
        return sftp, ssh
    except Exception as e:
        print(f"Failed to connect: {e}")
        return None, None

if __name__ == "__main__":
    # Example usage
    host = "example.com"
    port = 22
    username = "your_username"
    password = "your_password"
    
    sftp, ssh = sftp_login(host, port, username, password)
    if sftp:
        # List files in the remote directory
        print("Remote directory listing:")
        print(sftp.listdir("."))
        
        # Close connections
        sftp.close()
        ssh.close()
        print("SFTP connection closed.")
