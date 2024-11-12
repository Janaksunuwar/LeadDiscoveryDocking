#!/usr/bin/env nextflow

Channel
    .fromPath("data/zinc/zn_test_uri.uri")
    .set { url_files }

//Testing channels' input and output settings

process testChannel {
    input:
    path url_file from url_files

    script:
    """
    echo "Testing channel with file: ${url_file}"
    """
}

process pyStuffs {

    script:
    """
    echo pwordkir $PWD
    """
}

process sayHello {
    
    script:
    """
    echo "[HeyJan] Starting sayHello process..."
    echo "hello how are you doingg?"
    """
}

process addStuff {
    
    script:
    """
    echo "[HeyJan] Starting addNUmbers process..."
    python -c "
    x = 5
    y = 10
    added = x + y
    print(f'The added value is {added}')"
    """
}

process p3 {

    script:
    """
    #!/usr/bin/env python
    print("This is awesome")
    """
}


process znDownload {
    container 'lead_discovery_docking:latest'

    input:
    path url_file from url_files

    output:
    path "data/zinc/downloaded_molecules/*" into downloaded_files

    script:
    """
    echo "[HeyJan] Starting addNUmbers process..."
    python3 scripts/test_hi.py
    """
}
 
workflow {
    testChannel()
    sayHello()
    addStuff()
    p3()
    //znDownload()
    //downloaded_files.view()
}

//WORK FROM HERE:

