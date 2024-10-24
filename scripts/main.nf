params.databases = ["zinc", "chembl", "drugbank"] // List your databases
params.protein = "protein.pdb"

// Creating the input channel for databases
Channel.from(params.databases)
    .set { database_list }

// Process to download molecules
process download_molecules {
    input:
    val db from database_list

    output:
    path "data/${db}/${db}_downloaded_pdbqt/" into downloaded_dirs

    script:
    if (db == "zinc") {
        """
        mkdir -p data/zinc/${db}_downloaded_pdbqt/
        python scripts/zinc_download_pdbqt_from_url.py --data/zinc/uri_file data/zinc/ZINC-downloader-3D-pdbqt.gz.uri --output data/zinc/${db}_downloaded_pdbqt/
        """
    } else if (db == "chembl") {
        """
        # Placeholder for ChemBL download script
        mkdir -p data/chembl/${db}_downloaded_pdbqt
        echo "Downloading ChemBL data..." > data/chembl/${db}_downloaded_pdbqt/${db}_chembl_placeholder.pdbqt
        """
    } else if (db == "drugbank") {
        """
        # Placeholder for DrugBank download script
        mkdir -p data/drugbank/${db}_downloaded_pdbqt
        echo "Downloading DrugBank data..." > data/drugbank/${db}_downloaded_pdbqt/${db}_drugbank_placeholder.pdbqt
        """
    }
}

// Process to separate molecules
process separate_molecules {
    input:
    path input_dir from downloaded_dirs

    output:
    path "data/${input_dir.getBaseName()}_split_pdbqt/" into separated_dirs

    script:
    """
    mkdir -p data/${input_dir.getBaseName()}_split_pdbqt/
    python scripts/pdbqt_separator.py --input_dir ${input_dir} --output_dir data/${input_dir.getBaseName()}_split_pdbqt/
    """
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

