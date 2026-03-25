@echo on

set "BUILD_DIR=%TEMP%\b"

for %%F in (%BUILD_DIR%\Release\dist\onnxruntime*.whl) do (
    %PYTHON% -m pip install --no-deps --no-build-isolation -vvv %%F
    if errorlevel 1 exit 1
)
