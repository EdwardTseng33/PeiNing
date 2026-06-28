@echo off
chcp 65001 >nul
title 沐寧 Munea App
rem 讀本機鑰匙（engine\.env.local，不會上傳 GitHub）
for /f "usebackq tokens=1,* delims==" %%a in ("%~dp0engine\.env.local") do set "%%a=%%b"
if not defined GEMINI_API_KEY ( echo [錯誤] 讀不到鑰匙 engine\.env.local & echo 截圖給蘇菲。& pause & exit /b 1 )
cd /d "%~dp0engine"
echo.
echo   沐寧 App 啟動中... 伺服器暖機約 5 秒後，瀏覽器會自動打開 http://localhost:8200
echo   要停止：關掉這個黑視窗。畫面若一開是空白：重新整理一次。
echo.
rem 等伺服器先綁好 8200 再開瀏覽器（修「瀏覽器比伺服器早開、一片空白」）
start "" /b powershell -NoProfile -Command "Start-Sleep 5; Start-Process 'http://localhost:8200'"
set "PYEXE=C:\Users\Administrator\AppData\Local\Python\pythoncore-3.14-64\python.exe"
if exist "%PYEXE%" ( "%PYEXE%" server.py ) else ( py server.py )
echo.
echo [伺服器停止了] 上面若有紅字錯誤，截圖給蘇菲。
pause
