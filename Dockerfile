# Base image with Ubuntu
FROM ubuntu:20.04

# Set non-interactive mode to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update the system and install core dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    build-essential \
    cmake \
    git \
    python3 \
    python3-pip \
    libboost-all-dev \
    software-properties-common \
    ca-certificates \
    openbable \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh
ENV PATH="/opt/conda/bin:$PATH"

# Create Conda environment and install AutoDock Vina, RDKit, and GROMACS
COPY environment.yml /tmp/environment.yml
RUN conda update -n base -c defaults conda && \
    conda env create -f /tmp/environment.yml && \
    conda clean -a

# Install Python libraries outside of Conda (for global use)
RUN pip3 install numpy pandas matplotlib scipy

# Activate the Conda environment and install AutoDock Vina
RUN conda activate docking_env && \
    conda install -c bioconda autodock-vina && \
    conda clean -a

# Install RDKit via Conda
RUN conda activate docking_env && \
    conda install -c conda-forge rdkit && \
    conda clean -a

# Install GROMACS via Conda
RUN conda activate docking_env && \
    conda install -c bioconda gromacs && \
    conda clean -a

# Clone and install GNINA at version 1.3
RUN git clone https://github.com/gnina/gnina.git && \
    cd gnina && \
    git checkout v1.3 && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install

# Placeholder for X-Score installation
# X-Score does not have a direct Conda or APT package; need to manually download it
# RUN wget <link-to-XScore> && tar -xvf <downloaded-package>
# Please follow X-Score documentation for manual installation

# Install PyMOL (or replace with ChimeraX/LigPlot if preferred)
#RUN apt-get update && apt-get install -y pymol
#installed via conda

# Install MGLTools for preparing PDBQT files
RUN wget http://mgltools.scripps.edu/downloads/release/mgltools-1.5.6/MGLTools-1.5.6.tar.gz && \
    tar -zxvf MGLTools-1.5.6.tar.gz && \
    cd MGLTools-1.5.6 && \
    ./install.sh -d /opt/mgltools && \
    ln -s /opt/mgltools/bin/pythonsh /usr/local/bin/pythonsh && \
    ln -s /opt/mgltools/bin/prepare_ligand4.py /usr/local/bin/prepare_ligand4.py && \
    ln -s /opt/mgltools/bin/prepare_receptor4.py /usr/local/bin/prepare_receptor4.py

# Set the working directory
WORKDIR /workspace
COPY run_pipeline.sh /workspace/
COPY main.nf /workspace/
COPY scripts/ /workspace/scripts/

# Set entrypoint
ENTRYPOINT ["bash", "/workspace/run_pipeline.sh"]
