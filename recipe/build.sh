#!/bin/bash

set -exuo pipefail

if [[ "${PKG_NAME}" == 'onnxruntime-novec' ]]; then
    DONT_VECTORIZE="ON"
else
    DONT_VECTORIZE="OFF"
fi

if [[ "${target_platform:-other}" == 'osx-arm64' ]]; then
    OSX_ARCH="arm64"
else
    OSX_ARCH="x86_64"
fi

cmake_extra_defines=( "EIGEN_MPL2_ONLY=ON" \
		      "FLATBUFFERS_BUILD_FLATC=OFF" \
	              "onnxruntime_USE_COREML=OFF" \
                      "onnxruntime_DONT_VECTORIZE=$DONT_VECTORIZE" \
                      "onnxruntime_BUILD_SHARED_LIB=ON" \
                      "onnxruntime_BUILD_UNIT_TESTS=ON" \
                      "CMAKE_PREFIX_PATH=$PREFIX" \
                      "CMAKE_CUDA_ARCHITECTURES=all-major"
		    )

# Copy the defines from the "activate" script (e.g. activate-gcc_linux-aarch64.sh)
# into --cmake_extra_defines.
read -a CMAKE_ARGS_ARRAY <<< "${CMAKE_ARGS}"
for cmake_arg in "${CMAKE_ARGS_ARRAY[@]}"
do
    if [[ "${cmake_arg}" == -DCMAKE_SYSTEM_* ]]; then
        # Strip -D prefix
        cmake_extra_defines+=( "${cmake_arg#"-D"}" )
    fi
done

if [[ "${ep_variant:-}" == "cuda" ]]; then
    export CUDAHOSTCXX="${CXX}"                # If this isn't included, CUDA will use the system compiler to compile host
                                                # files, rather than the one in the conda environment, resulting in compiler errors
    CUDA_ARGS="--use_cuda --cudnn_home ${PREFIX} --cuda_home ${PREFIX} --enable_cuda_profiling"
else
    CUDA_ARGS=""
fi

${PYTHON} tools/ci_build/build.py \
    --allow_running_as_root \
    --compile_no_warning_as_error \
    --enable_lto \
    --build_dir build-ci \
    --cmake_extra_defines "${cmake_extra_defines[@]}" \
    --cmake_generator Ninja \
    --build_wheel \
    --config Release \
    --update \
    --build \
    --skip_submodule_sync \
    --osx_arch $OSX_ARCH \
    --test \
    $CUDA_ARGS

if [[ "${ep_variant:-}" == "cuda" ]]; then
    WHL_BASE_NAME="onnxruntime_gpu"
else
    WHL_BASE_NAME="onnxruntime"
fi

cp build-ci/Release/dist/${WHL_BASE_NAME}-*.whl ${WHL_BASE_NAME}-${PKG_VERSION}-py3-none-any.whl
${PYTHON} -m pip install ${WHL_BASE_NAME}-${PKG_VERSION}-py3-none-any.whl
