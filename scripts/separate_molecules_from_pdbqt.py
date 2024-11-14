import os
import gzip
import shutil
import argparse

def unzip_files(input_dir):
    print(f"[DEBUG] Unzipping files in directory: {input_dir}")

    # Iterate over each .gz file and unzip it
    for file_name in os.listdir(input_dir):
        if file_name.endswith(".gz"):
            gz_path = os.path.join(input_dir, file_name)
            pdbqt_path = gz_path[:-3]  # Remove .gz extension to get .pdbqt file name
            print(f"[DEBUG] Unzipping file: {gz_path} to {pdbqt_path}")
            try:
                with gzip.open(gz_path, 'rb') as f_in:
                    with open(pdbqt_path, 'wb') as f_out:
                        shutil.copyfileobj(f_in, f_out)
                print(f"[DEBUG] Unzipped: {pdbqt_path}")

                # Remove the original .gz file after unzipping
                os.remove(gz_path)
                print(f"[DEBUG] Removed original gz file: {gz_path}")

            except Exception as e:
                print(f"[ERROR] Error unzipping {file_name}: {e}")

def separate_molecules(input_dir, output_dir):
    # Create the output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    print(f"[DEBUG] Output directory ensured: {output_dir}")

    print(f"[DEBUG] Starting molecule separation in directory: {input_dir}")

    # Check if input directory exists and contains files
    if not os.path.exists(input_dir):
        print(f"[ERROR] Input directory {input_dir} does not exist.")
        return
    
    # Check if input directory is empty
    if not os.listdir(input_dir):
        print(f"[ERROR] Input directory {input_dir} is empty. No files to process.")
        return

    # Iterate over each pdbqt file and separate molecules
    found_files = False
    for file_name in os.listdir(input_dir):
        if file_name.endswith(".pdbqt"):
            found_files = True
            input_path = os.path.join(input_dir, file_name)
            print(f"[DEBUG] Processing file for molecule separation: {input_path}")
            try:
                with open(input_path, 'r') as f:
                    content = f.read()

                # Split molecules based on MODEL tag (AutoDock uses MODEL tag to separate)
                molecules = content.split('MODEL')
                if len(molecules) <= 1:
                    print(f"[DEBUG] No 'MODEL' tags found in {file_name}. Skipping.")
                    continue

                for idx, molecule in enumerate(molecules[1:], start=1):
                    molecule = 'MODEL' + molecule  # Add back the MODEL tag
                    output_path = os.path.join(output_dir, f"{file_name[:-6]}_molecule_{idx}.pdbqt")
                    with open(output_path, 'w') as f_out:
                        f_out.write(molecule)
                    print(f"[DEBUG] Separated molecule {idx} from {file_name} into {output_path}")

                # Optionally, remove the original pdbqt file if needed
                os.remove(input_path)
                print(f"[DEBUG] Removed original file after separation: {input_path}")

            except Exception as e:
                print(f"[ERROR] Error processing file {file_name} for molecule separation: {e}")

    if not found_files:
        print(f"[ERROR] No '.pdbqt' files found in {input_dir} to process.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Unzip PDBQT files and separate molecules.")
    parser.add_argument('--input_dir', type=str, required=True, help='Directory containing .pdbqt.gz files.')
    parser.add_argument('--output_dir', type=str, required=True, help='Directory to store separated PDBQT files.')

    args = parser.parse_args()

    # Step 1: Unzip files
    unzip_files(args.input_dir)

    # Step 2: Separate molecules
    separate_molecules(args.input_dir, args.output_dir)
