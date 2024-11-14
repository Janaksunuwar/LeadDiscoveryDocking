import os
import argparse

def separate_molecules(input_dir, output_dir):
    # Create the output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    print(f"[DEBUG] Output directory ensured: {output_dir}")

    print(f"[DEBUG] Starting molecule separation in directory: {input_dir}")
    # Iterate over each pdbqt file and separate molecules
    for file_name in os.listdir(input_dir):
        if file_name.endswith(".pdbqt"):
            input_path = os.path.join(input_dir, file_name)
            print(f"[DEBUG] Processing file for molecule separation: {input_path}")
            try:
                with open(input_path, 'r') as f:
                    content = f.read()
                print(f"[DEBUG] Separating Molecules")
                # Split molecules based on MODEL tag (AutoDock uses MODEL tag to separate)
                molecules = content.split('MODEL')
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

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Separate molecules from PDBQT files.")
    parser.add_argument('--input_dir', type=str, required=True, help='Directory containing PDBQT files.')
    parser.add_argument('--output_dir', type=str, required=True, help='Directory to store separated PDBQT files.')

    args = parser.parse_args()
    separate_molecules(args.input_dir, args.output_dir)
