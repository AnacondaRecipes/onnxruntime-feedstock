@echo on

set "BUILD_DIR=%TEMP%\b"
set "DONT_VECTORIZE=OFF"
if not "%PKG_NAME:-novec=%" == "%PKG_NAME%" set "DONT_VECTORIZE=ON"
rem Unit tests only run for CPU variants; CUDA variants pass --skip_tests, so don't compile them
set "BUILD_UNIT_TESTS=ON"
set "PARALLEL_JOBS=4"
if "%ep_variant%" == "cuda" (
    set "BUILD_UNIT_TESTS=OFF"
    set "PARALLEL_JOBS=2"
)
set cmake_extra_defines="EIGEN_MPL2_ONLY=ON onnxruntime_USE_COREML=OFF onnxruntime_BUILD_SHARED_LIB=ON onnxruntime_BUILD_UNIT_TESTS=%BUILD_UNIT_TESTS% onnxruntime_DONT_VECTORIZE=%DONT_VECTORIZE% CMAKE_PREFIX_PATH=%LIBRARY_PREFIX% CMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% CMAKE_DISABLE_FIND_PACKAGE_Protobuf=ON"

if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%"

if "%ep_variant%" == "cuda" (
    set "CUDAHOSTCXX=%CXX%"
    set "cmake_extra_defines=%cmake_extra_defines% CMAKE_CUDA_COMPILER=%LIBRARY_BIN:\=/%/nvcc.exe CMAKE_CUDA_ARCHITECTURES=75;80;86;89;90a;100a;103;120a;121"
    set "CUDA_ARGS=--use_cuda --cuda_home %LIBRARY_PREFIX:\=/% --cudnn_home %LIBRARY_PREFIX% --enable_cuda_profiling  --nvcc_threads 1"
    set "RUN_TESTS=--skip_tests"
) else (
    set "CUDA_ARGS="
    set "RUN_TESTS=--test"
)

%PYTHON% %SRC_DIR%/tools/ci_build/build.py ^
    --compile_no_warning_as_error ^
    --enable_pybind ^
    --build_dir %BUILD_DIR% ^
    --cmake_extra_defines %cmake_extra_defines% ^
    --cmake_generator Ninja ^
    --build_wheel ^
    --config Release ^
    --update ^
    --build ^
    --clean ^
    --parallel %PARALLEL_JOBS% ^
    --skip_pip_install ^
    --skip_submodule_sync ^
    --no_telemetry ^
    %RUN_TESTS% ^
    %CUDA_ARGS%
if errorlevel 1 exit 1
