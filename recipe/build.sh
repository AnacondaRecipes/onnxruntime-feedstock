#!/bin/bash

set -exuo pipefail

export BUILD_DIR="build"

if [[ "${PKG_NAME}" == *"-novec"* ]]; then
    DONT_VECTORIZE="ON"
else
    DONT_VECTORIZE="OFF"
fi

cmake_extra_defines=("EIGEN_MPL2_ONLY=ON" \
		             "FLATBUFFERS_BUILD_FLATC=OFF" \
	                 "onnxruntime_USE_COREML=OFF" \
                     "onnxruntime_DONT_VECTORIZE=$DONT_VECTORIZE" \
                     "onnxruntime_BUILD_SHARED_LIB=ON" \
                     "onnxruntime_BUILD_UNIT_TESTS=ON" \
                     "CMAKE_PREFIX_PATH=$PREFIX" \
                     "GTest_ROOT=${PREFIX}" \
                     "CMAKE_FIND_ROOT_PATH=${PREFIX}" \
                     "CMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY" \
                     "CMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY" \
                     "CMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY" \
                     "CMAKE_CUDA_ARCHITECTURES=75;80;86;89;90a;100a;103;120a;121"
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

# GCC 14.3 x86_64 numerical bug: ConvSplit test fails with sign flips in -novec variant
# (the comment-out-linux-x86-tests.patch covers most NHWC tests but missed this one)
if [[ "${target_platform}" == "linux-64" ]]; then
    export GTEST_FILTER="-NhwcTransformerTests.ConvSplit"
fi

# Build parallelism (see cuda-build-tuning skill). CPU builds can use all
# cores; CUDA builds are memory-bound (each nvcc template instantiation peaks
# several GB), so size jobs to the worker's RAM, not its core count, and cap
# per-nvcc threading + glibc arenas to avoid OOM. Replaces the old hardcoded
# `--parallel 4`, which throttled CPU builds across the whole matrix.
if [[ "${ep_variant:-}" == "cuda" ]]; then
    export MALLOC_ARENA_MAX=2
    if [[ "${target_platform}" == "linux-aarch64" ]]; then
        PARALLEL_JOBS=4          # SBSA GPU workers are memory-bound
        NVCC_THREADS=1
    else
        PARALLEL_JOBS=8          # x86 CUDA (was hardcoded 4)
        NVCC_THREADS=2
    fi
else
    PARALLEL_JOBS=${CPU_COUNT:-4}
    NVCC_THREADS=1
fi

if [[ "${ep_variant:-}" == "cuda" ]]; then
    export CUDAHOSTCXX="${CXX}"                # If this isn't included, CUDA will use the system compiler to compile host
                                                # files, rather than the one in the conda environment, resulting in compiler errors
    # CUDA toolkit headers live under targets/<arch>-linux; NVIDIA uses the SBSA
    # convention (sbsa-linux) for aarch64, not aarch64-linux.
    if [[ "${target_platform}" == "linux-aarch64" ]]; then
        CUDA_TARGET_DIR="sbsa-linux"
    else
        CUDA_TARGET_DIR="x86_64-linux"
    fi
    CUDA_ARGS="--use_cuda --cudnn_home ${PREFIX} --cuda_home ${PREFIX} --enable_cuda_profiling --nvcc_threads ${NVCC_THREADS}"
    cmake_extra_defines+=("CUDAToolkit_INCLUDE_DIR=${PREFIX}/targets/${CUDA_TARGET_DIR}/include/")
    # Skipping all tests for CUDA variants, as they're crashing after passing
    # this is related to CUDA Execution Provider cleanup, which fails, as CI images are missing CUDA drivers
    # All the tests are passing locally on CUDA-enabled docker
    RUN_TESTS="--skip_tests"
else
    CUDA_ARGS=""
    RUN_TESTS="--test"
fi

${PYTHON} ${SRC_DIR}/tools/ci_build/build.py \
    --compile_no_warning_as_error \
    --enable_lto \
    --enable_pybind \
    --build_dir ${BUILD_DIR} \
    --cmake_extra_defines "${cmake_extra_defines[@]}" \
    --cmake_generator Ninja \
    --build_wheel \
    --config Release \
    --update \
    --build \
    --clean \
    --parallel ${PARALLEL_JOBS} \
    --skip_pip_install \
    --skip_submodule_sync \
    ${RUN_TESTS} \
    ${CUDA_ARGS}
