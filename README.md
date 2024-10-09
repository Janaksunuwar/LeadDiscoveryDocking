# LeadDiscoveryDocking
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
Running the Pipeline:

The Docker image is built with the command:

docker build -t lead_discovery_docking .
Once built, the container can be run with:

docker run -it --rm -v $(pwd):/workspace lead_discovery_docking

These commands initialize the pipeline within the container, running it in a controlled and reproducible environment.

# Outputs:

The pipeline generates binding affinity scores for each small molecule tested.
The top-scoring molecules are sorted, refined using GROMACS, and visualized with PyMOL.
All outputs, including docking results and visualizations, are stored within the workspace directory for easy access and analysis.

# Repository Structure
The GitHub repository contains the following files:

Dockerfile: Defines the container environment, with all necessary tools and dependencies.
environment.yml: Specifies package versions and tools for consistent Conda environment setup.
run_pipeline.sh: Runs the pipeline within the container.
main.nf: Nextflow file for automating workflow steps, if desired.
README.md: Provides an overview, installation instructions, and usage examples.

#Documentation and Usage
A detailed README includes installation steps, descriptions of each tool, and example commands to set up and run the pipeline on any compatible system. The repository is designed for researchers and developers interested in small molecule screening and protein-ligand docking, providing a comprehensive and reproducible solution.
