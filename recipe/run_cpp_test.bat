setlocal EnableDelayedExpansion

:: Compile example that links onnxruntime
:: The library is named onnxruntime_conda as a workaround for
:: https://github.com/conda-forge/onnxruntime-feedstock/pull/56#issuecomment-1586080419
:: %1: optional extra compiler flag, e.g. /DORT_TEST_CUDA for the CUDA inference check
%CC% /std:c++17 /EHsc %1 -I%PREFIX%\Library\include %PREFIX%\Library\lib\onnxruntime_conda.lib test.cpp 
if %ERRORLEVEL% neq 0 exit 1

:: Run test
.\test.exe
if %ERRORLEVEL% neq 0 exit 1
