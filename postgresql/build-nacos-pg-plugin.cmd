@echo off
setlocal enabledelayedexpansion

rem =========================
rem  SET MAVEN ENVIRONMENT
rem =========================
set "JAVA_HOME=D:\Applications\Java\jdk-11.0.2"
set "MAVEN_HOME=D:\Applications\maven\apache-maven-3.9.4"
if not exist "%MAVEN_HOME%\bin\mvn.cmd" (
    echo Please set the MAVEN_HOME variable in your environment!
    exit /b 1
)
set "PATH=%MAVEN_HOME%\bin;%PATH%"

rem =========================
rem  GET CURRENT DIRECTORY
rem =========================
set BASE_DIR=%~dp0
set BASE_DIR=%BASE_DIR:~0,-1%

rem =========================
rem  SET DIRECTORIES
rem =========================
set M2_REPO=%BASE_DIR%\repository
set SOURCE_DIR=%BASE_DIR%\nacos-plugin
set OUTPUT_DIR=%BASE_DIR%\output
set PLUGIN_DATASOURCE_DIR=%SOURCE_DIR%\nacos-datasource-plugin-ext
set PLUGIN_DATASOURCE_BASE_DIR=%PLUGIN_DATASOURCE_DIR%\nacos-datasource-plugin-ext-base
set PLUGIN_DATASOURCE_POSTGRESQL_DIR=%PLUGIN_DATASOURCE_DIR%\nacos-postgresql-datasource-plugin-ext

rem =========================
rem  REPOSITORY URL
rem =========================
set REPO_URL=https://github.com/nacos-group/nacos-plugin.git

rem =========================
rem  MAVEN COMMANDS
rem =========================
set "INSTALL_POM_COMMAND=mvn -N clean install -Dmaven.repo.local=%M2_REPO%"
set "INSTALL_COMMAND=mvn clean install -Dmaven.repo.local=%M2_REPO%"

rem =========================
rem  CLONE PLUGIN SOURCE
rem =========================
if exist "%SOURCE_DIR%" rmdir /s /q "%SOURCE_DIR%"
git clone "%REPO_URL%" "%SOURCE_DIR%"
if not exist "%SOURCE_DIR%" (
    echo Clone plugin source failed!
    exit /b 1
)

rem =========================
rem  BUILD MODULES
rem =========================
rem Call BuildModule "Directory" "Command"
call :BuildModule "%SOURCE_DIR%" "%INSTALL_POM_COMMAND%"
call :BuildModule "%PLUGIN_DATASOURCE_DIR%" "%INSTALL_POM_COMMAND%"
call :BuildModule "%PLUGIN_DATASOURCE_BASE_DIR%" "%INSTALL_POM_COMMAND%"
call :BuildModule "%PLUGIN_DATASOURCE_POSTGRESQL_DIR%" "%INSTALL_COMMAND%"

rem =========================
rem  COPY ARTIFACTS
rem =========================
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
copy /y "%PLUGIN_DATASOURCE_POSTGRESQL_DIR%\target\nacos-postgresql-datasource-plugin-ext-*.jar" "%OUTPUT_DIR%"
copy /y "%PLUGIN_DATASOURCE_POSTGRESQL_DIR%\src\main\resources\schema\nacos-pg.sql" "%OUTPUT_DIR%"

rem =========================
rem  BUILD COMPLETED
rem =========================
echo Build completed successfully!
echo Output directory: %OUTPUT_DIR%
pause
exit /b 0

rem =========================
rem  FUNCTION: BuildModule
rem  Parameters: %1 = module directory, %2 = command to run
rem =========================
:BuildModule
echo ====================================
echo Building module: %~1
cd /d "%~1"
echo Running: %~2
call %~2
if errorlevel 1 (
    echo [ERROR] Build failed in %~1
    exit /b 1
)
echo Module %~1 built successfully!
goto :eof
