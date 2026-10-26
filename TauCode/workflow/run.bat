@echo off
echo ==^> [TauCode] Avvio compilazione remota GitHub Action (senza push locale)...
ezbuild --build-remote --non-interactive
if %ERRORLEVEL% neq 0 (
    echo [!] Errore durante l'avvio della compilazione remota.
    exit /b %ERRORLEVEL%
)
echo ==^> [TauCode] Esecuzione remota completata.
