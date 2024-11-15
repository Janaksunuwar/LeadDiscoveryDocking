#!/usr/bin/env nextflow

log.info """
    L E A D - D I S C O V E R Y  P I P E L I N E 
    ============================================
    Developed by: Janak Sunuwar, Ph.D,
    UNIVERSITY OF NORTH TEXAS HEALTH SCIENCES CENTER
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
    // First, run the downloader process
    def dwn_ch = Channel.fromPath(params.zn_dwnl_script)
    def uri_ch = Channel.fromPath(params.uri_file)
    def download_result = pdbqt_Download(dwn_ch, uri_ch)

    // Use the output from downloader to run the separator process
    separate_molecules(download_result.downloaded_files)
}

// nextflow.enable.dsl=2

// // Pipeline parameters
// params.zn_dwnl_script = "${System.getProperty('user.dir')}/scripts/zn_download_pdbqt_from_url.py"
// params.zn_separator_script = "${System.getProperty('user.dir')}/scripts/separate_molecules_from_pdbqt.py"
// params.uri_file = "${System.getProperty('user.dir')}/data/zinc/zn_test_uri.uri"
// params.zn_download_dir = "${System.getProperty('user.dir')}/data/zinc/zn_downloaded/"
// params.zn_separated_dir = "${System.getProperty('user.dir')}/data/zinc/zn_separated/"

// println "[DEBUG] URI file: ${params.uri_file}"
// println "[DEBUG] Download directory: ${params.zn_download_dir}"
// println "[DEBUG] Separated directory: ${params.zn_separated_dir}"

// // Process to download PDBQT files from given URLs
// process pdbqt_Download {
//     publishDir("${params.zn_download_dir}", mode: 'copy')
    
//     input:
//     path zn_dwnl_script
//     path uri_file

//     output:
//     path "*", emit: zn_downloaded_pdbqts


//     script:
//     """
//     python3 ${zn_dwnl_script} --uri_file ${uri_file}
//     """
// }

// // Process to separate molecules from the downloaded PDBQT files
// process separate_molecules {
    
//     publishDir("${params.zn_separated_dir}"), mode: 'copy'
    
//     input:
//     path zn_separator_script
//     path zn_download_dir

//     output:
//     path "*", emit: separated_files
 
//     script:
//     """
//     python3 ${zn_separator_script} --input_dir ${zn_download_dir}
//     """
// }

// // Workflow
// workflow {
//     // First, run the downloader process
//     def dwn_ch = Channel.fromPath(params.zn_dwnl_script)
//     def uri_ch = Channel.fromPath(params.uri_file)
    
//     // pdbqt_Download.out.zn_pdbqt_not_separated.view()

//     // Then, use the output from downloader to run the separator
//     def sep_ch= Channel.fromPath(params.zn_separator_script)
//     def zn_dwn_ch= Channel.fromPath(params.zn_download_dir)
//     pdbqt_Download(dwn_ch, uri_ch) | collect | separate_molecules(sep_ch, zn_dwn_ch)
// }





// #!/usr/bin/env nextflow

// nextflow.enable.dsl=2

// // Pipeline parameters
// params.zn_downloader_script = "${System.getProperty('user.dir')}/scripts/zn_download_pdbqt_from_url.py"
// params.zn_separator_script = "${System.getProperty('user.dir')}/scripts/separate_molecules_from_pdbqt.py"
// params.uri_file = "${System.getProperty('user.dir')}/data/zinc/zn_test_uri.uri"
// params.zn_download_dir = "${System.getProperty('user.dir')}/data/zinc/zn_downloaded/"
// params.zn_separated_dir = "${System.getProperty('user.dir')}/data/zinc/zn_separated/"

// println "[DEBUG] URI file: ${params.uri_file}"
// println "[DEBUG] Download directory: ${params.download_dir}"
// println "[DEBUG] Output directory: ${params.output_dir}"


// // Process to download PDBQT files from given URLs
// process pdbqt_Download {
//     input:
//     path zn_download_py_script

//     script:
//     """
//     python3  ${zn_download_py_script} --uri_file ${params.uri_file} --output_dir ${params.zn_download_dir}
    
//     """
// }

// //Process to separate molecules from the downloaded PDBQT files
// process separate_molecules {

//     input:
//     path separator_py_script

//     script:
//     """
//     python3 ${separator_py_script} --input_dir ${params.zn_download_dir} --output_dir ${params.zn_separated_dir}
//     """
// }

// // Workflow
// workflow {
//     def dwn_ch = Channel.fromPath (params.zn_downloader_script)
//     pdbqt_Download(dwn_ch)

//     def sep_ch = Channel.fromPath (params.zn_separator_script)
//     separate_molecules(sep_ch)
// }



// #!/usr/bin/env nextflow

// nextflow.enable.dsl=2

// // Pipeline parameters
// params.uri_file = "./data/zinc/zn_test_uri.uri"
// params.output_dir = "${System.getProperty('user.dir')}/data/zinc/test_fold/"
// params.script_path = "${System.getProperty('user.dir')}/scripts/zinc_download_pdbqt_from_url.py"

// println "[DEBUG] URI file: ${params.uri_file}"
// println "[DEBUG] Output directory: ${params.output_dir}"
// println "[DEBUG] Script path: ${params.script_path}"

// // Process to download PDBQT files from given URLs
// process znDownload {

//     input:
//     path uri_file

//     output:
//     path downloaded_files
//     publishDir params.output_dir, mode: 'copy'

//     script:
//     """
//     echo "Current Directory: $PWD"

//     wget 'http://files.docking.org/3D/BA/AAML/BAAAML.xaa.pdbqt.gz', '-O', './data/zinc/test_fold/BAAAML.xaa.pdbqt.gz'

//     python3 ${params.script_path} --uri_file ${uri_file} --output_dir ${params.output_dir}
//     """
// }

// // Workflow
// workflow {
//     def zn_ch = Channel.fromPath(params.uri_file)
//     znDownload(zn_ch)
// }


// #!/usr/bin/env nextflow

// nextflow.enable.dsl=2

// // Pipeline parameters
// params.output_dir = "${System.getProperty('user.dir')}/output/"

// println "[DEBUG] Output directory: ${params.output_dir}"

// // Create a channel from the shell script path
// // hello_script_channel = Channel.fromPath("./scripts/hello_world.sh")

// // Process to run a shell script that reads the content of hello_world.sh and outputs it
// process runHelloWorld {
//     input:
//     path x
    
//     output:
//     path "hello_output.txt"

//     publishDir params.output_dir, mode: 'copy'

//     script:
//     """
//     bash ${x} > hello_output.txt
//     """
// }

// workflow {
//     def proteins = Channel.fromPath("./scripts/hello_world.sh")
//     runHelloWorld(proteins)
// }





// #!/usr/bin/env nextflow

// nextflow.enable.dsl=2

// // Pipeline parameters
// params.uri_file = "./data/zinc/zn_test_uri.uri"
// params.output_dir = "./data/zinc/test_fold/"

// println "[DEBUG] URI file: ${params.uri_file}"
// println "[DEBUG] Output directory: ${params.output_dir}"

// // Channel for the URI file
// uri_channel = Channel.fromPath(params.uri_file)

// // Process to download PDBQT files from given URLs
// process znDownload {

//     input:
//     path uri_file from uri_channel

//     output:
//     path "${params.output_dir}/*" into separated_files

//     script:
//     """
//     python3 ./scripts/zinc_download_pdbqt_from_url.py --uri_file ${uri_file} --output_dir ${params.output_dir}
//     """
// }

// // Workflow
// workflow {
//     znDownload()
//     separated_files.view()
// }



// #!/usr/bin/env nextflow

// nextflow.enable.dsl=2

// // Pipeline input parameters
// params.uris = "Amit_Dr_Vishownatha/Docking_Pipeline/recov_LDTest/scripts/zinc_download_pdbqt_from_url.py"
// params.outdir = "Amit_Dr_Vishownatha/Docking_Pipeline/recov_LDTest/data/zinc/zinc_down/"
// "

// println "Here is the path to the zn URIS: $params.uris"
// println "Here is the path to the downlaoded pdbqt: $params.outdir"


// // Download pdbqt files from zn URLs prepared from zn database separately
// process znDownload {

   

//     script:
//     """
//     mkdir -p test_folder
    
//     """
// }

// // Workflow
// workflow {

//     zn_download_ch = znDownload()
// }


// // python3 ./scripts/zinc_download_pdbqt_from_url.py --uri_file ${zn_uris} --output_dir zn_downloaded_pdbqt/

// python3 Amit_Dr_Vishownatha/Docking_Pipeline/recov_LDTest/scripts/zinc_download_pdbqt_from_url.py --uri_file /Users/js1349/Desktop/UNTHSC/HSC_Janak/Amit_Dr_Vishownatha/Docking_Pipeline/recov_LDTest/data/zinc/zn_test_uri.uri --output_dir Amit_Dr_Vishownatha/Docking_Pipeline/recov_LDTest/data/zinc/zinc_down




// //pipeline input parameters
// params.uris = "./data/zinc/zn_test_uri.uri"
// params.outdir = "output"
// println "Here is the path to the zn URIS: $params.uris"


// //log info for display
// log.info """
//     L E A D - D I S C O V E R Y  P I P E L I N E 
//     ============================================
//     Developed by: Janak Sunuwar, Ph.D,
//     UNIVERSITY OF NORTH TEXAS HEALTH SCIENCES CENTER
//     @2024

//     WRITE SOME INFO HERE

//     Pdbqt files download for zinc dabatas is from uris file: ${params.uris}
//     outdir: ${params.outdir}
//     """
//     .stripIndent(true)

// //download pdbqt files from zn urls prepared from zn database separately
// process znDonwload {

//     input:
//     file zn_uri

//     output:
//     path zn_downloaded_pdbqt

//     script:
//     """
//     python3 ./scripts/zinc_download_pdbqt_from_url.py --uri_file  $zn_uri --output_dir $zn_downloaded_pdbqt
//     """
// }

// //workflow
// workflow {

//     zn_download_ch = znDonwload (params.uris)
//     zn_download_ch.view()
// }








// params.greetings = 'Hello Janak'
// greeting_ch = Channel.of(params.greetings)


// process SPLITLETTERS {
//     input:
//     val x

//     output:
//     path 'chunk_*'

//     script:
//     """
//     printf '$x' | split -b 6 - chunk_
//     """
// }


// process CONVERTTOUPPER {
//     input:
//     path y

//     output:
//     stdout

//     script:
//     """
//     cat $y | tr '[a-z]' '[A-z]'
//     """

// }

// workflow {
//     letters_ch = SPLITLETTERS(greeting_ch)
//     // letters_ch.view{ it }
//     result_ch = CONVERTTOUPPER(letters_ch.flatten())
//     result_ch.view { it }
// }



   
// process fastqc {
//     input:
//     path input

//     output:
//     path "*_fastqc.{zip, html}"

//     script:
//     """
//     fastqc -q $input
//     """
// }

// workflow {
//     Channel.fromPath("*.fastq.gz") | fastqc
// }





// uris = Channel.fromPath('./data/zinc/zn_test_uri.uri')


// process znDownload {
//     input:
//     path file

//     output:
//     //path to download the pdbqt files

//     script:
//     """
//     echo my alignment $file

//     """

// }


// workflow {
//     znDownload(uris)
// }

