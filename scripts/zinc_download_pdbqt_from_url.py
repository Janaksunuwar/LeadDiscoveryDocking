import os
import subprocess
import gzip
import shutil
# from tqdm import tqdm

def download_pdbqt_files(uri_file, output_dir):
    # Create the output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    print(f"[DEBUG] Output directory ensured: {output_dir}")
    print(f"[DEBUG] Current working directory: {os.getcwd()}")

    # Read URLs from the uri file
    with open(uri_file, 'r') as file:
        urls = file.readlines()
    print(f"[DEBUG] Total URLs to process: {len(urls)}")

    # Iterate over each URL and download using wget
    for url in urls:
        url = url.strip()
        if not url:
            print(f"[DEBUG] Skipping empty line in URI file.")
            continue
        file_name = os.path.basename(url)
        output_path = os.path.join(output_dir, file_name)

        print(f"[DEBUG] Processing URL: {url}")
        if not os.path.exists(output_path):
            try:
                # Run wget command to download the file
                subprocess.run(["wget", url, "-O", output_path], check=True)
                print(f"Downloaded: {file_name}")
                print(f"[DEBUG] File saved at: {output_path}")
            except subprocess.CalledProcessError as e:
                print(f"Error downloading {file_name}: {e}")
            except Exception as e:
                print(f"Unexpected error downloading {file_name}: {e}")
        else:
            print(f"Skipping {file_name}, already exists.")

        # Unzip the .gz file if it was downloaded successfully
        if output_path.endswith(".gz") and os.path.exists(output_path):
            try:
                decompressed_path = output_path[:-3]  # Remove .gz extension
                with gzip.open(output_path, 'rb') as f_in:
                    with open(decompressed_path, 'wb') as f_out:
                        shutil.copyfileobj(f_in, f_out)
                print(f"Unzipped: {decompressed_path}")

                # Remove the .gz file after unzipping
                os.remove(output_path)
                print(f"Removed: {output_path}")
            except Exception as e:
                print(f"Error unzipping {file_name}: {e}")

def separate_molecules(input_dir):
    print(f"[DEBUG] Starting molecule separation in directory: {input_dir}")
    # Iterate over each pdbqt file and separate molecules
    for file_name in os.listdir(input_dir):
        if file_name.endswith(".pdbqt"):
            input_path = os.path.join(input_dir, file_name)
            print(f"[DEBUG] Processing file for molecule separation: {input_path}")
            try:
                with open(input_path, 'r') as f:
                    content = f.read()

                # Split molecules based on MODEL tag (AutoDock uses MODEL tag to separate)
                molecules = content.split('MODEL')
                for idx, molecule in enumerate(molecules[1:], start=1):
                    molecule = 'MODEL' + molecule  # Add back the MODEL tag
                    output_path = os.path.join(input_dir, f"{file_name[:-6]}_molecule_{idx}.pdbqt")
                    with open(output_path, 'w') as f_out:
                        f_out.write(molecule)
                    print(f"Separated molecule {idx} from {file_name} into {output_path}")
            except Exception as e:
                print(f"Error processing file {file_name} for molecule separation: {e}")

def main(uri_file, output_dir):
    print(f"[DEBUG] Starting main function with uri_file: {uri_file}, output_dir: {output_dir}")
    # Download PDBQT files from the uri file
    download_pdbqt_files(uri_file, output_dir)

    # Separate molecules from each downloaded PDBQT file
    separate_molecules(output_dir)

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Download PDBQT files and separate molecules.")
    parser.add_argument('--uri_file', type=str, required=True, help='Path to the URI file containing download links.')
    parser.add_argument('--output_dir', type=str, required=True, help='Directory to store downloaded and separated PDBQT files.')

    args = parser.parse_args()
    main(args.uri_file, args.output_dir)

