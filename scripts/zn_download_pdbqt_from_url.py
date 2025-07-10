import os
import subprocess
import argparse




def download_pdbqt_files(uri_file, output_dir):
    # Create the output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    print(f"[DEBUG] Output directory ensured: {output_dir}")

    # Read URLs from the URI file
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
                print(f"[DEBUG] Downloaded: {file_name}")
            except subprocess.CalledProcessError as e:
                print(f"[ERROR] Error downloading {file_name}: {e}")
            except Exception as e:
                print(f"[ERROR] Unexpected error downloading {file_name}: {e}")
        else:
            print(f"[DEBUG] Skipping {file_name}, already exists.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download PDBQT files from URLs in a URI file.")
    parser.add_argument('--uri_file', type=str, required=True, help='Path to the URI file containing download links.')
    parser.add_argument('--output_dir', type=str, required=True, help='Directory to store downloaded PDBQT files.')

    args = parser.parse_args()
    download_pdbqt_files(args.uri_file, args.output_dir)
