@echo on

rem Copy wil
pushd wil\include
xcopy /E /I wil %LIBRARY_PREFIX%\include\wil
popd

rem Copy all dependencies that are to be built
rd /s /q cmake\external\onnx
xcopy /E /I /q onnx cmake\external\onnx
if errorlevel 1 exit 1

rd /s /q cmake\external\eigen
xcopy /E /I /q eigen cmake\external\eigen
if errorlevel 1 exit 1

rd /s /q cmake\external\json
xcopy /E /I /q json cmake\external\json
if errorlevel 1 exit 1

rd /s /q cmake\external\pytorch_cpuinfo
xcopy /E /I /q pytorch_cpuinfo cmake\external\pytorch_cpuinfo
if errorlevel 1 exit 1

pushd cmake\external\SafeInt\safeint
xcopy /E /I /q %LIBRARY_PREFIX%\include\SafeInt.hpp .
if errorlevel 1 exit 1
popd

rem Create extra cmake defines and associated variables
if %PKG_NAME% == "onnxruntime-novec" ( set DONT_VECTORIZE="ON" ) else set DONT_VECTORIZE="OFF"
set CMAKE_EXTRA_DEFINES= "Protobuf_SRC_ROOT_FOLDER=%LIBRARY_PREFIX%\lib\pkgconfig" "onnxruntime_PREFER_SYSTEM_LIB=ON" "onnxruntime_USE_COREML=OFF" "onnxruntime_DONT_VECTORIZE=%DONT_VECTORIZE%" "onnxruntime_BUILD_SHARED_LIB=ON" "onnxruntime_BUILD_UNIT_TESTS=OFF" "CMAKE_PREFIX_PATH=%LIBRARY_PREFIX%" "CMAKE_CXX_FLAGS=/wd4100 /wd4244 /wd4127" "CMAKE_VERBOSE_MAKEFILE=ON" 

%PYTHON% tools\ci_build\build.py --build_dir build-ci --config Release --update --build --skip_submodule_sync --build_wheel --parallel --enable_lto --use_full_protobuf --cmake_extra_defines %CMAKE_EXTRA_DEFINES%
if errorlevel 1 exit 1

xcopy /S /Y /F build-ci\Release\Release\dist\onnxruntime-*.whl onnxruntime-%PKG_VERSION%-py3-none-any.whl*
if errorlevel 1 exit 1

%PYTHON% -m pip install onnxruntime-%PKG_VERSION%-py3-none-any.whl
if errorlevel 1 exit 1
rem Exiting...