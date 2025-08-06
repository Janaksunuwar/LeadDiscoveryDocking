#This script moves the zn22.pdbqt file from the UNT Azure server to the local drive.
#This is intended for running Autodock locally, as the server seemed unstable while downloading zn22 3d files from AWS to UNT Azure server.

#!/bin/bash

SRC="/Volumes/CoreLabs/RCL/Jan_HPC/aws_zinc22_3D_download"
DEST="/Volumes/Janak_UNTHS/UNTHealth"

# Step 1: Transfer files with parallelized rsync (resume-safe, preserves hierarchy)
find "$SRC" -type f \
| parallel -j 8 rsync -Ravh --partial --append --ignore-existing --progress {} "$DEST"

# Step 2: Count files at source and destination
SRC_COUNT=$(find "$SRC" -type f | wc -l)
DEST_COUNT=$(find "$DEST/Volumes/CoreLabs/RCL/Jan_HPC/aws_zinc22_3D_download" -type f 2>/dev/null | wc -l)

echo "Source files:      $SRC_COUNT"
echo "Destination files: $DEST_COUNT"

# Step 3: Move folder if counts match
if [ "$SRC_COUNT" -eq "$DEST_COUNT" ]; then
    echo "Counts match. Moving folder to top level..."
    mv "$DEST/Volumes/CoreLabs/RCL/Jan_HPC/aws_zinc22_3D_download" \
       "$DEST/aws_zinc22_3D_download"
    echo "Move complete: $DEST/aws_zinc22_3D_download"
else
    echo "Counts do NOT match — move aborted."
fi

