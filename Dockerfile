# Base image with Ubuntu
FROM ubuntu:22.04

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
    libeigen3-dev \
    libgoogle-glog-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libhdf5-dev \
    libatlas-base-dev \
    python3-dev \
    librdkit-dev \
    python3-numpy \
    python3-pip \
    python3-pytest \
    libjsoncpp-dev \
    openbabel \
    && rm -rf /var/lib/apt/lists/*

# Add Kitware Repo for cmake
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg && \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | apt-key add - && \
    apt-add-repository 'deb https://apt.kitware.com/ubuntu/ jammy main' && \
    apt-get update && apt-get install -y cmake

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    chmod +x /tmp/miniconda.sh && \
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

# Install AutoDock Vina via Conda
RUN conda install -c bioconda autodock-vina

# Install RDKit manually
RUN apt-get update && apt-get install -y python3-rdkit

# Install GROMACS manually
RUN apt-get update && apt-get install -y gromacs

# Download GNINA pre-built binary
RUN wget https://github.com/gnina/gnina/releases/download/v1.3/gnina -O /usr/local/bin/gnina && \
    chmod +x /usr/local/bin/gnina

# Install PyMOL manually in the Dockerfile
RUN apt-get update && apt-get install -y pymol

# Placeholder for X-Score installation
# X-Score does not have a direct Conda or APT package; need to manually download it
# RUN wget <link-to-XScore> && tar -xvf <downloaded-package>
# Please follow X-Score documentation for manual installation

# Install PyMOL (or replace with ChimeraX/LigPlot if preferred)
#RUN apt-get update && apt-get install -y pymol
#installed via conda

# Install MGLTools for preparing PDBQT files
RUN wget https://ccsb.scripps.edu/download/532/ -O MGLTools-1.5.7.tar.gz && \
    tar -zxvf MGLTools-1.5.7.tar.gz && \
    cd mgltools_x86_64Linux2_1.5.7 && \
    ./install.sh -d /opt/mgltools && \
    ln -s /opt/mgltools/bin/pythonsh /usr/local/bin/pythonsh && \
    ln -s /opt/mgltools/bin/prepare_ligand4.py /usr/local/bin/prepare_ligand4.py && \
    ln -s /opt/mgltools/bin/prepare_receptor4.py /usr/local/bin/prepare_receptor4.py

# Set the working directory
WORKDIR /workspace
COPY scripts/main.nf /workspace/

# Set entrypoint
ENTRYPOINT ["bash", "/workspace/run_pipeline.sh"]

