import os
import subprocess
import gzip
import shutil
from tqdm import tqdm

def download_pdbqt_files(uri_file, output_dir):
    # Create the output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)

    # Read URLs from the uri file
    with open(uri_file, 'r') as file:
        urls = file.readlines()

    # Iterate over each URL and download using wget
    for url in tqdm(urls, desc="Downloading PDBQT files"):
        url = url.strip()
        if not url:
            continue
        file_name = url.split('/')[-1]
        output_path = os.path.join(output_dir, file_name)
        if not os.path.exists(output_path):
            try:
                # Run wget command to download the file
                subprocess.run(["wget", url, "-O", output_path], check=True)
                print(f"Downloaded: {file_name}")
            except subprocess.CalledProcessError as e:
                print(f"Error downloading {file_name}: {e}")
        else:
            print(f"Skipping {file_name}, already exists.")

        # Unzip the .gz file if it was downloaded successfully
        if output_path.endswith(".gz") and os.path.exists(output_path):
            try:
                with gzip.open(output_path, 'rb') as f_in:
                    decompressed_path = output_path[:-3]  # Remove .gz extension
                    with open(decompressed_path, 'wb') as f_out:
                        shutil.copyfileobj(f_in, f_out)
                    print(f"Unzipped: {decompressed_path}")
                # Remove the .gz file after unzipping
                os.remove(output_path)
                print(f"Removed: {output_path}")
            except Exception as e:
                print(f"Error unzipping {file_name}: {e}")

def main():
    # Update paths to be relative to the user's home directory to avoid read-only file system issues
    uri_file = os.path.expanduser("./data/zinc/ZINC-downloader-3D-pdbqt.gz.uri")
    output_dir = os.path.expanduser("./data/zinc/zinc_downloaded_pdbqt")

    # Download PDBQT files from the uri file
    download_pdbqt_files(uri_file, output_dir)

if __name__ == "__main__":
    main()
