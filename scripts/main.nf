params.databases = ["zinc", "chembl", ...] // List your databases
params.protein = "protein.pdb"

process download_molecules {
    input:
    val db from params.databases

    output:
    path "${db}_molecules.sdf"

    """
    python download_script.py --database ${db} --output ${db}_molecules.sdf
    """
}

process autodock_vina {
    input:
    path "${db}_molecules.sdf" from download_molecules.output
    path params.protein

    output:
    path "${db}_vina_output.pdbqt"

    """
    autodock_vina --receptor ${params.protein} --ligand ${db}_molecules.sdf --out ${db}_vina_output.pdbqt
    """
}

process gnina {
    input:
    path "${db}_vina_output.pdbqt"

    output:
    path "${db}_gnina_output.pdbqt"

    """
    gnina --receptor ${params.protein} --ligand ${db}_vina_output.pdbqt --out ${db}_gnina_output.pdbqt
    """
}

process gromacs {
    input:
    path "${db}_gnina_output.pdbqt"

    output:
    path "${db}_gromacs_output"

    """
    gmx mdrun -s topol.tpr -o ${db}_gromacs_output
    """
}

workflow {
    download_molecules | autodock_vina | gnina | gromacs
}

