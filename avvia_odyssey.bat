@echo off
setlocal
rem ============================================================
rem  ODYSSEY - build + avvio in openMSX
rem
rem  uso:  avvia_odyssey          rigenera i dati (mare, nave) se i
rem                               generatori sono cambiati, assembla,
rem                               avvia (Sony HB-55P, 50Hz)
rem        avvia_odyssey fast     salta la rigenerazione
rem        avvia_odyssey 60       avvia su C-BIOS_MSX1 (60Hz)
rem        (combinabili: avvia_odyssey fast 60)
rem ============================================================
cd /d "%~dp0"
set "OPENMSX=E:\Dropbox\FAUSTO\SVILUPPI\MSX\EMULATORI\openMSX"
rem audio a bassa latenza: forza il backend WASAPI di Windows
set "SDL_AUDIODRIVER=wasapi"
set "MACHINE=Sony_HB-55P"
if not exist build mkdir build

set "REGEN=1"
for %%A in (%*) do (
    if /i "%%A"=="fast" set "REGEN=0"
    if /i "%%A"=="60" set "MACHINE=C-BIOS_MSX1"
)

rem ---- trova python (serve solo per rigenerare i dati) ----
set "PY="
python --version >nul 2>&1 && set "PY=python"
if not defined PY (
    py -3 --version >nul 2>&1 && set "PY=py -3"
)

rem ---- rigenera i dati se i generatori sono piu' nuovi ----
if "%REGEN%"=="0" goto :gendone
if not exist src\waves_data.asm goto :gen
if not exist src\ship_data.asm goto :gen
if not exist src\sky_data.asm goto :gen
if not exist src\map0_pat.bin goto :gen
if not exist src\title_pat.bin goto :gen
if not exist src\music_data.asm goto :gen
if not exist src\fade_data.asm goto :gen
if not exist src\cave_data.asm goto :gen
powershell -NoProfile -Command "$w=(Get-Item 'src\waves_data.asm').LastWriteTime; $s=(Get-Item 'src\ship_data.asm').LastWriteTime; if((Get-Item 'tools\gen_waves.py').LastWriteTime -gt $w -or (Get-Item 'tools\gen_ship.py').LastWriteTime -gt $s -or (Get-Item 'tools\gen_sky.py').LastWriteTime -gt (Get-Item 'src\sky_data.asm').LastWriteTime){ exit 1 }; exit 0" >nul 2>&1
if not errorlevel 1 goto :gendone
:gen
if not defined PY (
    echo [ERRORE] Python 3 non trovato: serve per generare i dati.
    echo Installa Python 3, oppure lancia   avvia_odyssey fast
    pause
    exit /b 1
)
echo Genero i dati (mare, nave, cielo, mappe, titolo, musica)...
%PY% tools\gen_waves.py || goto :err
%PY% tools\gen_ship.py || goto :err
%PY% tools\gen_sky.py || goto :err
%PY% tools\gen_map.py || goto :err
%PY% tools\gen_title.py || goto :err
%PY% tools\gen_music.py || goto :err
%PY% tools\gen_fade.py || goto :err
%PY% tools\gen_cave.py || goto :err
:gendone

rem ---- trova sjasmplus ----
set "SJ="
where sjasmplus >nul 2>&1 && set "SJ=sjasmplus"
if not defined SJ if exist "E:\Dropbox\FAUSTO\SVILUPPI\MSX\sjasmplus-1.20.3.win\sjasmplus.exe" set "SJ=E:\Dropbox\FAUSTO\SVILUPPI\MSX\sjasmplus-1.20.3.win\sjasmplus.exe"
if not defined SJ if exist "E:\Dropbox\FAUSTO\SVILUPPI\MSX\sjasm\sjasmplus.exe" set "SJ=E:\Dropbox\FAUSTO\SVILUPPI\MSX\sjasm\sjasmplus.exe"
if not defined SJ (
    echo [ERRORE] sjasmplus non trovato ne' nel PATH ne' nelle cartelle note.
    pause
    exit /b 1
)

echo Assemblo (sjasmplus)...
"%SJ%" --msg=err --sym=build\odyssey.sym src\main.asm || goto :err
if not exist build\odyssey.rom goto :err

rem ---- avvio ----
taskkill /IM openmsx.exe /F >nul 2>&1
timeout /t 1 /nobreak >nul
copy /Y build\odyssey.rom "%OPENMSX%\odyssey.rom" >nul
if errorlevel 1 (
    echo [ERRORE] Copia della ROM fallita: openMSX tiene bloccato il file?
    pause
    exit /b 1
)
start "" "%OPENMSX%\openmsx.exe" -machine %MACHINE% -carta "%OPENMSX%\odyssey.rom" -romtype ascii8
exit /b 0

:err
echo.
echo [ERRORE] Build fallita: vedi i messaggi qui sopra.
pause
exit /b 1
