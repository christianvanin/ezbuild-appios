# TauCode Workflow - Istruzioni per Agenti AI

Questa directory (`TauCode/`) contiene gli script utilizzati dall'IDE per compilare e avviare questo progetto.
L'IDE esegue gli script che si trovano in `workflow/` basandosi sui file `compile.json` e `run.json`.

## ⚠️ DIRETTIVA CRITICA PER GLI AGENTI AI ⚠️
Tu, come assistente o agente AI che lavora su questo codice, **HAI LA RESPONSABILITÀ** di mantenere questi script aggiornati.

- Se aggiungi un nuovo step di build (es. Tailwind, Prisma, compilazione di asset).
- Se cambi il package manager (es. da npm a pnpm).
- Se cambi il file entrypoint (es. rinomini `main.py` in `app.py`).
- Se cambi framework.

**DEVI automaticamente modificare i file:**
- `workflow/compile.sh` / `workflow/compile.bat`
- `workflow/run.sh` / `workflow/run.bat`

...per riflettere i nuovi comandi, **senza aspettare che l'utente te lo chieda esplicitamente**. Questi script devono SEMPRE funzionare out-of-the-box in base alla struttura del progetto attuale.
