from rdkit import Chem
from rdkit.Chem import AllChem
import subprocess
import os
import sys

def sdf_to_pdb(sdf_file, pdb_file):
    # Load the SDF file
    suppl = Chem.SDMolSupplier(sdf_file)
    mol = suppl[0]  # Assuming one molecule per SDF file
    if mol is None:
        print(f"Failed to load molecule from {sdf_file}")
        return False
    
    # Add hydrogens and generate 3D coordinates
    mol = Chem.AddHs(mol)
    AllChem.EmbedMolecule(mol)
    AllChem.UFFOptimizeMolecule(mol)
    
    # Write the PDB file
    Chem.MolToPDBFile(mol, pdb_file)
    print(f"Converted {sdf_file} to {pdb_file}")
    return True

def pdb_to_pdbqt(pdb_file, pdbqt_file):
    # Use MGLTools to convert PDB to PDBQT
    command = f"pythonsh /usr/local/bin/prepare_ligand4.py -l {pdb_file} -o {pdbqt_file}"
    subprocess.run(command, shell=True, check=True)
    print(f"Converted {pdb_file} to {pdbqt_file}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python convert_ligands.py <input_sdf_file> <output_pdbqt_file>")
        sys.exit(1)

    input_sdf = sys.argv[1]
    output_pdbqt = sys.argv[2]
    intermediate_pdb = os.path.splitext(output_pdbqt)[0] + ".pdb"

    # Convert SDF to PDB
    if sdf_to_pdb(input_sdf, intermediate_pdb):
        # Convert PDB to PDBQT
        pdb_to_pdbqt(intermediate_pdb, output_pdbqt)
        # Remove the intermediate PDB file if desired
        os.remove(intermediate_pdb)

