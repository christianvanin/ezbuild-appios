#!/usr/bin/env bash
set -e
echo "==> [TauCode] Compilazione iOS: commit, push e avvio GitHub Action..."
ezbuild --push-and-build --non-interactive
echo "==> [TauCode] Compilazione completata con successo."
