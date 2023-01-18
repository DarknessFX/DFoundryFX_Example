@IF NOT DEFINED _echo echo off
@TITLE DFoundryFX Precompiled Shaders Utility
CLS
SETLOCAL

REM CONSTANTS
SET _RETURN=EXIT /b
SET _PAUSE=PING -n 4 127.0.0.1^>nul
SET _PROJECTNAME=
FOR %%I IN (.) DO SET _PROJECTNAME=%%~nI%%~xI

REM COLOR HELPERS
SET _bBlack=[40m
SET _fGreen=[92m
SET _fCyan=[36m
Set _fYellow=[33m
Set _fRed=[31m
Set _fBlue=[94m
SET _ResetColor=[0m

REM DATETIME LOG STAMP
SET _datetime=%date:/=%_%time::=%
SET _datetime=%_datetime:~0,-3%
SET _LOGSTAMP=%_datetime%

REM VARIABLES
SET _UEUVS=
SET _UEPath=

REM **********
REM MAIN
ECHO %_fGreen%%_bBlack%. DFoundryFX Utility for Precompiled Shaders.%_ResetColor%
ECHO  Utility tool to generate and test Precompiled Shaders PSO from UE5.
ECHO.
ECHO You can read more about PSO cache at :
ECHO https://docs.unrealengine.com/5.1/en-US/optimizing-rendering-with-pso-caches-in-unreal-engine/
ECHO.
ECHO  This process can take a long time! 
ECHO.
ECHO  We are going to create a Development build and run it with -logPSO to
ECHO  generate on demand shaders list, then copy PSO cache from Saved/
ECHO  CollectedPSOs, convert .upipelinecache and .spk (Stable Shader Key) 
ECHO  to .spc with ShaderPipelineCacheTools, then package a Development 
ECHO  build again with PSO cache.
ECHO.
%_PAUSE%
ECHO.
ECHO  This utility is built for DX12 Deferred Rendering projects, you can 
ECHO  adapt for Vulkan, but it's pointless to run with DX11 or Forward 
ECHO  rendering projects.
ECHO.
%_PAUSE%
ECHO.
ECHO  %_fYellow%%_bBlack%If you're running this utility with your own project, before start 
ECHO  make sure you edited%_ResetColor%:
ECHO    \Config\DefaultEngine.ini
ECHO      [/Script/Engine.RendererSettings]
ECHO      r.ShaderPipelineCache.Enabled=1
ECHO      r.ShaderPipelineCache.SaveAfterPSOsLogged=1
ECHO      [DevOptions.Shaders]
ECHO      NeedsShaderStableKeys=true
ECHO    \Config\DefaultGame.ini
ECHO      [/Script/UnrealEd.ProjectPackagingSettings]
ECHO      bShareMaterialShaderCode=True
ECHO      bSharedMaterialNativeLibraries=True
ECHO.
ECHO  DFoundryFX_Example project alredy have this configs ready.
ECHO.
CALL
CHOICE /M "Start the utility now?"
IF %ERRORLEVEL% NEQ 1 (
  ECHO Exiting...
  GOTO :END
)

CALL :FindUEVS
CALL :FindUE
CALL :BuildDevelopmentLogPSO
CALL :StartDevelopmentLogPSO
CALL :PSOExpansion
CALL :BuildDevelopmentPSO
CALL :StartDevelopmentWithPSO

ECHO.
ECHO %_fGreen%%_bBlack%Everything worked.%_ResetColor%

GOTO :END
REM /MAIN
REM **********


REM **********
REM FUNTIONS
:FindUEVS
ECHO %_fCyan%%_bBlack%  - Finding Unreal Engine Version Selector path.%_ResetColor%
FOR /f "tokens=3" %%a IN ('REG QUERY "HKEY_CLASSES_ROOT\Unreal.ProjectFile\shell\rungenproj\command" /VE ^|FINDSTR /ri "REG_SZ"') DO SET _UEUVS=%%a
IF NOT EXIST "%_UEUVS%" (
  ECHO %_fRed%%_bBlack%  Fail, UnrealVersionSelector-Win64-Shipping.exe not found.%_ResetColor%
  ECHO.
  PAUSE
  EXIT
)
ECHO   Found at:
ECHO     %_UEUVS%.
ECHO.
%_RETURN%


:FindUE
ECHO %_fCyan%%_bBlack%  - Finding Unreal Engine folder path.%_ResetColor%
SET _UEPath=%_UEUVS:Binaries\Win64\UnrealVersionSelector-Win64-Shipping.exe:"=%
IF NOT EXIST %_UEPath%\BINARIES (
  FOR /f "tokens=3" %%a IN ('REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\EpicGames\Unreal Engine\5.1" /f InstalledDirectory ^|FINDSTR /ri "REG_SZ"') DO SET _UEPath=%%a\Engine
)
IF NOT EXIST %_UEPath%\BINARIES (
  FOR /f "tokens=3" %%a IN ('REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\EpicGames\Unreal Engine\5.0" /f InstalledDirectory ^|FINDSTR /ri "REG_SZ"') DO SET _UEPath=%%a\Engine
)
IF NOT EXIST %_UEPath%\BINARIES (
  ECHO %_fRed%%_bBlack%  Fail, Unreal Engine folder not found.%_ResetColor%
  ECHO.
  EXIT
)
ECHO   Found at:
ECHO     %_UEPath%.
ECHO.
%_RETURN%


:BuildDevelopmentLogPSO
ECHO %_fCyan%%_bBlack%  - Building %_PROJECTNAME% Development Build .%_ResetColor%
CALL
IF EXIST "%CD%\Build\Development\WindowsLogPSO" (
  ECHO   Found %_PROJECTNAME% Development Build at:
  ECHO     %CD%\Build\Development\WindowsLogPSO.
  ECHO.
  CHOICE /M " Development Build already exist, do you want rebuild?"
)
IF %ERRORLEVEL% NEQ 1 ( %_RETURN% )
ECHO.
IF EXIST "%CD%\Build\Development\WindowsLogPSO" ( RMDIR /S /Q "%CD%\Build\Development\WindowsLogPSO" )
IF EXIST "%CD%\Build\Development\LogPSO" ( RMDIR /S /Q "%CD%\Build\Development\LogPSO" )
START "Packaging %_PROJECTNAME% - Development Build" /B /WAIT /D "%CD%" CMD /C CALL "%_UEPath%\Build\BatchFiles\RunUAT.bat" -ScriptsForProject="%CD%\%_PROJECTNAME%.uproject" Turnkey -command=VerifySdk -platform=Win64 -UpdateIfNeeded -project="%CD%\%_PROJECTNAME%.uproject" BuildCookRun -nop4 -utf8output -nocompileeditor -skipbuildeditor -cook  -project="%CD%\%_PROJECTNAME%.uproject" -target=%_PROJECTNAME% -unrealexe="%_UEPath%\Binaries\Win64\UnrealEditor-Cmd.exe" -platform=Win64 -stage -archive -package -build -pak -iostore -compressed -prereqs -archivedirectory="%CD%\Build\Development\LogPSO" -clientconfig=Development -nocompile -nocompileuat
MOVE /Y "%CD%\Build\Development\LogPSO\Windows" "%CD%\Build\Development\WindowsLogPSO"
IF EXIST "%CD%\Build\Development\LogPSO" ( RMDIR /S /Q "%CD%\Build\Development\LogPSO" )
ECHO   %_PROJECTNAME% Development Package successfully built.
ECHO.
%_PAUSE%
%_RETURN%


:StartDevelopmentLogPSO
ECHO.
ECHO %_fCyan%%_bBlack%  - Loading %_PROJECTNAME% Development Build .%_ResetColor%
ECHO.
ECHO  Play the game for some seconds just to give time to shaders on demand be 
ECHO  logged. Check DFoundryFX plugin Shader Tab to verify the shaders on demand 
ECHO  list (around 215 shaders for the Example project).
ECHO.
ECHO  Exit the game with ALT+F4 .
ECHO.
ECHO Starting game in 5 secons.
TIMEOUT /T 5
START "Playing %_PROJECTNAME% Development Build" /B /WAIT /D "%CD%\Build\Development\WindowsLogPSO" "%CD%\Build\Development\WindowsLogPSO\%_PROJECTNAME%.exe" -logPSO -ResX=1280 -ResY=720 -WINDOWED -dx12
ECHO   -logPSO gameplay done.
ECHO.
%_PAUSE%
%_RETURN%


:PSOExpansion
ECHO %_fCyan%%_bBlack%  - Collecting .upipelinecache and .shk .%_ResetColor%
ECHO.
IF NOT EXIST "%CD%\Saved\PSO" ( MKDIR "%CD%\Saved\PSO" )
START "Copying .upipelinecache" /B /WAIT /D "%CD%" CMD /C XCOPY /S /H /Y /Q "%CD%\Build\Development\WindowsLogPSO\%_PROJECTNAME%\Saved\CollectedPSOs\*.upipelinecache" "%CD%\Saved\PSO\"
START "Copying .shk" /B /WAIT /D "%CD%" CMD /C XCOPY /S /H /Y /Q "%CD%\Saved\Cooked\Windows\%_PROJECTNAME%\Metadata\PipelineCaches\*SM6.shk" "%CD%\Saved\PSO\"
ECHO %_fCyan%%_bBlack%  - Expansion .spc .%_ResetColor%
ECHO.
START "Expansion .spc" /B /WAIT /D "%_UEPath%" CMD /C CALL "%_UEPath%\Binaries\Win64\UnrealEditor-Cmd.exe" "%CD%\%_PROJECTNAME%.uproject" -run=ShaderPipelineCacheTools expand "%CD%\Saved\PSO\*.upipelinecache" "%CD%\Saved\PSO\*.shk" "%CD%\Saved\PSO\%_PROJECTNAME%_PCD3D_SM6.spc"
IF NOT EXIST "%CD%\Build\Windows\PipelineCaches" ( MKDIR "%CD%\Build\Windows\PipelineCaches" )
START "Copying .spc" /B /WAIT /D "%CD%" CMD /C XCOPY /S /H /Y /Q "%CD%\Saved\PSO\*.spc" "%CD%\Build\Windows\PipelineCaches"
ECHO.
ECHO   Expansion .spc successfully built.
ECHO.
%_PAUSE%
%_RETURN%


:BuildDevelopmentPSO
ECHO %_fCyan%%_bBlack%  - Building %_PROJECTNAME% Development With PSO Build .%_ResetColor%
ECHO.
IF EXIST "%CD%\Build\Development\WindowsWithPSO" ( RMDIR /S /Q "%CD%\Build\Development\WindowsWithPSO" )
IF EXIST "%CD%\Build\Development\WithPSO" ( RMDIR /S /Q "%CD%\Build\Development\WithPSO" )
START "Packaging %_PROJECTNAME% - Development Build" /B /WAIT /D "%CD%" CMD /C CALL "%_UEPath%\Build\BatchFiles\RunUAT.bat" -ScriptsForProject="%CD%\%_PROJECTNAME%.uproject" Turnkey -command=VerifySdk -platform=Win64 -UpdateIfNeeded -project="%CD%\%_PROJECTNAME%.uproject" BuildCookRun -nop4 -utf8output -nocompileeditor -skipbuildeditor -cook  -project="%CD%\%_PROJECTNAME%.uproject" -target=%_PROJECTNAME% -unrealexe="%_UEPath%\Binaries\Win64\UnrealEditor-Cmd.exe" -platform=Win64 -stage -archive -package -build -pak -iostore -compressed -prereqs -archivedirectory="%CD%\Build\Development\WithPSO" -clientconfig=Development -nocompile -nocompileuat
MOVE /Y "%CD%\Build\Development\WithPSO\Windows" "%CD%\Build\Development\WindowsWithPSO"
IF EXIST "%CD%\Build\Development\WithPSO" ( RMDIR /S /Q "%CD%\Build\Development\WithPSO" )
ECHO   %_PROJECTNAME% Development Package With PSO successfully built.
ECHO.
%_PAUSE%
%_RETURN%


:StartDevelopmentWithPSO
ECHO.
ECHO %_fCyan%%_bBlack%  - Loading %_PROJECTNAME% Development With PSO Build .%_ResetColor%
ECHO.
ECHO  Note that GameWithPSO is going to take longer to start, around 1 minute.
ECHO.
ECHO  Read the docs about Controlling PSO Compilation for better control when 
ECHO  PSO compile in your project.
ECHO.
ECHO  Play the game with PSO check DFoundryFX Shader Tab to verify the shaders 
ECHO  on demand list (around 8 GPU shaders in the DFoundryFX_Example project).
ECHO.
ECHO  Exit the game with ALT+F4 .
ECHO.
ECHO Starting game in 5 secons.
TIMEOUT /T 5
START "Playing %_PROJECTNAME% Development With PSO Build" /B /WAIT /D "%CD%\Build\Development\WindowsWithPSO" "%CD%\Build\Development\WindowsWithPSO\%_PROJECTNAME%Game.exe" -logPSO -ResX=1280 -ResY=720 -WINDOWED -dx12
ECHO   -WithPSO gameplay done.
ECHO.
%_RETURN%

REM /FUNTIONS
REM **********

:END
REM END
ECHO.
PAUSE
EXIT 0