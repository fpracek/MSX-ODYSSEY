# ODYSSEY — un'Odissea per MSX1 (MSXdev'26)

Action-platform episodico sull'Odissea. MSX1 puro (TMS9918, 16KB RAM),
MegaROM ASCII8, tutto in assembly Z80 (sjasmplus). Il design completo è
in [DESIGN.md](DESIGN.md).

## Stato: sezione navale giocabile (vinci o perdi)

Frecce (o joystick) = timone.

**La struttura** — le traversate collegano le isole del viaggio:
Ciclopi → Circe → Eolia → Sirene → Scilla → Itaca (che è solo
l'ULTIMA tappa). La scritta nel cielo è la destinazione della tratta
corrente (blocchi glifi+riga per tratta in sky_data, caricati dal
main; la tratta sopravvive al restart, `leg` a 0xC040). All'arrivo
si riparte verso l'isola successiva — lì un domani si aggancerà
l'episodio a terra.

**Il title screen** — all'accensione (e a viaggio completato):
bitmap SC2 in stile silhouette generata da gen_title.py — la triremi
nera con Ulisse a prua, lancia in pugno, contro un sole enorme al
tramonto; cielo a bande sfumate a dither, scia dorata sul mare,
gabbiani, "THE ODYSSEY" in oro col fregio a meandro. Sotto, il
**tema musicale PSG a 3 canali** (gen_music.py): melodia in MI
frigio dominante (la scala "egea"), basso ostinato in ottave come
un battito di remi, bordone di quinte — loop di 16s, driver a
stream (nota,durata) tickato dal loop del titolo. FIRE → pergamena.

**La pergamena del viaggio** — all'inizio di ogni traversata una
mappa bitmap SC2 pre-renderizzata (gen_map.py): pergamena, le 7
isole coi nomi, la rotta percorsa in rosso scuro pieno, la tratta
che inizia in rosso vivo doppio, le future a puntini d'inchiostro,
la nave sull'isola di partenza. Sotto, il **tema della lira**:
arpeggi in MI minore a tempo dimezzato, melodia che parte da SOL,
lira in primo piano (volumi per-brano nel driver) — inconfondibile
rispetto al tema del titolo. Si salpa con SPACE/FIRE. Titolo e
pergamena entrano ed escono in **dissolvenza** (niente palette sul
TMS9918: la color table viene riscritta a gradini attraverso LUT
di oscuramento, in rate da 1KB per frame con la musica che
continua — gen_fade.py + fade_pass). Sei
varianti complete (12KB l'una) nei banchi 8-19: la ROM paga, il
runtime copia e basta. La **ciurma superstite prosegue di tratta
in tratta** (si torna in 12 solo dopo un naufragio).

**La sfida** — la ciurma è le vite, il vento è il tempo:
- **Vinci** arrivando all'isola della tratta: la barra di rotta (in
  alto a destra) avanza alla velocità del mare, cioè del vento. **La
  tempesta fa avanzare il doppio ma porta i fulmini**: il rischio
  paga.
- **Perdi** a ciurma zero: 12 compagni (in alto a sinistra), ogni
  fulmine preso ne costa uno (1,5s di invulnerabilità lampeggiante).
- **Meteo**: sereno (~10s) ↔ tempesta (~12s). In tempesta il cielo
  diventa NERO (recolor one-shot: 176 byte, il sole sparisce,
  l'orizzonte resta livido), Eolo soffia sempre 64..95, e cadono
  fulmini ogni 1-2s: lampo bianco di avviso, scarica a zigzag (3
  sprite, metà cadono vicino alla nave), tuono sul canale A del PSG.
- **Nel sereno lo scoglio**: la schiuma ribolle (avviso ~4s, col
  suo **sfrigolio** sul canale A), poi il masso rompe l'acqua con
  uno **splash** (burst di rumore chiaro, distinto dal tuono cupo)
  e resta lì ~3s — va aggirato col timone, toccarlo costa un
  compagno. Metà degli scogli affiorano sulla rotta della nave.
  Priorità sul canale effetti: tuono/schianto > gabbiano > ribollio.
  Gli effetti hanno **inviluppi veri**: il tuono è schiocco brillante
  (8 frame a volume pieno) poi rombo cupo che ondeggia e sfuma con
  tremolo; lo splash è uno sweep rapido brillante→scuro. Durante
  ogni effetto la risacca va in sordina (ducking): il generatore di
  rumore dell'AY è uno solo e condiviso.
- **FAIRNESS** (ogni colpo deve essere evitabile): il fulmine dà
  ~1s di preavviso — un bagliore giallo intermittente nel punto
  esatto della scarica (col timone a 0,75 px/f si esce sempre dalla
  zona, anche controvento); e non viene MAI mirato sulla nave se
  uno scoglio le sta già limitando la manovra. I fulmini sono
  sequenziali: mai due minacce dal cielo insieme.
- **L'approdo**: a rotta completa niente più pericoli; il vento si
  placa, la nave accosta verso l'isola e sale verso l'orizzonte
  rimpicciolendo (sprite "nave lontana"), una pausa, e si prosegue
  alla tratta successiva. Cinematica sul motore vivo (l'ISR
  continua: bande, risacca, HUD).
- **Il gabbiano di buon auspicio**: oltre metà rotta, col bel tempo,
  attraversa il cielo con due richiami (tono PSG sul canale A) —
  dice al giocatore che la terra si avvicina. Innocuo.
- **L'isola della tratta appare all'orizzonte** a rotta quasi
  compiuta (21/24): 8 tile statici disegnati una volta sola, con
  variante colore per la tempesta (il recolor la tiene coerente).
  L'avvistamento è annunciato dal richiamo del gabbiano: "terra!".
- Arrivo/naufragio: lampeggio (bianco-cyan / rosso-nero) e il
  viaggio ricomincia.

- **Mare a parallasse senza scroll hardware**: 4 bande che scorrono a
  pixel riscrivendo **solo i pattern** nel vblank, con velocità
  **frazionarie 8.8** accumulate per banda (il costo del blast non
  dipende dal passo). La color table è statica per contratto: per ogni
  riga-pixel di una banda un solo fg/bg su tutta la larghezza → 8
  byte/tile per frame, mai un byte di colore.
- **Vento di Eolo**: raffiche-obiettivo da tabella ogni ~2,5s, il vento
  corrente le insegue (slew 1 ogni 2 frame, range −96..+96). Il vento
  modula le velocità di TUTTE le bande (A/A2: 1.0+v/128, B: 0.5+v/256,
  C: 0.33+v/512 px/frame — solo somme, zero moltiplicazioni) e spinge
  la nave in deriva.
- **Timone**: fisica 8.8 nel main loop — spinta timone ±12/frame,
  vento/16 di deriva, attrito vx/16. A regime il timone (0,75 px/f)
  vince sempre il vento massimo (0,37 px/f): si può risalire una
  raffica contraria, ma costa. Clamp ai bordi.
- **Cielo** (tutto statico, zero costo runtime): scritta "TO ITHACA"
  con glifi in stile lapidario greco (A=lambda, C=sigma lunato) ma
  leggibili in inglese, sole, e 2 righe di foschia a dither che
  sfumano il cielo verso il cyan dell'orizzonte (gen_sky.py).
- **Risacca PSG**: rumore sui canali B+C con due swell sinusoidali
  sfasati (passi da 8 e 6 frame: interferenza naturale); il periodo
  del rumore respira col volume. Tutto nell'ISR, ~niente CPU.
- **La nave**: triremi 32×16 a 2 layer di sprite (scafo+albero legno,
  vela+pennone bianchi) = 4 sprite 16×16 sulle stesse linee, esattamente
  il limite del TMS9918 (coi nemici navali servirà il multiplexing).
  Beccheggia su una sinusoide a 16 passi; OAM riscritto ogni frame
  nell'ISR. Vela contro l'orizzonte, scafo sulla banda media.
- **Gauge del bordo** (stile Black Tiger): bordo bianco durante il blast
  VRAM. Se la barra raggiunge l'area attiva, si è fuori budget.
- **Self-test del mapper ASCII8** al boot (firma "N4" nel banco 4);
  se fallisce, bordo rosso fisso.
- **Misura reale** (`make measure`, 300 frame su C-BIOS MSX1):
  blast min 1,96 / media 2,45 / max 2,82 ms contro un budget di ~4,4 ms
  a 60Hz. La logica (vento, meteo, fulmini, fisica, input) gira nel
  main loop in display time; l'ISR fa solo VDP e PSG.
- **Test scriptati**: `test/boot.tcl` (mapper, hook, PSG, screenshot),
  `test/wind.tcl` (deriva + timone contro vento), `test/storm.tcl`
  (tempesta, fulmini, ciurma, rotta), `test/calm.tcl` (scoglio,
  isola, gabbiano), `test/measure.tcl` (banda vblank).

## Struttura

```
src/main.asm         kernel banco 0 + Proto 0 (unico sorgente asm)
src/waves_data.asm   GENERATO da gen_waves.py — non toccare a mano
src/ship_data.asm    GENERATO da gen_ship.py — non toccare a mano
src/sky_data.asm     GENERATO da gen_sky.py — non toccare a mano
src/mapK_*.bin       GENERATI da gen_map.py — le 6 pergamene
tools/gen_waves.py   bande del mare: 8 preshift + colori statici
tools/gen_ship.py    sprite: nave, fulmine, scoglio, gabbiano
tools/gen_sky.py     cielo, tratte, HUD, isola (font pseudo-greco)
tools/gen_map.py     pergamena del viaggio (bitmap SC2 per tratta)
test/boot.tcl        boot headless: mapper + hook + screenshot
test/measure.tcl     misura del blast (label gauge_on/gauge_off)
build/               odyssey.rom (64KB, 8 banchi), .sym, preview, esiti
avvia_odyssey.bat    build + avvio openMSX  [fast] [60]
Makefile             all / waves / ship / test / measure
```

## Build e prova

```
avvia_odyssey            build completo, avvio su Sony HB-55P (50Hz)
avvia_odyssey 60         avvio su C-BIOS_MSX1 (60Hz) — provare SEMPRE entrambe
avvia_odyssey fast       salta la rigenerazione dei dati
```

Headless: `make test` (boot + screenshot in build/shot.png, esito in
build/boot_result.txt), `make measure` (durata del blast su 300 frame,
esito in build/measure_result.txt). Nota Windows: openmsx.exe non
scrive sulla console e il driver SDL dummy lo fa uscire subito — gli
script Tcl scrivono su file e la finestra si chiude da sola.

## Manopole

- `BURN_CHUNKS` (main.asm): blocchi extra da 256 byte nel vblank verso
  l'area sprite libera; alzalo finché il gauge tocca l'area attiva.
- `SHIP_X` / `SHIP_Y` (main.asm): posizione della nave.
- `--tiles=A,B,C` di gen_waves.py: larghezza bande in tile (potenze
  di 2, max 32); texture in `tex_a/tex_b/tex_c`.
- Art della nave: matrice ASCII `ART` in gen_ship.py ('.'=trasparente,
  H=scafo, M=albero, S=vela); preview in build/ship_preview.png.

## Layout ROM (ASCII8, banchi da 8KB)

| Banco | Contenuto |
|-------|-----------|
| 0 | kernel: boot, init VDP, ISR blast+OAM, routine VDP (no FILVRM: buggato) |
| 1 | dati generati: mare + sprite + cielo/tratte (fisso in pagina 6000h) |
| 2-3 | riservati engine (mappati di default) |
| 4 | firma self-test "N4" + asset futuri |
| 5-7 | riserva |
| 8-19 | pergamene: tratta k → banco 8+2k pattern, 9+2k colori |
| 20-21 | title screen (pattern + colori) |
| 22-31 | riserva (ROM totale 256KB) |

Le guardie `DS <fine banco>-$` fanno fallire sjasmplus con "Negative
BLOCK?" se un banco trabocca: l'overflow si scopre in build, mai in ROM.

## RAM (C000-FFFF)

Variabili a EQU fissi da `banktest_ok` (C000h, letto dai test tcl) in
poi. Il proto usa 6 byte; la mappa completa prevista è in DESIGN.md.

## Prossimi passi (da DESIGN.md)

1. Vento di Eolo: velocità delle bande modulata (offset frazionari
   8.8) + deriva orizzontale della nave → fisica firma del navale.
2. Nemici/ostacoli navali → multiplexing sprite (rotazione slot).
3. Musica PSG di navigazione (hook già nel posto giusto).
4. Poi: engine platform (banco 2), primo episodio Polifemo.
