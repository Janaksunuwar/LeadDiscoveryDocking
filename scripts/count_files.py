import os

def count_files_in_directory(directory):
    """
    Counts the number of files in the specified directory and its subdirectories.
    """
    try:
        file_count = sum(len(files) for _, _, files in os.walk(directory))
        print(f"Total files in '{directory}': {file_count}")
        return file_count
    except Exception as e:
        print(f"Error counting files: {e}")
        return 0

if __name__ == "__main__":
    # Example usage
    directory = "C:\\path\\to\\your\\directory"  # Replace with your Windows directory path
    count_files_in_directory(directory)
