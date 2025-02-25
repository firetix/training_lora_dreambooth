@echo off
setlocal

REM Define color variables
set "yellow_text=[1;33m"
set "blue_text=[1;34m"
set "reset_text=[0m"

REM Run pip freeze and capture the output
for /f "delims=" %%I in ('pip freeze') do (
    set "pip_output=%%I"
    goto :CheckModules
)

:CheckModules
REM Check if modules are found in the output
if defined pip_output (
    echo %yellow_text%=============================================================
    echo Modules installed outside the virtual environment were found.
    echo This can cause issues. Please review the installed modules.
    echo.
    echo You can uninstall all local modules with:
    echo.
    echo %blue_text%deactivate
    echo pip freeze ^> uninstall.txt
    echo pip uninstall -y -r uninstall.txt
    echo %yellow_text%=============================================================%reset_text%

    goto PromptUser
)

endlocal

set PYTHON_VER=3.10.9

REM Check if Python version meets the recommended version
python --version 2>nul | findstr /b /c:"Python %PYTHON_VER%" >nul
if errorlevel 1 (
    echo Warning: Python version %PYTHON_VER% is recommended.
)

IF NOT EXIST venv (
    python -m venv venv
) ELSE (
    echo venv folder already exists, skipping creation...
)
call .\venv\Scripts\activate.bat

REM Upgrade pip if needed
python.exe -m pip install --upgrade pip

echo Do you want to uninstall previous versions of torch and associated files before installing? Usefull if you are upgrading from torch 1.12.1 to torch 2.0.0 or if you are downgrading from torch 2.0.0 to torch 1.12.1.
echo [1] - Yes
echo [2] - No (recommanded for most)
set /p uninstall_choice="Enter your choice (1 or 2): "

if %uninstall_choice%==1 (
    pip uninstall -y xformers torch torchvision triton
)

echo Please choose the version of torch you want to install:
echo [1] - v1 (torch 1.12.1) (Recommended)
echo [2] - v2 (torch 2.0.0) (Experimental)
set /p choice="Enter your choice (1 or 2): "


:: Only does this section to cleanup the old custom dll versions that we used to use. No longer needed now with the new bitsandbytes version
pip uninstall -y bitsandbytes
IF EXIST ".\venv\Lib\site-packages\bitsandbytes" (
    rmdir .\venv\Lib\site-packages\bitsandbytes
)
:::::::::::::::::::::::::

if %choice%==1 (
    pip install torch==1.12.1+cu116 torchvision==0.13.1+cu116 --extra-index-url https://download.pytorch.org/whl/cu116
    pip install --use-pep517 --upgrade -r requirements.txt
    pip install -U -I --no-deps https://github.com/C43H66N12O12S2/stable-diffusion-webui/releases/download/f/xformers-0.0.14.dev0-cp310-cp310-win_amd64.whl
) else (
    pip install torch==2.0.1+cu118 torchvision==0.15.2+cu118 --extra-index-url https://download.pytorch.org/whl/cu118
    pip install --use-pep517 --upgrade -r requirements.txt
    rem pip install --upgrade xformers==0.0.20
    rem pip install -U -I --no-deps https://files.pythonhosted.org/packages/d6/f7/02662286419a2652c899e2b3d1913c47723fc164b4ac06a85f769c291013/xformers-0.0.17rc482-cp310-cp310-win_amd64.whl
    pip install https://huggingface.co/r4ziel/xformers_pre_built/resolve/main/triton-2.0.0-cp310-cp310-win_amd64.whl
)

python.exe .\tools\update_bitsandbytes.py

@REM copy /y .\bitsandbytes_windows\*.dll .\venv\Lib\site-packages\bitsandbytes\
@REM copy /y .\bitsandbytes_windows\cextension.py .\venv\Lib\site-packages\bitsandbytes\cextension.py
@REM copy /y .\bitsandbytes_windows\main.py .\venv\Lib\site-packages\bitsandbytes\cuda_setup\main.py

accelerate config

exit

:PromptUser
REM Ask the user if they want to quit or continue
echo.
echo Do you want to:
echo [1] - Quit
echo [2] - Continue with the setup
set /p "choice=Enter your choice (1 or 2): "
if /i "%choice%"=="1" (
    echo You chose to quit.
    echo.
    goto :Quit
) else if /i "%choice%"=="2" (
    echo You chose to continue.
    echo.
) else (
    echo Invalid choice. Please try again.
    echo.
    goto :PromptUser
)

:Quit