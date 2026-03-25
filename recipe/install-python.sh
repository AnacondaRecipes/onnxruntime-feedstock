#!/bin/bash

set -exuo pipefail

BUILD_DIR="${SRC_DIR}/build"

for whl_file in ${BUILD_DIR}/Release/dist/onnxruntime*.whl; do
    ${PYTHON} -m pip install --no-deps --no-build-isolation -vvv $whl_file
done

# Fix CUDA variant dist-info to match conda package name
if [[ "${ep_variant:-}" == "cuda" ]]; then
    for d in "${SP_DIR}"/onnxruntime_gpu-*.dist-info; do
        [ -d "$d" ] || continue
        new_d="${d/onnxruntime_gpu/onnxruntime}"
        mv "$d" "$new_d"
        sed -i 's/^Name: onnxruntime-gpu$/Name: onnxruntime/' "$new_d/METADATA"
    done
fi
