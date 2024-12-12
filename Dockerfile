# Base image with Ubuntu
FROM ubuntu:22.04

# Set non-interactive mode to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update the system and install core dependencies
RUN apt-get update && apt-get install -y \
    unzip \
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

# Install Miniforge (Multi-architecture support)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh; \
    elif [ "$ARCH" = "aarch64" ]; then \
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh -O /tmp/miniforge.sh; \
    else \
    echo "Unsupported architecture: $ARCH"; exit 1; \
    fi && \
    chmod +x /tmp/miniforge.sh && \
    bash /tmp/miniforge.sh -b -p /opt/conda && \
    rm /tmp/miniforge.sh

# Set Miniconda path
ENV PATH="/opt/conda/bin:$PATH"

# Create Conda environment for Python-based dependencies
COPY environment.yml /tmp/environment.yml
RUN conda update -n base -c defaults conda && \
    conda env create -f /tmp/environment.yml && \
    conda clean -a

# Install Python libraries outside of Conda (for global use)
RUN pip3 install numpy pandas matplotlib scipy

# Install AutoDock Vina for different architectures
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
    wget https://github.com/ccsb-scripps/AutoDock-Vina/releases/download/v1.2.5/vina_1.2.5_linux_x86_64 -O /usr/local/bin/vina; \
    elif [ "$ARCH" = "aarch64" ]; then \
    wget https://github.com/ccsb-scripps/AutoDock-Vina/releases/download/v1.2.5/vina_1.2.5_linux_aarch64 -O /usr/local/bin/vina; \
    else \
    echo "Unsupported architecture: $ARCH"; exit 1; \
    fi && \
    chmod +x /usr/local/bin/vina

# Install RDKit manually
RUN apt-get update && apt-get install -y python3-rdkit

# Install GROMACS manually
RUN apt-get update && apt-get install -y gromacs

# Download GNINA pre-built binary
RUN wget https://github.com/gnina/gnina/releases/download/v1.3/gnina -O /usr/local/bin/gnina && \
    chmod +x /usr/local/bin/gnina

# Install PyMOL from source
RUN apt-get update && apt-get install -y \
    libglew-dev \
    libglm-dev \
    libpng-dev \
    libfreetype6-dev \
    libxml2-dev \
    libmsgpack-dev \
    libpython3-dev \
    freeglut3-dev \
    libnetcdf-dev \
    catch2 \
    qtbase5-dev \
    libqt5opengl5-dev \
    python3-pyqt5 && \
    git clone https://github.com/schrodinger/pymol-open-source.git && \
    git clone https://github.com/rcsb/mmtf-cpp.git && \
    mv mmtf-cpp/include/mmtf* pymol-open-source/include/ && \
    cd pymol-open-source && \
    pip install build && \
    pip install --verbose --no-build-isolation --config-settings testing=True .


# Install MGLTools for preparing PDBQT files
RUN wget https://ccsb.scripps.edu/download/532/ -O MGLTools-1.5.7.tar.gz && \
    tar -zxvf MGLTools-1.5.7.tar.gz && \
    cd mgltools_x86_64Linux2_1.5.7 && \
    ./install.sh -d /opt/mgltools && \
    ln -s /opt/mgltools/bin/pythonsh /usr/local/bin/pythonsh && \
    ln -s /opt/mgltools/bin/prepare_ligand4.py /usr/local/bin/prepare_ligand4.py && \
    ln -s /opt/mgltools/bin/prepare_receptor4.py /usr/local/bin/prepare_receptor4.py

# Install OpenJDK 11
RUN apt-get update && apt-get install -y openjdk-11-jdk && \
    rm -rf /var/lib/apt/lists/*



# Install Nextflow
RUN wget -qO- https://get.nextflow.io | bash && \
    mv nextflow /usr/local/bin/ && \
    chmod +x /usr/local/bin/nextflow

# Set the working directory
WORKDIR /workspace
COPY scripts/ /workspace/scripts/

# Set entrypoint
ENTRYPOINT ["bash", "/workspace/run_pipeline.sh"]