@echo off
REM =====================================================================
REM  Campus Notify - persiapan demo
REM  Menyalakan MySQL, Laravel API, dan adb reverse dalam satu klik.
REM  Setelah skrip ini selesai, jalankan aplikasi dari Android Studio
REM  atau lewat: flutter run -d <serial>
REM =====================================================================
setlocal

set MYSQLD=C:\laragon\bin\mysql\mysql-8.0.30-winx64\bin\mysqld.exe
set MYINI=C:\laragon\bin\mysql\mysql-8.0.30-winx64\my.ini
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
set API_DIR=%~dp0..\..\..\06-week-6\api-mahasiswa

echo [1/3] MySQL...
tasklist /FI "IMAGENAME eq mysqld.exe" 2>nul | find /I "mysqld.exe" >nul
if errorlevel 1 (
    start "" /B "%MYSQLD%" --defaults-file="%MYINI%"
    timeout /t 5 /nobreak >nul
    echo       dinyalakan.
) else (
    echo       sudah berjalan.
)

echo [2/3] Laravel API di port 8000...
start "Campus Notify API" cmd /k "cd /d "%API_DIR%" && php artisan serve --host=127.0.0.1 --port=8000"
timeout /t 3 /nobreak >nul

echo [3/3] adb reverse tcp:8000...
"%ADB%" reverse tcp:8000 tcp:8000

echo.
echo Selesai. Buka tab "Campus Notify API" untuk melihat log server.
echo Jalankan aplikasi: flutter run -d e89c181d
echo.
pause
