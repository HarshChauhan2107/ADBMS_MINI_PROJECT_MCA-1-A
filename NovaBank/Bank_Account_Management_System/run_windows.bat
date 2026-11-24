@echo off
setlocal
cd /d "%~dp0"

if not exist .venv (
  echo [1/3] Creating Python virtual environment...
  py -3 -m venv .venv
  if errorlevel 1 (echo Python 3 was not found. Install Python 3.10+ and try again.& pause & exit /b 1)
)
call .venv\Scripts\activate.bat

echo [2/3] Installing project dependencies...
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
if errorlevel 1 (echo Dependency installation failed.& pause & exit /b 1)

if not exist .env copy .env.example .env >nul

echo.
echo [3/3] Starting NovaBank dashboard...
echo For a UI-only preview, set DEMO_MODE=true in .env.
echo For live Oracle data, set DEMO_MODE=false and configure ORACLE_USER, ORACLE_PASSWORD and ORACLE_DSN.
echo Open http://127.0.0.1:5000 in your browser.
python backend\app.py
pause
