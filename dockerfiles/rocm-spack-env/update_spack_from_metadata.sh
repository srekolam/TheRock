#!/bin/bash
set -euo pipefail

METADATA_FILE="${1:-/home/spack/rocm-metadata/sync-metadata.json}"

if [ ! -f "$METADATA_FILE" ]; then
    echo "Error: Metadata file not found: $METADATA_FILE"
    exit 1
fi

echo "Reading metadata from: $METADATA_FILE"

ROCM_SYSTEMS_COMMIT=$(jq -r '.therock_submodules.rocm_systems_commit' "$METADATA_FILE")
ROCM_LIBRARIES_COMMIT=$(jq -r '.therock_submodules.rocm_libraries_commit' "$METADATA_FILE")
AMD_LLVM_COMMIT=$(jq -r '.therock_submodules.amd_llvm_commit' "$METADATA_FILE")
HIPIFY_COMMIT=$(jq -r '.therock_submodules.hipify_commit' "$METADATA_FILE")
SPIRV_TRANSLATOR_COMMIT=$(jq -r '.therock_submodules.spirv_translator_commit' "$METADATA_FILE")

echo "TheRock submodule commits:"
echo "  rocm-systems:          $ROCM_SYSTEMS_COMMIT"
echo "  rocm-libraries:        $ROCM_LIBRARIES_COMMIT"
echo "  amd-llvm:              $AMD_LLVM_COMMIT"
echo "  hipify:                $HIPIFY_COMMIT"
echo "  spirv-llvm-translator: $SPIRV_TRANSLATOR_COMMIT"

echo "$ROCM_SYSTEMS_COMMIT"      > /home/spack/rocm-metadata/rocm_systems_commit.txt
echo "$ROCM_LIBRARIES_COMMIT"    > /home/spack/rocm-metadata/rocm_libraries_commit.txt
echo "$AMD_LLVM_COMMIT"          > /home/spack/rocm-metadata/amd_llvm_commit.txt
echo "$HIPIFY_COMMIT"            > /home/spack/rocm-metadata/hipify_commit.txt
echo "$SPIRV_TRANSLATOR_COMMIT"  > /home/spack/rocm-metadata/spirv_translator_commit.txt

echo "Metadata processed successfully!"
