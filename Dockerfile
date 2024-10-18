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

# Create Conda environment for Python-based dependencies
COPY environment.yml /tmp/environment.yml
RUN conda update -n base -c defaults conda && \
    conda env create -f /tmp/environment.yml && \
    conda clean -a

# Install Python libraries outside of Conda (for global use)
RUN pip3 install numpy pandas matplotlib scipy

# Install a specific version of AutoDock Vina
#RUN wget https://github.com/ccsb-scripps/AutoDock-Vina/releases/download/v1.2.3/vina_1.2.3_linux_x86_64 -O /usr/local/bin/vina && \
#    chmod +x /usr/local/bin/vina

# Pull AutoDock Vina from Docker Hub
FROM ccsb-scripps/autodock-vina:latest AS vina



# Pull RDKit from Docker Hub
FROM rdkit/rdkit:latest AS rdkit



# Pull GROMACS from Docker Hub
FROM biocontainers/gromacs:latest AS gromacs

# Clone and install GNINA at version 1.3
RUN git clone https://github.com/gnina/gnina.git && \
    cd gnina && \
    git checkout v1.3 && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install

# Pull PyMOL from Docker Hub
FROM schrodinger/pymol:latest AS pymol

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

