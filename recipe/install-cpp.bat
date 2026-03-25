@echo on

set "BUILD_DIR=%TEMP%\b"

mkdir "%LIBRARY_INC%\onnxruntime" 2>nul
mkdir "%LIBRARY_LIB%" 2>nul
mkdir "%LIBRARY_BIN%" 2>nul

robocopy %SRC_DIR%\include\onnxruntime "%LIBRARY_INC%\onnxruntime" /E /NFL /NDL /NJH /NJS
if %errorlevel% leq 7 set errorlevel=0

copy /Y %BUILD_DIR%\Release\onnxruntime_conda.lib "%LIBRARY_LIB%"
if errorlevel 1 exit 1
copy /Y %BUILD_DIR%\Release\onnxruntime_conda.dll "%LIBRARY_BIN%"
if errorlevel 1 exit 1

if "%ep_variant%" == "cuda" (
    copy /Y %BUILD_DIR%\Release\onnxruntime_providers_shared.lib "%LIBRARY_LIB%"
    if errorlevel 1 exit 1
    copy /Y %BUILD_DIR%\Release\onnxruntime_providers_shared.dll "%LIBRARY_BIN%"
    if errorlevel 1 exit 1
    copy /Y %BUILD_DIR%\Release\onnxruntime_providers_cuda.lib "%LIBRARY_LIB%"
    if errorlevel 1 exit 1
    copy /Y %BUILD_DIR%\Release\onnxruntime_providers_cuda.dll "%LIBRARY_BIN%"
    if errorlevel 1 exit 1
)
