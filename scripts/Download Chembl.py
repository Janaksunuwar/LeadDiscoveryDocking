#Download Chembl
#https://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBLdb/latest/

# wget chembl sdf
#wget https://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBLdb/latest/chembl_35.sdf.gz

# convert sdf to pdbqt

import os
import random
import subprocess
import gzip
import shutil
from rdkit import Chem
from rdkit.Chem import AllChem

# Parameters
NUM_MOLECULES = 10  # Number of molecules to extract and convert
SDF_GZ_URL = "https://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBLdb/latest/chembl_35.sdf.gz"
SDF_FILE = "chembl_35.sdf"
SDF_GZ_FILE = SDF_FILE + ".gz"
OUTPUT_DIR = "chembl_pdbqt"

# Step 1: Setup
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(f"{OUTPUT_DIR}/sdf", exist_ok=True)
os.makedirs(f"{OUTPUT_DIR}/mol2", exist_ok=True)
os.makedirs(f"{OUTPUT_DIR}/pdbqt", exist_ok=True)

# Step 2: Download .sdf.gz
if not os.path.exists(SDF_GZ_FILE):
    print("Downloading ChEMBL SDF...")
    subprocess.run(["wget", SDF_GZ_URL, "-O", SDF_GZ_FILE])

# Step 3: Unzip
if not os.path.exists(SDF_FILE):
    print("Unzipping SDF...")
    with gzip.open(SDF_GZ_FILE, "rb") as f_in:
        with open(SDF_FILE, "wb") as f_out:
            shutil.copyfileobj(f_in, f_out)

# Step 4: Extract N random molecules using RDKit
print(f"🔍 Parsing and extracting {NUM_MOLECULES} random molecules...")
suppl = list(Chem.SDMolSupplier(SDF_FILE))
mols = [m for m in suppl if m is not None]
random.shuffle(mols)
selected = mols[:NUM_MOLECULES]

for i, mol in enumerate(selected):
    mol_name = f"mol_{i+1}"
    
    sdf_path = f"{OUTPUT_DIR}/sdf/{mol_name}.sdf"
    mol2_path = f"{OUTPUT_DIR}/mol2/{mol_name}.mol2"
    pdbqt_path = f"{OUTPUT_DIR}/pdbqt/{mol_name}.pdbqt"

    # Write SDF file
    w = Chem.SDWriter(sdf_path)
    w.write(mol)
    w.close()

    # Step 5: SDF → MOL2 using Open Babel
    subprocess.run(["obabel", sdf_path, "-O", mol2_path, "--gen3d"])

    # Step 6: MOL2 → PDBQT using Open Babel
    subprocess.run(["obabel", mol2_path, "-O", pdbqt_path])

print("Done! All molecules converted to .pdbqt.")

