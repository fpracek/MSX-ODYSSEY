# NESSUNO — un'Odissea per MSX1
## Design document v0.1 — progetto per MSXdev'26

Titolo di lavoro: **NESSUNO** (il nome che Ulisse dà a Polifemo — corto, memorabile,
funziona in tutte le lingue). Alternative: ODYSSEY, NOSTOS.

- Target: MSX1 puro, 16KB RAM, TMS9918, PSG. ROM ASCII8, dimensione libera (regole MSXdev'26).
- Finestra compo: metà settembre 2026 → metà marzo 2027.
- Genere: action-platform episodico + interludi navali. Base King's Valley/Sam.Pr,
  una meccanica nuova per episodio.

---

## 1. Realtà tecnica del TMS9918 (i vincoli veri)

Niente V9938/V9958: nessuno scroll hardware, nessun comando VDP, nessuna palette,
16KB VRAM totali. Tutto il "wow" va costruito con CPU + ROM precalcolata.

### 1.1 Mappa VRAM in SCREEN 2 (16KB)

| Area                | Indirizzo     | Dim.   |
|---------------------|---------------|--------|
| Pattern table       | 0000-17FF     | 6144   |
| Name table A        | 1800-1AFF     | 768    |
| Sprite attributes   | 1B00-1B7F     | 128    |
| **Name table B**    | 1C00-1EFF     | 768    |
| (libero)            | 1F00-1FFF     | 256    |
| Color table         | 2000-37FF     | 6144   |
| Sprite patterns     | 3800-3FFF     | 2048   |

**Buffering: SOLO name-table flip.** Due name table ci stanno (bit di R#2);
pattern e colori sono a copia unica. Il flip del name serve per cambi di schermata
puliti e per riorganizzare metatile senza tearing. Ogni animazione di pattern/colori
va invece fatta *in place* dentro il vblank → tile animati progettati perché la
riscrittura parziale non produca frame sporchi visibili.

### 1.2 Budget di banda VRAM per frame (Z80 3.58MHz, NTSC)

- Vblank: ~70 linee × 63.5µs ≈ 4.4ms ≈ **~15.900 T-states**. Con OUTI srotolato
  (~18T/byte) e tolto l'overhead di ISR/setup: **~700-800 byte sicuri a 60Hz**.
- Display attivo: scritture VRAM ammesse con pacing ≥29T tra accessi →
  loop da ~31T/byte per **~1.2-1.4KB extra** se si dedica il frame al transfer.
- Regola di progetto: **il gameplay usa solo il vblank (~700B/frame)**; i transfer
  grossi (cambio stanza, boss, cutscene) usano frame dedicati con schermo attivo
  o disabilitato (BLANK: banda piena, ~2 frame per riempire pattern+colori).

Da verificare al prototipo 0: misurare il numero esatto di OUTI che entrano nel
vblank su openMSX con macchina MSX1 reale (Canon V-20 / SVI-728), bordo colorato
come gauge stile Black Tiger.

### 1.3 Le tecniche di punta (tutte compatibili col budget sopra)

1. **Mare a scorrimento via animazione pattern, SOLO pattern.** Trucco chiave:
   i tile d'acqua hanno **color table statica** (righe di colore fisse), si
   riscrivono solo gli 8 byte di pattern per tile. 8 fasi pre-shiftate in ROM.
   - 64 tile animati = 512 byte/frame → scroll a pixel a 60Hz dentro il vblank.
   - 2-3 bande a velocità diverse (onde vicine 60Hz, lontane 30Hz, cielo 20Hz)
     = parallasse su MSX1. Le bande a frequenza ridotta dimezzano il costo.
2. **Boss giganti a tile** (Polifemo, Scilla): il corpo è name+pattern, animato
   riscrivendo solo i tile che cambiano tra frame (delta pre-calcolati dal tool,
   lista `(addr, len, dati)` per frame in ROM). Sprite solo per occhio/artigli.
   A ~700B/frame un boss da 8×10 tile può animare metà corpo a 30Hz.
3. **Sprite multi-layer + multiplexing**: formato 4 layer di Sam.Pr riusato per
   Ulisse a 3 colori; rotazione slot per superare i 4 sprite/linea con flicker
   controllato (già collaudato).
4. **Cutscene pseudo-FMV**: schermo in BLANK 1-2 frame o transfer paced su più
   frame; delta-frame compressi in ROM. Solo intro/attract/morti di boss,
   mai durante gameplay.
5. **Sample PSG** (canto delle sirene, "NESSUNO!" urlato, tuono): replay ~8kHz
   4bit da ROM. Mangia quasi tutta la CPU → si usa SOLO in momenti semi-interattivi
   (scena sirene con solo timone attivo, stacchi narrativi). ~4KB/secondo di ROM:
   con ASCII8 libero, 30-60 secondi di audio digitale non sono un problema.

---

## 2. Struttura di gioco

### 2.1 Flusso

```
Attract/Intro (tempesta FMV) → mappa del viaggio →
  [Navigazione] → [Isola/Episodio] → [Navigazione] → ... → Itaca (finale)
```

La mappa del viaggio mostra la rotta e la ciurma residua; le navigazioni sono
brevi (1-2 min), le isole sono il piatto forte (5-15 stanze flip-screen ciascuna).

### 2.2 La ciurma come risorsa persistente

Si parte con 12 compagni. Errori e eventi del mito ne costano alcuni
(Polifemo ne mangia, Scilla ne ghermisce). Effetti:
- Navigazione: meno rematori = nave più lenta/pesante da manovrare.
- Isole: i compagni sono i "continue" dell'episodio.
- Finale valutato anche su quanti ne riporti a casa → rigiocabilità e score.
Stato in RAM: pochi byte. Tutta la logica eventi in ROM per episodio.

### 2.3 Gli episodi (CORE — in ordine di sviluppo, non di gioco)

| # | Episodio | Genere | Meccanica firma | Vetrina tecnica |
|---|----------|--------|-----------------|-----------------|
| N | Navigazione (ricorrente) | avoid/ritmo | vento di Eolo direzionale | parallasse pattern-scroll |
| 1 | Polifemo | stealth + boss | rumore: salti/passi attirano il ciclope accecato | boss gigante a tile |
| 2 | Circe | platform-puzzle | trasformazione in maiale: moveset alternativo | doppio set sprite/anim |
| 3 | Eolo | platform | vento controllabile che curva salti e nemici | fisica con vettore vento |
| 4 | Sirene | navale scriptato | comandi attratti verso gli scogli; legarsi = perdere il controllo per salvarsi | sample PSG (canto) |
| 5 | Scilla e Cariddi | navale boss doppio | due minacce simultanee, corridoio stretto | vortice animato precalc + boss tile |
| 6 | Itaca | action + finale | l'arco: tiro attraverso le 12 scuri, poi i Proci | set-piece conclusivo |

### 2.4 Stretch goals (solo se il core è finito e rifinito)

- **Ade** (mondo dei morti): platform al buio con cerchio di luce attorno a Ulisse
  (fatto a tile: 4-5 anelli di pattern pre-shiftati). Atmosfera fortissima.
- **Lotofagi**: mini-episodio tutorial, controlli "sognanti" (inerzia alterata).
- Modalità time-attack per episodio sbloccabile.

Regola: meglio 6 episodi rifiniti che 9 mediocri. La giuria vede la cura, non la lista.

---

## 3. Architettura ROM (ASCII8, banchi da 8KB)

Pagine: 4000/6000/8000/A000 commutabili; kernel fisso in 4000.

| Banchi | Contenuto |
|--------|-----------|
| 0 | Kernel: boot, ISR, dispatcher banchi, routine VDP (OUTI srotolati), input |
| 1 | Engine platform: fisica, collisioni, entità, sprite multiplexer |
| 2 | Engine navale: pattern-scroll, vento, nave |
| 3 | Player musicale PSG + SFX + replayer sample |
| 4-5 | UI: mappa viaggio, HUD, font, menu, attract logic |
| 6-N | Per episodio: 1 banco codice/logica + 2-4 banchi asset (tileset, delta boss, stanze) |
| ... | Musiche (1 traccia/episodio), sample digitali, cutscene delta-frames |

Stima core: ~40-60 banchi (320-512KB). Con sample e FMV si arriva a 1MB comodi.
Lezione da Sam.Pr: **budget dei banchi tracciato da subito nel Makefile**
(il "Negative BLOCK?" di sjasmplus non deve più essere una sorpresa).

## 4. Mappa RAM (16KB: C000-FFFF)

| Area | Uso | Stima |
|------|-----|-------|
| C000- | Variabili engine, stato entità (max ~16 attive) | ~1.5KB |
| | Stato persistente: ciurma, flag episodi, inventario, score | ~256B |
| | Shadow name table (per flip e collisioni a tile) | 768B |
| | Shadow sprite attributes (OAM) | 128B |
| | Buffer transfer/decompressione stanza | ~2KB |
| | Stato player musicale + coda SFX | ~512B |
| | Stack (sotto area sistema F380) | ~512B |
| F380-FFFF | Area sistema/BIOS | — |

Totale ~6KB usati: margine ampio. Niente unpack giganti in RAM: i dati si
streammano dai banchi ROM direttamente in VRAM.

## 5. Pipeline e tooling (riuso da Sam.Pr / Black Tiger)

- sjasmplus + Makefile con controllo overflow banchi (da Sam.Pr).
- Tool Python di generazione: evoluzione di gen_iso.py → `gen_room.py` (stanze
  flip-screen a metatile), `gen_waves.py` (8 fasi pre-shiftate, verifica che la
  color table resti statica), `gen_bossdelta.py` (delta-frame per boss a tile),
  `gen_sample.py` (WAV → 4bit PSG).
- Testing: openMSX headless con script Tcl (matrice tasti, read VRAM/romblocks)
  — la suite di Sam.Pr si porta quasi pari pari. Macchine di riferimento:
  una MSX1 16KB giapponese + una europea 50Hz (il gioco DEVE gestire 50/60Hz:
  a 50Hz il vblank è più lungo, la musica va compensata).
- Attenzione FILVRM buggato su MSX1 (già documentato): usare routine proprie.

## 6. Milestone (7 mesi)

| Mese | Obiettivo | Gate di uscita |
|------|-----------|----------------|
| Set 2026 | **Proto 0**: misura banda vblank reale; demo pattern-scroll mare 3 bande + nave sprite | video del mare che scrolla a 60Hz su MSX1 |
| Ott | Engine platform portato + prima isola grigia (Polifemo senza grafica finale); boss a tile proof | stealth a rumore giocabile |
| Nov | Circe (maiale) + navigazione completa con vento; musica driver | 2 episodi giocabili in sequenza da mappa |
| Dic | Eolo + Sirene (sample PSG); grafica definitiva episodi 1-2 | demo natalizia interna completa al 50% |
| Gen 2027 | Scilla&Cariddi + Itaca; tutte le musiche | gioco completabile inizio-fine |
| Feb | Polish: grafica finale ovunque, bilanciamento, intro FMV, attract, 50Hz | playtest esterni (2-3 fidati) |
| Mar (1-10) | Freeze, bugfix, manuale, trailer, submission | consegna con ≥5 giorni di margine |

Regola anti-scope-creep: gli stretch goal si toccano solo se a fine gennaio il
core è completo. La tempesta FMV dell'intro si fa a febbraio, non prima.

## 7. Rischi principali

1. **Banda vblank insufficiente per il parallasse a 3 bande** → mitigazione:
   bande a 30/20Hz, meno tile animati; il proto 0 di settembre decide.
2. **Sample PSG + gameplay incompatibili** → per design i sample suonano solo
   in scene semi-interattive; nessun rischio se la regola si rispetta.
3. **Troppi episodi** → il taglio è già previsto: core 6, stretch separati.
4. **50Hz vs 60Hz** → testato da subito su due macchine, non a febbraio.
5. **Flicker sprite nei boss** → i boss sono a tile proprio per questo; gli
   sprite restano ≤8 in scena nei momenti caldi.
