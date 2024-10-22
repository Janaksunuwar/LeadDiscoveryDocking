import argparse
import os

def separate_molecules(input_dir, output_dir):
    # Iterate over each pdbqt file and separate molecules
    for file_name in os.listdir(input_dir):
        if file_name.endswith(".pdbqt"):
            print(file_name)
            input_path = os.path.join(input_dir, file_name)
            with open(input_path, 'r') as f:
                content = f.read()

            # Split molecules based on MODEL tag (AutoDock uses MODEL tag to separate)
            molecules = content.split('MODEL')
            for idx, molecule in enumerate(molecules[1:], start=1):
                molecule = 'MODEL' + molecule  # Add back the MODEL tag
                output_path = os.path.join(output_dir, f"{file_name[:-6]}_molecule_{idx}.pdbqt")
                with open(output_path, 'w') as f_out:
                    f_out.write(molecule)
                print(f"Separated molecule {idx} from {file_name} into {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Separate molecules from downloaded PDBQT files.")
    parser.add_argument("--input_dir", type=str, required=True, help="Input directory containing downloaded PDBQT files.")
    parser.add_argument("--output_dir", type=str, required=True, help="Output directory to save separated PDBQT files.")
    args = parser.parse_args()

    separate_molecules(args.input_dir, args.output_dir)

