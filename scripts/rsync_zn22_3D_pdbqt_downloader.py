##Usingh rsync as weget keeps on breaking


# Zn22 rsync parallel downloader for pdbqt files
# Efficient alternative to wget-based download with resume and filtering support

import os
import subprocess
import multiprocessing
from datetime import datetime

# CONFIGURATION
rsync_base = "rsync://files.docking.org/ZINC22-3D"
tranches = [
    "zinc-22a", "zinc-22b", "zinc-22c", "zinc-22d", "zinc-22e",
    "zinc-22f", "zinc-22g", "zinc-22h", "zinc-22i", "zinc-22j",
    "zinc-22k", "zinc-22l", "zinc-22m", "zinc-22n", "zinc-22o",
    "zinc-22p", "zinc-22q", "zinc-22r", "zinc-22s", "zinc-22t",
    "zinc-22u", "zinc-22v", "zinc-22w", "zinc-22x"
]

output_dir = "zn_rsync_download"
rsync_log = "rsync_summary.log"
os.makedirs(output_dir, exist_ok=True)

# FUNCTION TO RUN RSYNC FOR A SINGLE TRANCHE
def run_rsync(tranche):
    log_file = os.path.join(output_dir, f"rsync_{tranche}.log")
    target_dir = os.path.join(output_dir, tranche)
    os.makedirs(target_dir, exist_ok=True)

    include_rules = [
        "--include=*/",
        f"--include={tranche}/H*/H*/[a-z]/",
        f"--include={tranche}/H*/H*/[a-z]/*pdbqt.tgz",
        "--exclude=*"
    ]

    cmd = [
        "rsync", "-Larv", *include_rules,
        f"{rsync_base}/{tranche}",
        target_dir
    ]

    start = datetime.now()
    with open(log_file, 'w') as log:
        log.write(f"Running: {' '.join(cmd)}\n")
        log.write(f"Started: {start}\n\n")
        result = subprocess.run(cmd, stdout=log, stderr=log)
        end = datetime.now()
        log.write(f"\nFinished: {end}, Duration: {end - start}\n")

    return tranche, result.returncode, start, end

# MAIN PARALLEL EXECUTION
if __name__ == '__main__':
    start_time = datetime.now()
    print(f"Starting rsync download of {len(tranches)} tranches at {start_time}")

    with multiprocessing.Pool(processes=4) as pool:
        results = pool.map(run_rsync, tranches)

    end_time = datetime.now()
    duration = end_time - start_time

    total_success = sum(1 for _, code, _, _ in results if code == 0)
    total_failed = len(results) - total_success

    with open(rsync_log, 'w') as f:
        f.write(f"RSYNC SUMMARY LOG\n")
        f.write(f"Started: {start_time}\n")
        f.write(f"Ended: {end_time}\n")
        f.write(f"Duration: {duration}\n")
        f.write(f"Total tranches: {len(tranches)}\n")
        f.write(f"Successful: {total_success}\n")
        f.write(f"Failed: {total_failed}\n\n")
        for tranche, code, t_start, t_end in results:
            f.write(f"{tranche}: {'SUCCESS' if code == 0 else 'FAILED'} | Start: {t_start} | End: {t_end} | Duration: {t_end - t_start}\n")

    print(f"All rsync tasks completed in {duration}")
