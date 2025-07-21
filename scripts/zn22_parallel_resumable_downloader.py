#Zn db downloader from the wget 3D zinc22
#This script downloads and extracts ZINC22 3D ligand files in parallel, resuming from where it left off. Includes auto-pausing when volume is offline and retrying failed jobs.
# The script might pause if the output directory is not mounted, and it will retry downloading files that failed previously.
# It also logs the download status and timestamps for each event, allowing for easy tracking of progress and issues.

import os
import subprocess
import tarfile
import tempfile
import psutil
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime

# CONFIGURATION
wget_file = 'ZINC22-downloader-3D-pdbqt.tgz.wget'
output_dir = "zn_download"
max_workers = 2
summary_file = "download_summary.txt"
done_log_file = "downloaded.done"
error_log_file = "failed.log"
notfound_log_file = "notfound.log"
timestamp_log_file = "timestamp.log"
polling_interval = 60  # seconds to wait when volume is offline

# SETUP
os.makedirs(output_dir, exist_ok=True)

# Load already downloaded or skipped .tgz names (if any)
done_files = set()
notfound_files = set()
if os.path.exists(done_log_file):
    with open(done_log_file, 'r') as f:
        done_files = set(line.strip() for line in f if line.strip())
if os.path.exists(notfound_log_file):
    with open(notfound_log_file, 'r') as f:
        notfound_files = set(line.strip() for line in f if line.strip())

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
    if shortname not in done_files and shortname not in notfound_files:
        jobs.append((shortname, line))

total_jobs = len(jobs)
print(f"Total remaining jobs: {total_jobs}")

# Logging

def log_append(filename, text):
    with open(filename, 'a') as f:
        f.write(text + '\n')

def log_timestamp_event(event):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(timestamp_log_file, 'a') as f:
        f.write(f"[{timestamp}] {event}\n")

# Mount check

def is_output_mounted(path):
    partitions = [p.mountpoint for p in psutil.disk_partitions()]
    abs_path = os.path.abspath(path)
    return any(abs_path.startswith(p) for p in partitions)

# Worker

def process_job(index, shortname, command):
    # Wait until volume is mounted
    while not is_output_mounted(output_dir):
        log_timestamp_event(f"PAUSED: Output dir {output_dir} is not mounted. Waiting...")
        time.sleep(polling_interval)

    print(f"[{index+1}/{total_jobs}] Downloading {shortname}")
    local_tgz_path = os.path.join(output_dir, shortname)
    result = subprocess.run(command, shell=True, cwd=output_dir, capture_output=True, text=True)

    if result.returncode != 0:
        if "404 Not Found" in result.stderr or "404 Not Found" in result.stdout:
            log_append(notfound_log_file, shortname)
            log_timestamp_event(f"NOT FOUND (404): {shortname}")
            return f"[{index+1}] 404 Not Found: {shortname}"
        log_append(error_log_file, shortname)
        log_timestamp_event(f"FAILED: {shortname}")
        return f"[{index+1}] Failed: {shortname}"

    if not os.path.exists(local_tgz_path):
        log_append(error_log_file, shortname)
        log_timestamp_event(f"FAILED (Missing file): {shortname}")
        return f"[{index+1}] Missing file: {shortname}"

    with tempfile.TemporaryDirectory() as temp_dir:
        try:
            with tarfile.open(local_tgz_path, 'r:gz') as tar:
                tar.extractall(path=temp_dir)
        except Exception as e:
            log_append(error_log_file, shortname)
            log_timestamp_event(f"EXTRACT FAIL: {shortname} ({e})")
            return f"[{index+1}] Extract fail: {shortname} ({e})"
        finally:
            os.remove(local_tgz_path)

        for root, dirs, files in os.walk(temp_dir):
            rel_path = os.path.relpath(root, temp_dir)
            dest_path = os.path.join(output_dir, rel_path)
            os.makedirs(dest_path, exist_ok=True)
            for file in files:
                src_file = os.path.join(root, file)
                dst_file = os.path.join(dest_path, file)
                if not os.path.exists(dst_file):
                    os.rename(src_file, dst_file)

    log_append(done_log_file, shortname)
    log_timestamp_event(f"DOWNLOADED: {shortname}")
    return f"[{index+1}] Done: {shortname}"

# MAIN PARALLEL LOOP
start_time = datetime.now()
log_timestamp_event(f"STARTED download session with {total_jobs} jobs")

with ThreadPoolExecutor(max_workers=max_workers) as executor:
    futures = [executor.submit(process_job, i, name, cmd) for i, (name, cmd) in enumerate(jobs)]
    for future in as_completed(futures):
        print(future.result())

# FINAL SUMMARY
duration = datetime.now() - start_time
success_count = 0
fail_count = 0
notfound_count = 0

if os.path.exists(done_log_file):
    with open(done_log_file, 'r') as f:
        success_count = len([line for line in f if line.strip()])

if os.path.exists(error_log_file):
    with open(error_log_file, 'r') as f:
        fail_count = len([line for line in f if line.strip()])

if os.path.exists(notfound_log_file):
    with open(notfound_log_file, 'r') as f:
        notfound_count = len([line for line in f if line.strip()])

with open(summary_file, 'a') as f:
    f.write(f"Run completed at: {datetime.now()}\n")
    f.write(f"Total attempted this run: {total_jobs}\n")
    f.write(f"Newly successful: {success_count}\n")
    f.write(f"Newly failed: {fail_count}\n")
    f.write(f"404 Not Found: {notfound_count}\n")
    f.write(f"Duration: {duration}\n")
    f.write(f"Total .tgz files remaining (unprocessed): {822233 - success_count - fail_count - notfound_count}\n\n")

log_timestamp_event(f"FINISHED download session. Duration: {duration}")
print(f"All tasks completed. Duration: {duration}")
