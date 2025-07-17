#DOWNLOAD ZN PDBQT FROM 

#the wget address was downloaded from the ZINC website ub AutoDock format (https://cartblanche22.docking.org/tranches/3d)

import os
import subprocess
import tarfile
import tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed

# === CONFIGURATION ===
wget_file = 'ZINC22-downloader-3D-pdbqt.tgz.wget'  # File with wget commands
output_dir = "zn_download"                         # Where .tgz files and folders are stored
max_workers = 5                                    # Number of parallel download threads
summary_file = "download_summary.txt"

# === SETUP ===
os.makedirs(output_dir, exist_ok=True)

with open(wget_file, 'r') as f:
    wget_commands = [line.strip() for line in f if line.strip().startswith("wget")]

total_tranches = len(wget_commands)
completed = 0
failed = []

print(f" Total tranches to process: {total_tranches}")


def process_wget(index, command):
    tgz_filename = command.split()[-1]
    shortname = os.path.basename(tgz_filename)
    local_tgz_path = os.path.join(output_dir, shortname)

    if os.path.exists(local_tgz_path):
        return f"[{index+1}/{total_tranches}] Already exists: {shortname}"

    print(f"[{index+1}/{total_tranches}] Downloading: {shortname}")
    result = subprocess.run(command, shell=True, cwd=output_dir)

    if result.returncode != 0 or not os.path.exists(local_tgz_path):
        failed.append(shortname)
        return f"[{index+1}/{total_tranches}] Failed: {shortname}"

    with tempfile.TemporaryDirectory() as temp_dir:
        try:
            print(f"[{index+1}/{total_tranches}] Extracting: {shortname}")
            with tarfile.open(local_tgz_path, 'r:gz') as tar:
                tar.extractall(path=temp_dir)
        except Exception as e:
            failed.append(shortname)
            return f"[{index+1}/{total_tranches}] Extraction failed: {shortname} ({e})"
        finally:
            os.remove(local_tgz_path)

        # Move the full extracted folder structure into output_dir
        for item in os.listdir(temp_dir):
            src = os.path.join(temp_dir, item)
            dst = os.path.join(output_dir, item)
            if os.path.exists(dst):
                continue
            os.rename(src, dst)

    return f"[{index+1}/{total_tranches}] Done: {shortname}"


# === MAIN PARALLEL LOOP ===
with ThreadPoolExecutor(max_workers=max_workers) as executor:
    futures = [executor.submit(process_wget, i, cmd) for i, cmd in enumerate(wget_commands)]
    for future in as_completed(futures):
        print(future.result())

# === FINAL SUMMARY ===
with open(summary_file, 'w') as f:
    f.write(f"Total tranches: {total_tranches}\n")
    f.write(f"Failed downloads: {len(failed)}\n")
    for fail in failed:
        f.write(f"  - {fail}\n")
    f.write(f"Extracted data stored in: {output_dir}\n")

print("\nAll downloads attempted.")
print(f"Failed: {len(failed)} tranches")
print(f"All extracted content saved under: {output_dir}")
print(f"Summary written to: {summary_file}")
