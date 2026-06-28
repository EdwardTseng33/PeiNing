@echo off
chcp 65001 >nul
title 沐寧 Munea App
rem 讀本機鑰匙（engine\.env.local，不會上傳 GitHub）
for /f "usebackq tokens=1,* delims==" %%a in ("%~dp0engine\.env.local") do set "%%a=%%b"
cd /d "%~dp0engine"
echo.
echo   沐寧 App 啟動中...  開瀏覽器到  http://localhost:8200
echo   要停止就關掉這個黑視窗。若畫面一開是空白，重新整理一次即可。
echo.
start "" http://localhost:8200
set "PYEXE=C:\Users\Administrator\AppData\Local\Python\pythoncore-3.14-64\python.exe"
if exist "%PYEXE%" ("%PYEXE%" server.py) else (py server.py || python server.py)
pause
