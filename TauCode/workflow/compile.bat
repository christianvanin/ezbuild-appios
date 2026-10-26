@echo off
echo ==^> [TauCode] Compilazione iOS: commit, push e avvio GitHub Action...
ezbuild --push-and-build --non-interactive
if %ERRORLEVEL% neq 0 (
    echo [!] Errore durante la compilazione con EzBuild CLI.
    exit /b %ERRORLEVEL%
)
echo ==^> [TauCode] Compilazione completata con successo.
