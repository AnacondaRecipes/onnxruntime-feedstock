@echo on

set cmake_extra_defines="EIGEN_MPL2_ONLY=ON onnxruntime_USE_COREML=OFF onnxruntime_BUILD_SHARED_LIB=ON onnxruntime_BUILD_UNIT_TESTS=ON CMAKE_PREFIX_PATH=%LIBRARY_PREFIX% CMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% CMAKE_DISABLE_FIND_PACKAGE_Protobuf=ON"

:: Enable CUDA support
if "%ep_variant%" == "cuda" (
    set "CUDAHOSTCXX=%CXX%"
    set "cmake_extra_defines=%cmake_extra_defines% CMAKE_CUDA_COMPILER=%LIBRARY_BIN:\=/%/nvcc.exe"
    set "CUDA_ARGS=--use_cuda --cuda_home %LIBRARY_PREFIX:\=/% --cudnn_home %LIBRARY_PREFIX% --enable_cuda_profiling"
) else (
    set "CUDA_ARGS="
)

:: We set CMAKE_DISABLE_FIND_PACKAGE_Protobuf=ON as currently we do not want to use
:: protobuf from conda-forge, see https://github.com/conda-forge/onnxruntime-feedstock/issues/57#issuecomment-1518033552
%PYTHON% tools/ci_build/build.py ^
    --compile_no_warning_as_error ^
    --enable_pybind ^
    --build_dir build-ci ^
    --cmake_extra_defines %cmake_extra_defines% ^
    --cmake_generator Ninja ^
    --build_wheel ^
    --config Release ^
    --update ^
    --build ^
    --parallel ^
    --test ^
    --skip_submodule_sync ^
    %CUDA_ARGS%
if errorlevel 1 exit 1

:: In theory there should be only one wheel
for %%F in (build-ci\Release\dist\onnxruntime*.whl) do (
    %PYTHON% -m pip install %%F --no-deps --no-build-isolation -v
    if errorlevel 1 exit 1
)
