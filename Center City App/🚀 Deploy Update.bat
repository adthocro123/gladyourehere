@echo off
title CCG — Deploy Update
cd /d "%~dp0"
echo.
echo  ╔══════════════════════════════════════╗
echo  ║   CENTER CITY GYM — Deploy Update   ║
echo  ╚══════════════════════════════════════╝
echo.
echo  Deploying to center-city-app-bay.vercel.app...
echo.
vercel --prod
echo.
echo  ✓ Done! Your update is live.
echo.
pause
