#this pipeline is specifically for docking mien1 and zn22 3d from aws directly

import os
import subprocess
import random
import csv
import boto3
from botocore import UNSIGNED
from botocore.config import Config
from pathlib import Path

# === CONFIGURATION ===
RECEPTOR_PDB_ID = "2LJK"
RECEPTOR_PDB = "MIEN1.pdb"
RECEPTOR_PDBQT = "MIEN1.pdbqt"
RESULTS_DIR = "results"
CSV_FILE = "docking_results.csv"
TEMP_DIR = "temp"
NUM_LIGANDS = 50
ZINC_PREFIX = "zinc-22"

# === PREP ===
os.makedirs(RESULTS_DIR, exist_ok=True)
os.makedirs(TEMP_DIR, exist_ok=True)

# === Step 1: Download MIEN1 (2LJK) from RCSB ===
def download_mien1():
    if not os.path.exists(RECEPTOR_PDB):
        print("Downloading MIEN1 (2LJK)...")
        subprocess.run(["wget", f"https://files.rcsb.org/download/{RECEPTOR_PDB_ID}.pdb", "-O", RECEPTOR_PDB], check=True)
    else:
        print("MIEN1 PDB already exists.")

# === Step 2: Convert to PDBQT ===
def convert_to_pdbqt():
    if not os.path.exists(RECEPTOR_PDBQT):
        print("Converting MIEN1 to PDBQT using prepare_receptor4.py...")
        subprocess.run(["prepare_receptor4.py", "-r", RECEPTOR_PDB, "-o", RECEPTOR_PDBQT, "-A", "hydrogens"], check=True)
    else:
        print("MIEN1 PDBQT already exists.")

# === Step 3: Sample Ligands from AWS ===
def list_random_ligands(n):
    print(f"Fetching ligand list from zinc3d bucket...")
    s3 = boto3.client('s3', config=Config(signature_version=UNSIGNED))
    paginator = s3.get_paginator('list_objects_v2')

    all_keys = []
    for tranche in 'abcdefghijklmnopqrstuvwxyz':
        prefix = f"{ZINC_PREFIX}{tranche}/"
        pages = paginator.paginate(Bucket="zinc3d", Prefix=prefix)
        for page in pages:
            for obj in page.get('Contents', []):
                if obj['Key'].endswith(".pdbqt.tgz"):
                    all_keys.append(obj['Key'])

    print(f"Total ligands found: {len(all_keys)}")
    return random.sample(all_keys, min(n, len(all_keys)))

# === Step 4: Docking Each Ligand ===
def dock_ligand(s3_key):
    local_tgz = os.path.join(TEMP_DIR, os.path.basename(s3_key))
    local_pdbqt = local_tgz.replace(".tgz", "")

    # Download
    subprocess.run(["aws", "s3", "cp", f"s3://zinc3d/{s3_key}", local_tgz, "--no-sign-request"], check=True)

    # Extract
    subprocess.run(["tar", "-xzf", local_tgz, "-C", TEMP_DIR], check=True)

    # Dock
    out_path = os.path.join(RESULTS_DIR, s3_key)
    Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    out_pdbqt = os.path.join(out_path + ".out.pdbqt")
    log_file = os.path.join(out_path + ".log")

    result = subprocess.run([
        "vina",
        "--receptor", RECEPTOR_PDBQT,
        "--ligand", local_pdbqt,
        "--center_x", "10", "--center_y", "20", "--center_z", "30",
        "--size_x", "20", "--size_y", "20", "--size_z", "20",
        "--out", out_pdbqt,
        "--log", log_file
    ], capture_output=True, text=True)

    # Parse binding score
    best_score = None
    for line in result.stdout.splitlines():
        if line.strip().startswith("1"):
            parts = line.split()
            best_score = parts[1]  # Score is second column
            break

    return s3_key, out_pdbqt, best_score

# === Step 5: Log to CSV ===
def append_to_csv(rows):
    header = ["aws_key", "local_result", "binding_score"]
    write_header = not os.path.exists(CSV_FILE)
    with open(CSV_FILE, "a", newline="") as f:
        writer = csv.writer(f)
        if write_header:
            writer.writerow(header)
        writer.writerows(rows)

# === RUN ===
download_mien1()
convert_to_pdbqt()
ligands = list_random_ligands(NUM_LIGANDS)
results = []

for ligand_key in ligands:
    try:
        print(f"Docking: {ligand_key}")
        row = dock_ligand(ligand_key)
        results.append(row)
    except Exception as e:
        print(f"Failed on {ligand_key}: {e}")

append_to_csv(results)
print("Docking complete. Results saved in docking_results.csv")
