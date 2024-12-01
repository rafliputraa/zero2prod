@echo off
setlocal enabledelayedexpansion

:: Set default environment variables
set "DB_USER=%POSTGRES_USER%"
if not defined DB_USER set "DB_USER=postgres"

set "DB_PASSWORD=%POSTGRES_PASSWORD%"
if not defined DB_PASSWORD set "DB_PASSWORD=sariawan"

set "DB_NAME=%POSTGRES_DB%"
if not defined DB_NAME set "DB_NAME=newsletter"

set "DB_PORT=%POSTGRES_PORT%"
if not defined DB_PORT set "DB_PORT=5432"

:: Launch postgres using Docker
docker run ^
-e POSTGRES_USER=%DB_USER% ^
-e POSTGRES_PASSWORD=%DB_PASSWORD% ^
-e POSTGRES_DB=%DB_NAME% ^
-p %DB_PORT%:5432 ^
-d postgres ^
postgres -N 1000

:: Check PostgreSQL availability using ping
echo Waiting for PostgreSQL to be ready...
:wait_for_postgres
ping -n 1 localhost >nul 2>&1
if %errorlevel% neq 0 (
    echo Postgres is still unavailable - sleeping
    timeout /t 1 >nul
    goto wait_for_postgres
)

:: Assume Postgres is ready after ping is successful
echo Postgres is up and running on port %DB_PORT%!

:: Set the DATABASE_URL environment variable
set "DATABASE_URL=postgres://%DB_USER%:%DB_PASSWORD%@localhost:%DB_PORT%/%DB_NAME%"

:: Run the sqlx database creation step if sqlx is available
where sqlx >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: sqlx is not installed.
    echo Use:
    echo cargo install --version=0.5.7 sqlx-cli --no-default-features --features postgres
    echo to install it.
    exit /b 1
)
sqlx database create
