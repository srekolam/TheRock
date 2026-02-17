# Dockerfile for Spack integration on Ubuntu 24.04
# This image includes Spack for ROCm package management and builds

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages
RUN apt-get update -y && apt-get install -y \
    sudo \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    file \
    unzip \
    patch \
    gfortran \
    cmake \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create spack user with sudo privileges
RUN useradd -m -s /bin/bash -U -G sudo spack
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to spack user
USER spack
WORKDIR /home/spack

# Set environment variables for Spack
ENV SPACK_ROOT=/home/spack/spack
ENV PATH="${SPACK_ROOT}/bin:${PATH}"

# Clone Spack repository
RUN git clone --depth 1 https://github.com/spack/spack.git ${SPACK_ROOT}

# Clone Spack packages repository (custom package repository)
RUN git clone --depth 1 https://github.com/spack/spack-packages.git /home/spack/spack-packages

# Initialize Spack
RUN . ${SPACK_ROOT}/share/spack/setup-env.sh && \
    spack compiler find

# Add spack-packages as a repository
RUN . ${SPACK_ROOT}/share/spack/setup-env.sh && \
    spack repo add /home/spack/spack-packages || true

# Create directory for ROCm submodule metadata
RUN mkdir -p /home/spack/rocm-metadata

# Create a helper script to update Spack repos from sync artifacts
RUN cat > /home/spack/update_spack_from_metadata.sh <<'EOF'
#!/bin/bash
set -euo pipefail

METADATA_FILE="${1:-/home/spack/rocm-metadata/sync-metadata.json}"

if [ ! -f "$METADATA_FILE" ]; then
    echo "Error: Metadata file not found: $METADATA_FILE"
    exit 1
fi

echo "Reading metadata from: $METADATA_FILE"

# Extract commit information
ROCM_SYSTEMS_COMMIT=$(jq -r '.therock_submodules.rocm_systems_commit' "$METADATA_FILE")
ROCM_LIBRARIES_COMMIT=$(jq -r '.therock_submodules.rocm_libraries_commit' "$METADATA_FILE")
AMD_LLVM_COMMIT=$(jq -r '.therock_submodules.amd_llvm_commit' "$METADATA_FILE")
HIPIFY_COMMIT=$(jq -r '.therock_submodules.hipify_commit' "$METADATA_FILE")
SPIRV_TRANSLATOR_COMMIT=$(jq -r '.therock_submodules.spirv_translator_commit' "$METADATA_FILE")

echo "TheRock submodule commits:"
echo "  rocm-systems: $ROCM_SYSTEMS_COMMIT"
echo "  rocm-libraries: $ROCM_LIBRARIES_COMMIT"
echo "  amd-llvm: $AMD_LLVM_COMMIT"
echo "  hipify: $HIPIFY_COMMIT"
echo "  spirv-llvm-translator: $SPIRV_TRANSLATOR_COMMIT"

# Save commits to individual files for easy access
echo "$ROCM_SYSTEMS_COMMIT" > /home/spack/rocm-metadata/rocm_systems_commit.txt
echo "$ROCM_LIBRARIES_COMMIT" > /home/spack/rocm-metadata/rocm_libraries_commit.txt
echo "$AMD_LLVM_COMMIT" > /home/spack/rocm-metadata/amd_llvm_commit.txt
echo "$HIPIFY_COMMIT" > /home/spack/rocm-metadata/hipify_commit.txt
echo "$SPIRV_TRANSLATOR_COMMIT" > /home/spack/rocm-metadata/spirv_translator_commit.txt

echo "Metadata processed successfully!"
EOF

RUN chmod +x /home/spack/update_spack_from_metadata.sh

# Install jq for JSON parsing
USER root
RUN apt-get update -y && apt-get install -y jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
USER spack

# Source Spack in bashrc for convenience
RUN echo ". ${SPACK_ROOT}/share/spack/setup-env.sh" >> /home/spack/.bashrc

# Set default command
CMD ["/bin/bash"]
