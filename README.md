# LeadDiscoveryDocking in progress
The LeadDiscoveryDocking pipeline is designed for high-throughput screening, scoring, and refinement of small molecule leads for protein-ligand docking. This pipeline is containerized using Docker to ensure reproducibility and compatibility across various systems, including macOS, Linux, and cloud environments.

## Pipeline Workflow Overview
Docker Installation:
Install Docker on any system that lacks it. This enables containerization, allowing for isolated environments where the entire pipeline can be run consistently.

Environment Setup with Conda:
The pipeline uses a Conda environment to manage dependencies. The environment.yml file specifies all required tools and libraries, including AutoDock Vina, RDKit, GROMACS, and PyMOL.
All software dependencies and Python libraries (like numpy, pandas, matplotlib, and scipy) are installed via Conda to maintain version consistency and reproducibility.

# Core Components:

AutoDock Vina: Performs high-throughput docking to identify initial binding poses for small molecule leads.

RDKit: Provides chemical informatics capabilities for molecular manipulation, scoring, and filtering of docked poses.

GROMACS: Used for molecular dynamics simulations, enabling the refinement and stability analysis of top docking poses.

GNINA: Enhances scoring and docking accuracy with deep learning-based predictions, particularly for protein-ligand interactions.

PyMOL: Visualizes and customizes the binding poses and protein-ligand interactions, providing publication-quality images.


