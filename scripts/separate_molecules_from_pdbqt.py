# This script separates molecules from PDBQT files by splitting them based on the MODEL tag
import os

def separate_molecules(input_files):
    # Check if input_files is a single string (single file) or a list of files
    if isinstance(input_files, str):
        input_files = [input_files]
        
    print(f"[DEBUG] Starting molecule separation for files: {input_files}")

    # Iterate over each pdbqt file and separate molecules
    for input_path in input_files:
        if input_path.endswith(".pdbqt"):
            print(f"[DEBUG] Processing file for molecule separation: {input_path}")
            try:
                with open(input_path, 'r') as f:
                    content = f.read()

                # Split molecules based on MODEL tag (AutoDock uses MODEL tag to separate)
                molecules = content.split('MODEL')
                for idx, molecule in enumerate(molecules[1:], start=1):
                    molecule = 'MODEL' + molecule  # Add back the MODEL tag
                    output_file_name = f"{os.path.basename(input_path)[:-6]}_molecule_{idx}.pdbqt"
                    output_path = os.path.join(os.getcwd(), output_file_name)
                    with open(output_path, 'w') as f_out:
                        f_out.write(molecule)
                    print(f"[DEBUG] Separated molecule {idx} from {input_path} into {output_path}")

                # Optionally, remove the original file after splitting
                os.remove(input_path)
                print(f"[DEBUG] Removed original file: {input_path}")

            except Exception as e:
                print(f"[ERROR] Error processing file {input_path} for molecule separation: {e}")

def main(input_files):
    print(f"[DEBUG] Starting main function with input_files: {input_files}")
    # Print current working directory for debugging
    print(f"[DEBUG] Current working directory: {os.getcwd()}")
    # Separate molecules from each downloaded PDBQT file
    separate_molecules(input_files)

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Separate molecules from PDBQT files.")
    parser.add_argument('--input_files', type=str, nargs='+', required=True, help='PDBQT files to separate.')

    args = parser.parse_args()
    main(args.input_files)

    # confirm the script is running