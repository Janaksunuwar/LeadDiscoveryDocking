#This is a prototype for direct autodock from AWS S3 bucket of zn22 db.

#!/bin/bash
set -e

# Config
RECEPTOR="protein.pdbqt"  # Path to your receptor file
AWS_BUCKET="s3://zinc3d/zinc-22a/"
PARALLEL_JOBS=8           # Number of ligands to dock in parallel
NUM_LIGANDS=50            # Number of ligands to test
CENTER_X=10
CENTER_Y=20
CENTER_Z=30
SIZE_X=20
SIZE_Y=20
SIZE_Z=20

# Folders
mkdir -p results temp

# Step 1: Get N random ligand .tgz keys (only key names, no timestamps/sizes)
aws s3 ls "$AWS_BUCKET" --no-sign-request --recursive \
    | grep ".pdbqt.tgz" \
    | awk '{print $4}' \
    | gshuf -n $NUM_LIGANDS > tgz_list.txt

# Step 2: Define docking function
dock_ligand() {
    key="$1"
    base_name=$(basename "$key" .pdbqt.tgz)

    # Download ligand
    aws s3 cp --no-sign-request "s3://zinc3d/$key" "temp/$base_name.pdbqt.tgz"

    # Extract PDBQT
    tar -xzf "temp/$base_name.pdbqt.tgz" -C temp/
    ligand_file=$(find temp -name "*.pdbqt" | head -n 1)

    # Run Vina docking
    vina --receptor "$RECEPTOR" \
         --ligand "$ligand_file" \
         --center_x $CENTER_X --center_y $CENTER_Y --center_z $CENTER_Z \
         --size_x $SIZE_X --size_y $SIZE_Y --size_z $SIZE_Z \
         --out "results/${base_name}_docked.pdbqt"

    # Cleanup temp files
    rm -f "temp/$base_name.pdbqt.tgz" "$ligand_file"
}

export -f dock_ligand
export RECEPTOR CENTER_X CENTER_Y CENTER_Z SIZE_X SIZE_Y SIZE_Z

# Step 3: Run in parallel
cat tgz_list.txt | parallel -j $PARALLEL_JOBS dock_ligand {}

echo "✅ Docking complete. Results in ./results"
