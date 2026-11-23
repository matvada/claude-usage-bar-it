# Consumi Claude

Un'app per la barra dei menu del Mac che mostra a colpo d'occhio quanto hai usato del tuo piano Claude: la sessione di 5 ore, la settimana, il dettaglio per modello e i crediti extra spesi rispetto al tetto mensile.

È un fork, tradotto in italiano e ricolorato nello stile di Claude, di [Claude Usage Bar](https://github.com/Blimp-Labs/claude-usage-bar) di Blimp Labs (licenza BSD 2-Clause).

## Cosa mostra

- **Nella barra dei menu:** il logo di Claude e due mini barre, `5h` (sessione) e `7g` (settimana). Sono verde oliva sotto il 60%, terracotta fino all'85% e rosso mattone oltre.
- **Cliccando l'icona:**
  - percentuale e ora di azzeramento di sessione e settimana
  - consumo settimanale per modello
  - crediti extra spesi sul tetto mensile, in euro o in dollari
  - grafico dello storico (1h, 6h, 1g, 7g, 30g)
- **Notifiche:** puoi impostare una soglia per la sessione, una per la settimana e una per i crediti extra.

## Installazione

1. Scarica `ClaudeUsageBar.dmg` dall'ultima [Release](../../releases/latest).
2. Apri il DMG e trascina l'app in **Applicazioni**.
3. L'app non è firmata con un certificato Apple Developer, quindi la prima volta macOS la blocca. Per aprirla fai **clic destro › Apri**, oppure esegui nel Terminale:
   ```sh
   xattr -dr com.apple.quarantine /Applications/ClaudeUsageBar.app
   ```
4. Clicca l'icona nella barra dei menu, poi **Accedi con Claude**, e autorizza l'accesso nel browser.

## Requisiti

- macOS 14 (Sonoma) o successivo
- Un piano Claude a pagamento (Pro, Max, Team o Enterprise con licenza a utente)

## Come funziona

L'app accede con il tuo account Claude tramite OAuth, lo stesso accesso che usa Claude Code, e legge gli stessi dati della pagina Impostazioni › Utilizzo di claude.ai. Le credenziali restano sul Mac, in `~/.config/claude-usage-bar/`.

Queste API non sono pubbliche né documentate. Se Anthropic le modifica, l'app potrebbe smettere di funzionare finché non viene aggiornata.

## Compilare dai sorgenti

Servono Xcode 26 o successivo e macOS 14 o successivo.

```sh
make app       # crea macos/ClaudeUsageBar.app
make dmg       # crea il DMG
make install   # copia l'app in /Applications
```

## Pubblicare una nuova versione

Aggiorna `CFBundleShortVersionString` in `macos/Resources/Info.plist` e fai push su `main`: GitHub Actions compila l'app e pubblica DMG e ZIP nella Release `v<versione>`.

## Licenza

BSD 2-Clause, come il progetto originale. Vedi [LICENSE](LICENSE).
Non è un prodotto ufficiale di Anthropic.
