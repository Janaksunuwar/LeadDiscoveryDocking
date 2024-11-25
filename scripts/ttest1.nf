#!/usr/bin/env nextflow

log.info """
    L E A D - D I S C O V E R Y  P I P E L I N E 
    ============================================
    Developed by: Janak Sunuwar, Ph.D,
    UNIVERSITY OF NORTH TEXAS HEALTH SCIENCES CENTER
    @2024

    """

// Pipeline parameters

params.uri_file = "${System.getProperty('user.dir')}/data/zinc/zn_test_uri.uri"
params.zn_download_dir = "${System.getProperty('user.dir')}/data/zinc/"
params.chembl_download_dir = "${System.getProperty('user.dir')}/data/chembl/"
params.pubchem_download_dir = "${System.getProperty('user.dir')}/data/pubchem/"

params.zn_separator_script = "${System.getProperty('user.dir')}/scripts/separate_molecules_from_pdbqt.py"
params.zn_separated_dir = "${System.getProperty('user.dir')}/data/zinc/zn_separated/"

// download zn sdf from uri link downloaded from zn db
process zn_Download {
    publishDir("${params.zn_download_dir}", mode: 'copy')
    
    input:
    path uri_file

    output:
    path "*.txt", emit: zn_downloaded_sdf

    script:
    """
    wget -i ${uri_file} 
    
    """

}
//download sdf from chembl with wget and the ftp link provided in the website
process chembl_download {
    publishDir("${params.chembl_download_dir}", mode: 'copy')

    output:
    path "*.sdf", emit: chembl_downloaded_sdf

    script:
    """
    wget https://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBLdb/releases/chembl_34/chembl_34.sdf.gz

    gunzip *.sdf.gz

    """
}

//download pubchem sdf using the bash script
process pubchem_download {
    publishDir "${params.pubchem_download_dir}", mode: 'copy'

    output:
    path "*.sdf", emit: sdf_files
    path "pubchem_listing.html", emit: html_listing, optional: true
    path "sdf_urls.txt", emit: url_list, optional: true
    path "*.sdf.gz", emit: compressed_sdf, optional: true

    script:

    """
    #!/bin/bash
    set -e  # Exit immediately if a command exits with a non-zero status

    # Download HTML listing
    curl -s https://ftp.ncbi.nlm.nih.gov/pubchem/Compound/CURRENT-Full/SDF/ > pubchem_listing.html

    # Extract all .sdf.gz links
    grep -oE 'Compound_[0-9]+_[0-9]+\.sdf\.gz' pubchem_listing.html | sort -u > sdf_urls.txt

    # Add base URL to each extracted link
    sed -i 's|^|https://ftp.ncbi.nlm.nih.gov/pubchem/Compound/CURRENT-Full/SDF/|' sdf_urls.txt

    # Download all unique .sdf.gz files with resume capability
    wget -c -i sdf_urls.txt

    # Unzip all .sdf.gz files
    gunzip *.sdf.gz
    """
}


// Process to separate molecules from the downloaded PDBQT files
process separate_molecules {
    publishDir(params.zn_separated_dir, mode: 'copy')
    
    input:
    path gz_files


    output:
    path "*.pdbqt", emit: separated_files
 
    script:
    """
    python3 ${params.zn_separator_script} --input_files ${gz_files} 
    """
}


// Workflow
workflow {
    def zn_uri_ch = Channel.fromPath(params.uri_file)
    zn_Download(zn_uri_ch)

    chembl_download()

    pubchem_download()

}