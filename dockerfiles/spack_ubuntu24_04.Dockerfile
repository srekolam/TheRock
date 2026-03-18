# Dockerfile for Spack integration on Ubuntu 24.04
# This image includes Spack for ROCm package management and builds

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install all system dependencies in one layer
RUN apt-get update -y && apt-get install -y \
    sudo \
    curl \
    wget \
    git \
    jq \
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

# Create spack user with passwordless sudo
RUN useradd -m -s /bin/bash -U -G sudo spack && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER spack
WORKDIR /home/spack

ENV SPACK_ROOT=/home/spack/spack \
    SPACK_ENV_NAME=rocm
ENV PATH="${SPACK_ROOT}/bin:${PATH}"

# Clone Spack and the ROCm package repository
RUN git clone --depth 1 https://github.com/spack/spack.git ${SPACK_ROOT} && \
    git clone --depth 1 https://github.com/ROCm/rocm-spack-packages.git /home/spack/spack-packages

# Bootstrap Spack: detect compilers and register the ROCm package repo
RUN . ${SPACK_ROOT}/share/spack/setup-env.sh && \
    spack compiler find && \
    spack repo add /home/spack/spack-packages

# Create the named environment and install all ROCm-tagged packages
COPY --chown=spack:spack rocm-spack-env/spack.yaml /home/spack/rocm-spack-env/spack.yaml
RUN . ${SPACK_ROOT}/share/spack/setup-env.sh && \
    spack env create ${SPACK_ENV_NAME} /home/spack/rocm-spack-env/spack.yaml && \
    spack env activate ${SPACK_ENV_NAME} && \
    spack list -t rocm | tail -n +2 | tr '  ' '\n' | grep -v '^$' | \
        xargs -I{} spack add {} && \
    spack buildcache keys --install --trust && \
    spack concretize -f && \
    spack install --fail-fast

# Activate the environment for interactive sessions
RUN echo ". ${SPACK_ROOT}/share/spack/setup-env.sh" >> /home/spack/.bashrc && \
    echo "spack env activate ${SPACK_ENV_NAME}" >> /home/spack/.bashrc

# Create directory and helper script for ROCm submodule metadata
RUN mkdir -p /home/spack/rocm-metadata
COPY --chown=spack:spack rocm-spack-env/update_spack_from_metadata.sh /home/spack/update_spack_from_metadata.sh
RUN chmod +x /home/spack/update_spack_from_metadata.sh

# Entrypoint activates the spack environment for all commands
COPY --chown=spack:spack rocm-spack-env/entrypoint.sh /home/spack/entrypoint.sh
RUN chmod +x /home/spack/entrypoint.sh

ENTRYPOINT ["/home/spack/entrypoint.sh"]
CMD ["/bin/bash"]
