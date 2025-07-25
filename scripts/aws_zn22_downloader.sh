#download all pdbqts only from aws s3 bucket (https://aws.amazon.com/marketplace/pp/prodview-cclrxhtx5xibk#resources)

#!/bin/bash

# === CONFIGURATION ===
S3_BUCKET="s3://zinc3d"
DEST_DIR="zn22_pdbqt"
LOG_DIR="logs"
LOG_FILE="$LOG_DIR/download_pdbqt.log"

# === PREP ===
mkdir -p "$DEST_DIR"
mkdir -p "$LOG_DIR"

# === START LOGGING ===
echo "=== ZINC22 pdbqt Sync Started: $(date) ===" | tee -a "$LOG_FILE"

# === LOOP THROUGH zinc-22a to zinc-22z ===
for PART in {a..z}; do
  PART_PATH="zinc-22$PART"
  echo ">>> Syncing $PART_PATH..." | tee -a "$LOG_FILE"

  aws s3 sync \
    --no-sign-request \
    --exclude "*" \
    --include "*.pdbqt.tgz" \
    "$S3_BUCKET/$PART_PATH/" "$DEST_DIR/$PART_PATH/" \
    | tee -a "$LOG_FILE"

  echo "<<< Completed $PART_PATH at $(date)" | tee -a "$LOG_FILE"
done

# === DONE ===
echo "=== ZINC22 pdbqt Sync Finished: $(date) ===" | tee -a "$LOG_FILE"
