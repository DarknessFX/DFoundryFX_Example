@IF NOT DEFINED _echo echo off
@TITLE DFoundryFX Plugin Setup
CLS
SETLOCAL

REM CONSTANTS
SET _ExitSub=EXIT /b

REM COLOR HELPERS
SET _bBlack=[40m
SET _fGreen=[92m
SET _fCyan=[36m
Set _fYellow=[33m
Set _fRed=[31m
Set _fBlue=[94m
SET _ResetColor=[0m

REM VARIABLES
SET _DevCmd=1 
SET _ProcessorType=64
SET _UEUVS=
SET _UEPath=

REM **********
REM MAIN
ECHO %_fGreen%%_bBlack%. DFoundryFX Plugin Setup .%_ResetColor%

ECHO.
CALL :CheckVSDevCmd
CALL :CheckMake
CALL :CheckGit
CALL :FindVS
CALL :LoadVSDevCmd

ECHO.
CALL :CloneExample
CALL :ClonePlugin
CALL :BuildImGui

ECHO.
CALL :FindUE
CALL :GenerateSolution
CALL :BuildSolution

ECHO.
ECHO %_fGreen%%_bBlack%Everything worked.%_ResetColor%
ECHO %_fGreen%%_bBlack%DFoundryFX_Example.uproject is opening now...%_ResetColor%
START DFoundryFX_Example.uproject

GOTO :END
REM /MAIN
REM **********


REM **********
REM FUNTIONS
:CheckVSDevCmd
ECHO %_fCyan%%_bBlack%  - Checking if in Visual Studio Developer Enviroment (vsdevcmd.bar or vsvarsall.bat).%_ResetColor%
IF DEFINED VCToolsInstallDir ( 
  ECHO   Detected in Visual Studio Developer Enviroment.
  EXIT /b
)
SET _DevCmd=0
ECHO %_fYellow%%_bBlack%  Fail, not in Visual Studio Developer Enviroment.%_ResetColor%
EXIT /b

:CheckMake
ECHO %_fCyan%%_bBlack%  - Checking Make.exe exists.%_ResetColor%
WHERE Make.exe >nul
IF %ERRORLEVEL% EQU 0 ( 
  ECHO   Make.exe detected.
  EXIT /b
)
SET _DevCmd=0
ECHO %_fYellow%%_bBlack%  Fail, Make.exe not found.%_ResetColor%
EXIT /b

:CheckGit
ECHO %_fCyan%%_bBlack%  - Checking Git.exe exists.%_ResetColor%
WHERE Git.exe >nul
IF %ERRORLEVEL% EQU 0 ( 
  ECHO   Git.exe detected.
  EXIT /b
)
SET _DevCmd=0
ECHO %_fRed%%_bBlack%  Fail, Git.exe not found.%_ResetColor%
ECHO.
ECHO.
ECHO We need git to be installed to run the setup,
ECHO download and install : %_fBlue%%_bBlack%https://git-scm.com/download/win%_ResetColor%
ECHO.
ECHO With Git installed, run this setup again.
ECHO.
PAUSE
EXIT

:DownloadVSWhere
IF NOT EXIST "%CD%\vswhere.exe" (
  BITSADMIN /rawreturn /transfer /download "https://github.com/microsoft/vswhere/releases/download/3.1.1/vswhere.exe" "%CD%\vswhere.exe"
  ECHO     VSWhere donwloaded.
)
EXIT /b

:FindVS
IF %_DevCmd% EQU 1 ( EXIT /b )
ECHO %_fCyan%%_bBlack%  - Trying to load Visual Studio Developer Enviroment.%_ResetColor%
WHERE VSWHERE.EXE >nul
IF %ERRORLEVEL% NEQ 0 (
  ECHO     VSWhere not found. 
  ECHO     VSWhere donwloading...
  CALL :DownloadVSWhere 
)
EXIT /b

:ExecuteVSDevCmd
FOR /F "usebackq delims=" %%i IN (`vswhere.exe -prerelease -latest -property installationPath`) DO (
  IF EXIST "%%i\Common7\Tools\vsdevcmd.bat" (
    CALL "%%i\Common7\Tools\vsdevcmd.bat"
    SET _DevCmd=1
    EXIT /b 2
  )
)
EXIT /b

:LoadVSDevCmd
IF %_DevCmd% EQU 0 (
  CALL :ExecuteVSDevCmd
)
EXIT /b

:ProcessorType
IF %PROCESSOR_ARCHITECTURE% == x86 (
  IF NOT DEFINED PROCESSOR_ARCHITEW6432 Set _ProcessorType=32
)
ECHO     Operating System is %_OS_Bitness% bit
%_ExitSub%
REM /FUNTIONS
REM **********

:CloneExample
ECHO %_fCyan%%_bBlack%  - Cloning DFoundryFX_Example git.%_ResetColor%
IF NOT EXIST "%CD%\Source" (
  MKDIR "%CD%\Temp"
  GIT clone --recursive https://github.com/DarknessFX/DFoundryFX_Example "%CD%\Temp"
  XCOPY /S /H /Y /Q "%CD%\Temp\" "%CD%\"
  RMDIR /S /Q "%CD%\Temp"
) ELSE ( 
  GIT pull
)
EXIT /b

:ClonePlugin
ECHO %_fCyan%%_bBlack%  - Cloning DFoundryFX Plugin git.%_ResetColor%
IF NOT EXIST "%CD%\Plugins" ( MKDIR "%CD%\Plugins" )
IF NOT EXIST "%CD%\Plugins\DFoundryFX" ( MKDIR "%CD%\Plugins\DFoundryFX" )
IF NOT EXIST "%CD%\Plugins\DFoundryFX\Source" (
  GIT clone --recursive https://github.com/DarknessFX/DFoundryFX "%CD%\Plugins\DFoundryFX"
) ELSE (
  CD Plugins\DFoundryFX
  GIT pull
  CD ..\..
)
EXIT /b

:BuildImGui
ECHO %_fCyan%%_bBlack%  - Compiling ImGui and Implot binaries.%_ResetColor%
CD "%CD%\Plugins\DFoundryFX\Source\Thirdparty\ImGui"
CALL Build.bat
CD ..\..\..\..\..
EXIT /b

:FindUE
ECHO %_fCyan%%_bBlack%  - Finding Unreal Engine path.%_ResetColor%
FOR /f "tokens=3" %%a IN ('REG QUERY "HKEY_CLASSES_ROOT\Unreal.ProjectFile\shell\rungenproj\command" /VE ^|FINDSTR /ri "REG_SZ"') DO SET _UEUVS=%%a
IF NOT EXIST "%_UEUVS%" (
  ECHO %_fRed%%_bBlack%  Fail, UnrealVersionSelector-Win64-Shipping.exe not found.%_ResetColor%
  ECHO.
  ECHO.
  ECHO You're going to need to generate the .uproject solution files manually
  ECHO since we cannot find your Unreal Engine installation folder.
  ECHO.
  PAUSE
  EXIT
)
ECHO   Found at:
ECHO     %_UEUVS%.
ECHO.
EXIT /b

:GenerateSolution
ECHO %_fCyan%%_bBlack%  - Generating DFoundryFX_Example VS Solution.%_ResetColor%
SET _UEPath=%_UEUVS:UnrealVersionSelector-Win64-Shipping.exe=%
IF NOT DEFINED VSAPPIDDIR SET VSAPPIDDIR=%VSINSTALLDIR%Common7\IDE\
IF NOT DEFINED VisualStudioEdition SET VisualStudioEdition=%VisualStudioVersion%
CD /D %_UEPath%\..\..\Build\BatchFiles\
CALL Build.bat -projectfiles -project="%~dp0%\DFoundryFX_Example.uproject" -game -engine -progress
IF %ERRORLEVEL% NEQ 0 (
  ECHO %_fRed%%_bBlack%  Fail to generate DFoundryFX_Example VS Solution.%_ResetColor%
  ECHO.
  ECHO.
  ECHO You're going to need to generate the .SLN solution from this .uproject manually.
  ECHO.
  PAUSE
  EXIT
)
CD /D %~dp0%
ECHO   DFoundryFX_Example.sln VS Solution successfully created.
ECHO.
EXIT /b

:BuildSolution
ECHO %_fCyan%%_bBlack%  - Building DFoundryFX_Example.sln .%_ResetColor%
CD /D %_UEPath%\..\..\Build\BatchFiles\
CALL Build.bat -Target="DFoundryFX_ExampleEditor Win64 Development" -Project="%~dp0%/DFoundryFX_Example.uproject"
CD /D %~dp0%
ECHO   VS Solution successfully built.
ECHO.
EXIT /b


:END
REM END
ECHO.
PAUSE
REM EXIT 0