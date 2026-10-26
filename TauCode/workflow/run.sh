#!/usr/bin/env bash
set -e
echo "==> [TauCode] Avvio compilazione remota GitHub Action (senza push locale)...
ezbuild --build-remote --non-interactive
echo "==> [TauCode] Esecuzione remota completata."
