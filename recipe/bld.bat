@echo on

:: We set CMAKE_DISABLE_FIND_PACKAGE_Protobuf=ON as currently we do not want to use
:: protobuf from conda-forge, see https://github.com/conda-forge/onnxruntime-feedstock/issues/57#issuecomment-1518033552
%PYTHON% tools/ci_build/build.py ^
    --compile_no_warning_as_error ^
    --build_dir build-ci ^
    --cmake_extra_defines EIGEN_MPL2_ONLY=ON "onnxruntime_USE_COREML=OFF" "onnxruntime_BUILD_SHARED_LIB=ON" "onnxruntime_BUILD_UNIT_TESTS=OFF" CMAKE_PREFIX_PATH=%LIBRARY_PREFIX% CMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% CMAKE_DISABLE_FIND_PACKAGE_Protobuf=ON ^
    --build_wheel ^
    --config Release ^
    --update ^
    --build ^
    --test ^
    --enable_onnx_tests ^
    --enable_symbolic_shape_infer_tests ^
    --skip_submodule_sync
if errorlevel 1 exit 1

xcopy /S /Y /F build-ci\Release\Release\dist\onnxruntime-*.whl onnxruntime-%PKG_VERSION%-py3-none-any.whl*
if errorlevel 1 exit 1

%PYTHON% -m pip install onnxruntime-%PKG_VERSION%-py3-none-any.whl
if errorlevel 1 exit 1
rem Exiting...
