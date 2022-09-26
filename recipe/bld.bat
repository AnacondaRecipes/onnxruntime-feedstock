@echo on

pushd wil\include
move wil %LIBRARY_PREFIX%\include\wil
popd

rd /s /q cmake\external\onnx
if errorlevel 1 exit 1

dir

move onnx cmake\external\onnx
if errorlevel 1 exit 1
rd /s /q cmake\external\eigen
if errorlevel 1 exit 1
move eigen cmake\external\eigen
if errorlevel 1 exit 1
rd /s /q cmake\external\googletest
if errorlevel 1 exit 1
move googletest cmake\external\googletest
if errorlevel 1 exit 1

pushd cmake\external\SafeInt\safeint
if errorlevel 1 exit 1
copy %LIBRARY_PREFIX%\include\SafeInt.hpp .
if errorlevel 1 exit 1
popd

pushd cmake\external\json
if errorlevel 1 exit 1
rem md single_include
rem if errorlevel 1 exit 1
rem md single_include\nlohmann
rem if errorlevel 1 exit 1
copy %LIBRARY_PREFIX%\include\nlohmann\json.hpp .
if errorlevel 1 exit 1
popd

rem Needs eigen 3.4
rem rm -rf cmake/external/eigen
rem pushd cmake/external
rem ln -s $PREFIX/include/eigen3 eigen
rem popd

%PYTHON% tools\ci_build\build.py --build_dir build-ci --config Release  --update --build --skip_submodule_sync --build_wheel --parallel --enable_lto --use_full_protobuf

dir build-ci /s

xcopy build-ci\Release\dist\onnxruntime-*.whl onnxruntime-%PKG_VERSION%-py3-none-any.whl

%PYTHON%  -m pip install onnxruntime-%PKG_VERSION%-py3-none-any.whl

