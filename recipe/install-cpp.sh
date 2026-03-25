#!/bin/bash

set -exuo pipefail

BUILD_DIR="${SRC_DIR}/build"

mkdir -p "${PREFIX}/include"
mkdir -p "${PREFIX}/lib"
cp -pr ${SRC_DIR}/include/onnxruntime "${PREFIX}/include/"

if [[ -n "${OSX_ARCH:+yes}" ]]; then
    install ${BUILD_DIR}/Release/libonnxruntime.*dylib "${PREFIX}/lib"
else
    install ${BUILD_DIR}/Release/libonnxruntime.so* "${PREFIX}/lib"
    if [[ "${ep_variant:-}" == "cuda" ]]; then
        install ${BUILD_DIR}/Release/libonnxruntime_providers_shared.so* "${PREFIX}/lib"
        install ${BUILD_DIR}/Release/libonnxruntime_providers_cuda.so* "${PREFIX}/lib"
    fi
fi
