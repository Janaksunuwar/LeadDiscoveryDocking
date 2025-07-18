#Zn db downloader from the wget 3D zinc22
#This script downloads and extracts ZINC22 3D ligand files in parallel, resuming from where it left off.

import os
import subprocess
import tarfile
import tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime

# CONFIGURATION
wget_file = 'ZINC22-downloader-3D-pdbqt.tgz.wget'  # Your wget command file
output_dir = "zn_download"
max_workers = 2
summary_file = "download_summary.txt"
done_log_file = "downloaded.done"
error_log_file = "failed.log"

# SETUP
os.makedirs(output_dir, exist_ok=True)

# Load already downloaded .tgz names (if any)
done_files = set()
if os.path.exists(done_log_file):
    with open(done_log_file, 'r') as f:
        done_files = set(line.strip() for line in f if line.strip())

# Prepare wget commands
with open(wget_file, 'r') as f:
    wget_commands = [line.strip() for line in f if line.strip().startswith("wget")]

# Parse target filenames from commands
jobs = []
for line in wget_commands:
    parts = line.split()
    if len(parts) < 2:
        continue
    url = parts[-1]
    shortname = os.path.basename(url)
    if shortname not in done_files:
        jobs.append((shortname, line))

total_jobs = len(jobs)
print(f"Total remaining jobs: {total_jobs}")

# Thread-safe log append
def log_append(filename, text):
    with open(filename, 'a') as f:
        f.write(text + '\n')

# Worker function
def process_job(index, shortname, command):
    print(f"[{index+1}/{total_jobs}] {shortname}")

    local_tgz_path = os.path.join(output_dir, shortname)
    result = subprocess.run(command, shell=True, cwd=output_dir)

    if result.returncode != 0 or not os.path.exists(local_tgz_path):
        log_append(error_log_file, shortname)
        return f"[{index+1}] Failed: {shortname}"

    with tempfile.TemporaryDirectory() as temp_dir:
        try:
            with tarfile.open(local_tgz_path, 'r:gz') as tar:
                tar.extractall(path=temp_dir)
        except Exception as e:
            log_append(error_log_file, shortname)
            return f"[{index+1}] Extract fail: {shortname} ({e})"
        finally:
            os.remove(local_tgz_path)

        # Move extracted contents
        for root, dirs, files in os.walk(temp_dir):
            rel_path = os.path.relpath(root, temp_dir)
            dest_path = os.path.join(output_dir, rel_path)
            os.makedirs(dest_path, exist_ok=True)

            for file in files:
                src_file = os.path.join(root, file)
                dst_file = os.path.join(dest_path, file)
                if not os.path.exists(dst_file):  # avoid overwrite
                    os.rename(src_file, dst_file)

    log_append(done_log_file, shortname)
    return f"[{index+1}] Done: {shortname}"

# MAIN PARALLEL LOOP
start_time = datetime.now()
with ThreadPoolExecutor(max_workers=max_workers) as executor:
    futures = [executor.submit(process_job, i, name, cmd) for i, (name, cmd) in enumerate(jobs)]
    for future in as_completed(futures):
        print(future.result())

# FINAL SUMMARY
duration = datetime.now() - start_time
with open(summary_file, 'a') as f:
    f.write(f"Run completed at: {datetime.now()}\n")
    f.write(f"Total attempted: {total_jobs}\n")
    f.write(f"Successful: {len(jobs) - len(open(error_log_file).readlines()) if os.path.exists(error_log_file) else len(jobs)}\n")
    f.write(f"Failed: {len(open(error_log_file).readlines()) if os.path.exists(error_log_file) else 0}\n")
    f.write(f"Duration: {duration}\n\n")

print(f"All tasks completed. Duration: {duration}")
