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
params.pubchem_url_file = "${System.getProperty('user.dir')}/data/pubchem/sdf_urls_full.txt"

params.zn_separator_script = "${System.getProperty('user.dir')}/scripts/separate_molecules_from_pdbqt.py"
params.zn_separated_dir = "${System.getProperty('user.dir')}/data/zinc/zn_separated/"

params.bindingdb_download_dir = "${System.getProperty('user.dir)}/data/bindingdb/"

// download zn sdf from uri link downloaded from zn db
process zn_Download {
    publishDir("${params.zn_download_dir}", mode: 'copy')
    
    input:
    path uri_file

    output:
    path "*.sdf", emit: zn_downloaded_sdf

    script:
    """
    echo "process zn_Download"
    echo "wgetting zn sdf from ZN db"

    wget -i ${uri_file} 

    gunzip *.sdf.gz
    
    echo "Zn SDF downloaded using the uri"
    """

}

process bindingdb_download {
    publishDir("${params.bindingdb_download_dir}", mode: 'copy')

    output:
    path "*.sdf", emit: bindingdb_downloaded_sdf

    script:
    """
    echo "process wget bindingdb"

    wget -i https://www.bindingdb.org/bind/downloads/BindingDB_All_3D_202411_sdf.zip

    """
}
//download sdf from chembl with wget and the ftp link provided in the website
process chembl_download {
    publishDir("${params.chembl_download_dir}", mode: 'copy')

    output:
    path "*.sdf", emit: chembl_downloaded_sdf

    script:
    """
    echo "process chembl_download"
    echo "wgetting chembl sdf from CheEMBL db"
    wget https://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBLdb/releases/chembl_34/chembl_34.sdf.gz

    gunzip *.sdf.gz

    echo "downloaded chembl sdf from CheEMBL db and unzipped"

    """
}
//download pubchem sdf using the bash script
process pubchem_download {
    publishDir "${params.pubchem_download_dir}", mode: 'copy'

    output:
    path "*.sdf", emit: sdf_files

    script:
    """
    #!/bin/bash
    set -e  # Exit immediately if a command exits with a non-zero status

    echo "process pubchem_download"
    echo "Starting download of HTML listing"
    curl -s https://ftp.ncbi.nlm.nih.gov/pubchem/Compound/CURRENT-Full/SDF/ > pubchem_listing.html
    echo "HTML listing downloaded"

    echo "Extracting .sdf.gz links"
    grep -oE 'Compound_[0-9]+_[0-9]+\\.sdf\\.gz' pubchem_listing.html | sort -u > sdf_urls.txt
    echo "Extraction complete"

    echo "Adding base URL to links"
    # This version is cross-compatible with macOS and Linux
    sed -e 's#^#https://ftp.ncbi.nlm.nih.gov/pubchem/Compound/CURRENT-Full/SDF/#' sdf_urls.txt > sdf_urls_full.txt
    echo "Base URL added"

    echo "Downloading .sdf.gz files"
    wget -i sdf_urls_full.txt
    echo "Download complete"

    echo "Unzipping .sdf.gz files"
    gunzip *.sdf.gz
    echo "Unzip complete"
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

    bindingdb_download()
    
    }
