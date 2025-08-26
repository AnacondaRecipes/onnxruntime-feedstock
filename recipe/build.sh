#!/bin/bash

set -exuo pipefail

find ${PREFIX} -name nvcc

if [[ "${PKG_NAME}" == 'onnxruntime-novec' ]]; then
    DONT_VECTORIZE="ON"
else
    DONT_VECTORIZE="OFF"
fi

if [[ "$(uname -s)" == "Linux" ]]; then
    OS_SPECIFIC_ARGS="--allow_running_as_root"
else
    OS_SPECIFIC_ARGS=""
fi

cmake_extra_defines=("EIGEN_MPL2_ONLY=ON" \
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
    if [[ "${cmake_arg}" == -DCMAKE_* ]]; then
        # Strip -D prefix
        cmake_extra_defines+=( "${cmake_arg#"-D"}" )
    fi
done

if [[ "${ep_variant:-}" == "cuda" ]]; then
    export CUDAHOSTCXX="${CXX}"                # If this isn't included, CUDA will use the system compiler to compile host
                                                # files, rather than the one in the conda environment, resulting in compiler errors
    CUDA_ARGS="--use_cuda --cudnn_home ${PREFIX} --cuda_home ${PREFIX} --enable_cuda_profiling"
    cmake_extra_defines+=('CUDAToolkit_INCLUDE_DIR="${PREFIX}/targets/x86_64-linux/include/"')
    # Skipping all tests for CUDA variants, as they're crashing after passing
    # this is related to CUDA Execution Provider cleanup, which fails, as CI images are missing CUDA drivers
    # All the tests are passing locally on CUDA-enabled docker
    RUN_TESTS="--skip_tests"
else
    CUDA_ARGS=""
    RUN_TESTS="--test"
fi

echo "${cmake_extra_defines[@]}"

${PYTHON} tools/ci_build/build.py \
    --compile_no_warning_as_error \
    --enable_lto \
    --enable_pybind \
    --build_dir build-ci \
    --cmake_extra_defines "${cmake_extra_defines[@]}" \
    --cmake_generator Ninja \
    --build_wheel \
    --config Release \
    --update \
    --build \
    --parallel 0 \
    --skip_submodule_sync \
    $RUN_TESTS \
    $OS_SPECIFIC_ARGS \
    $CUDA_ARGS

if [[ "${ep_variant:-}" == "cuda" ]]; then
    WHL_BASE_NAME="onnxruntime_gpu"
else
    WHL_BASE_NAME="onnxruntime"
fi

for whl_file in build-ci/Release/dist/${WHL_BASE_NAME}*.whl; do
    ${PYTHON} -m pip install "$whl_file" --no-deps --no-build-isolation -v
done
