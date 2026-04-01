@echo on

set "BUILD_DIR=%TEMP%\b"

for %%F in (%BUILD_DIR%\Release\dist\onnxruntime*.whl) do (
    %PYTHON% -m pip install --no-deps --no-build-isolation -vvv %%F
    if errorlevel 1 exit 1
)

:: Fix CUDA variant dist-info to match conda package name
if "%ep_variant%" == "cuda" (
    %PYTHON% -c "import glob, os, pathlib; sp = pathlib.Path(r'%SP_DIR%'); [((new := d.with_name(d.name.replace('onnxruntime_gpu', 'onnxruntime'))), d.rename(new), (new / 'METADATA').write_text((new / 'METADATA').read_text().replace('Name: onnxruntime-gpu', 'Name: onnxruntime'))) for d in sp.glob('onnxruntime_gpu-*.dist-info')]"
    if errorlevel 1 exit 1
)
