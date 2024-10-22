params.databases = ["zinc", "chembl", "drugbank"] // List your databases
params.protein = "protein.pdb"

process download_molecules {
    input:
    val db from params.databases

    output:
    path "data/zinc/${db}_downloaded_pdbqt/"

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
process separate_molecules {
    input:
    path input_dir from download_molecules.output

    output:
    path "data/zinc/${input_dir.getName()}_split_pdbqt/"

    script:
    """
    mkdir -p data/zinc/${input_dir.getName()}_split_pdbqt/
    python scripts/pdbqt_separator.py --input_dir ${input_dir} --output_dir data/zinc/${input_dir.getName()}_split_pdbqt/
    """
}

process autodock_vina {
    input:
    path "data/zinc/${db}_downloaded_pdbqt/" from download_molecules.output
    path params.protein

    output:
    path "${db}_vina_output.pdbqt"

    """
    autodock_vina --receptor ${params.protein} --ligand data/zinc/${db}_downloaded_pdbqt/*.pdbqt --out ${db}_vina_output.pdbqt
    """
}

process gnina {
    input:
    path "${db}_vina_output.pdbqt" from autodock_vina.output

    output:
    path "${db}_gnina_output.pdbqt"

    """
    gnina --receptor ${params.protein} --ligand ${db}_vina_output.pdbqt --out ${db}_gnina_output.pdbqt
    """
}

process gromacs {
    input:
    path "${db}_gnina_output.pdbqt" from gnina.output

    output:
    path "${db}_gromacs_output"

    """
    gmx mdrun -s topol.tpr -o ${db}_gromacs_output
    """
}

workflow {
    download_molecules | autodock_vina | gnina | gromacs
}

