#!/usr/bin/env nextflow

log.info """
    L E A D - D I S C O V E R Y  P I P E L I N E 
    ============================================
    Developed by: Janak Sunuwar, Ph.D,
    UNIVERSITY OF NORTH TEXAS HEALTH SCIENCES CENTER, Fort Worth, TX
    @2024

    """  
// Pipeline parameters
params.zn_dwnl_script = "${System.getProperty('user.dir')}/scripts/zn_download_pdbqt_from_url.py"
params.zn_separator_script = "${System.getProperty('user.dir')}/scripts/separate_molecules_from_pdbqt.py"
params.uri_file = "${System.getProperty('user.dir')}/data/zinc/zn_test_uri.uri"
params.zn_download_dir = "${System.getProperty('user.dir')}/data/zinc/zn_downloaded/"
params.zn_separated_dir = "${System.getProperty('user.dir')}/data/zinc/zn_separated/"

println "[DEBUG] URI file: ${params.uri_file}"
println "[DEBUG] Download directory: ${params.zn_download_dir}"
println "[DEBUG] Separated directory: ${params.zn_separated_dir}"

// Process to download PDBQT files from given URLs
process pdbqt_Download {
    publishDir("${params.zn_download_dir}", mode: 'copy')
    
    input:
    path zn_dwnl_script
    path uri_file

    output:
    path "*.pdbqt", emit: downloaded_files

    script:
    """
    python3 ${zn_dwnl_script} --uri_file ${uri_file}
    """
}
// Process to separate molecules from the downloaded PDBQT files
process separate_molecules {
    publishDir(params.zn_separated_dir, mode: 'copy')
    
    input:
    path pdbqt_unseparated_files


    output:
    path "*.pdbqt", emit: separated_files
 
    script:
    """
    python3 ${params.zn_separator_script} --input_files ${pdbqt_unseparated_files} 
    """
}

// Channel to hold the separated directories
//WORK FROM HERE .....
// PASS The pdbqt files to AUTODOCK VINA..
// IMPORT OUR PROTEIN OF INTEREST


workflow {
    // First, run the downloader process
    def dwn_ch = Channel.fromPath(params.zn_dwnl_script)
    def uri_ch = Channel.fromPath(params.uri_file)
    def download_result = pdbqt_Download(dwn_ch, uri_ch)

    // Use the output from downloader to run the separator process
    separate_molecules(download_result.downloaded_files)
}


// Process to run AutoDock Vina
process autodock_vina {
    input:
    path split_dir from separated_dirs
    path params.protein

    output:
    path "${split_dir.getBaseName()}_vina_output.pdbqt" into vina_outputs

    script:
    """
    autodock_vina --receptor ${params.protein} --ligand ${split_dir}/*.pdbqt --out ${split_dir.getBaseName()}_vina_output.pdbqt
    """
}


// Process to run GNINA
process gnina {
    input:
    path vina_output from vina_outputs

    output:
    path "${vina_output.getBaseName()}_gnina_output.pdbqt" into gnina_outputs

    script:
    """
    gnina --receptor ${params.protein} --ligand ${vina_output} --out ${vina_output.getBaseName()}_gnina_output.pdbqt
    """
}


// Process to run GROMACS
process gromacs {
    input:
    path gnina_output from gnina_outputs

    output:
    path "${gnina_output.getBaseName()}_gromacs_output"

    script:
    """
    gmx mdrun -s topol.tpr -o ${gnina_output.getBaseName()}_gromacs_output
    """
}

// Workflow definition
workflow {
    download_molecules | separate_molecules | autodock_vina | gnina | gromacs
}