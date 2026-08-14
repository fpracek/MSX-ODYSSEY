; ============================================================
;  ODYSSEY - un'Odissea per MSX1 (MSXdev'26)
;  Proto 0: mare a 3 bande in pattern-scroll + nave a 2 layer
;           + gauge di banda vblank
;  MSX1 (16KB RAM) + MegaROM ASCII8 - TMS9918, SCREEN 2
;  Assembler: sjasmplus            (design: DESIGN.md)
;
;  Cosa dimostra questo proto:
;   - parallasse su MSX1 senza scroll hardware: 3 bande di mare che
;     scorrono a 60/30/20Hz riscrivendo SOLO i pattern nel vblank
;     (color table statica: 8 byte/tile, mai riscritti)
;   - gauge del bordo (stile Black Tiger): bordo bianco mentre il
;     blast VRAM e' in corso; se la barra tocca l'area attiva si e'
;     fuori budget
;   - self-test del mapper ASCII8 al boot (firma "N4" nel banco 4)
; ============================================================

        OUTPUT "build/odyssey.rom"

; ---------- BIOS ----------
WRTVDP  equ 0047h
CHGMOD  equ 005Fh
GTSTCK  equ 00D5h
GTTRIG  equ 00D8h
SNSMAT  equ 00141h      ; A=riga matrice -> A=bit (0=premuto)
ENASLT  equ 00024h
RSLREG  equ 00138h
EXPTBL  equ 0FCC1h
HTIMI   equ 0FD9Fh      ; hook interrupt di frame (5 byte di RAM)

; ---------- VRAM (Screen 2) ----------
VR_PAT  equ 00000h
VR_NAME equ 01800h
VR_SPRA equ 01B00h
VR_NAME2 equ 01C00h     ; secondo name table (flip futuro, libero qui)
VR_COL  equ 02000h
VR_SPRP equ 03800h      ; pattern sprite: 128 byte per la nave, il
                        ; resto e' libero (area burn da +80h in poi)

; ---------- ASCII8 mapper ----------
BANK0R  equ 06000h
BANK1R  equ 06800h
BANK2R  equ 07000h
BANK3R  equ 07800h

; ---------- config Proto 0 ----------
; BURN_CHUNKS: blocchi extra da 256 byte scritti nel vblank verso
; l'area sprite (inutilizzata), SOLO per sondare il limite di banda:
; alza il valore finche' la barra bianca del bordo raggiunge l'area
; attiva dello schermo. 0 = solo il mare.
BURN_CHUNKS equ 0
GAUGEC  equ 0Fh         ; bordo durante il blast (bianco)
BORDERC equ 01h         ; bordo a riposo (nero)

; ---------- layout bande sullo schermo ----------
; terzo 1 = righe 8-15, terzo 2 = righe 16-23 (pattern table SC2)
; foschia righe 8-9, C (orizzonte) 10-11, B (media) 12-15,
; A (vicina) 16-19, A2 (vicinissima) 20-23. A e A2 stessa velocita',
; texture diverse: varieta' verticale senza costo di parallasse.
TBASE_B equ 1                   ; tile 1..W_B nel terzo 1
TBASE_C equ TBASE_B+WAVES_B_W   ; subito dopo la banda B
HAZE_T0 equ TBASE_C+WAVES_C_W   ; 2 tile di foschia dopo la banda C
TBASE_A equ 1                   ; tile 1..W_A nel terzo 2
TBASE_A2 equ TBASE_A+WAVES_A_W  ; subito dopo la banda A
WAVES_A_VPAT equ VR_PAT+1000h+TBASE_A*8
WAVES_A2_VPAT equ VR_PAT+1000h+TBASE_A2*8
WAVES_B_VPAT equ VR_PAT+0800h+TBASE_B*8
WAVES_C_VPAT equ VR_PAT+0800h+TBASE_C*8

; ---------- nave ----------
; 32x16, 2 layer (scafo+albero / vela) = 4 sprite 16x16 sulle stesse
; linee: ESATTAMENTE il limite di 4/linea del TMS9918. Quando
; arriveranno i nemici navali servira' il multiplexing (rotazione
; slot di Sam.Pr). Scafo prima della vela = l'albero passa davanti.
SHIP_X  equ 84          ; posizione di partenza (poi governa il timone)
SHIP_Y  equ 85          ; attributo Y (riga video -1): vela contro
                        ; l'orizzonte (banda C), scafo sulla banda B
RUDDER_ACC equ 12       ; spinta del timone (8.8 per frame); con
                        ; attrito 1/16 la velocita' a regime e'
                        ; 12*16 = 0.75 px/frame: piu' del vento
                        ; massimo (96/16*16 = 0.375), si puo' sempre
                        ; risalire una raffica contraria
GUST_LEN equ 150        ; frame tra le raffiche di Eolo (~2.5s a 60Hz)

; ---------- la sfida del navale ----------
; La ciurma e' le vite (12 compagni, un colpo = un compagno, 0 = fine
; del viaggio). Il vento e' il tempo: la rotta avanza alla velocita'
; del mare, la tempesta fa avanzare il doppio ma porta i fulmini.
CREW0   equ 12          ; compagni alla partenza
SERENO_DUR equ 600      ; frame di sereno (~10s a 60Hz)
STORM_DUR  equ 700      ; frame di tempesta
TARGET_H  equ 24        ; arrivo della PRIMA tratta (le successive
                        ; crescono: vedi diff_tab e v_target)
BOLT_DUR  equ 12        ; frame di fulmine visibile
BOLT_WARN equ 55        ; preavviso: il cielo "si carica" sul punto
                        ; della scarica (~1s). FAIRNESS: col timone a
                        ; 0.75px/frame la zona (|dx|<14) si evacua
                        ; sempre, anche controvento (0.37px/frame)
IFRAMES   equ 90        ; invulnerabilita' dopo un colpo (~1.5s)
HUD_MAN  equ 12         ; tile HUD (terzo 0, da gen_sky.py)
HUD_DOT  equ 14
HUD_FILL equ 15
BOLT_PAT equ 16         ; pattern sprite del fulmine (dopo la nave)
FOAM_PAT equ 20         ; schiuma d'avviso del mostro marino
ROCK_PAT equ 24         ; mostro marino: il collo (la base)
GULL_PAT equ 28         ; gabbiano (28/32: due frame d'ali)
SERP_HEAD1 equ 40       ; mostro marino: testa, 2 frame d'ondeggio
SERP_HEAD2 equ 44
CREW_COL equ 1          ; colonna HUD del primo marinaio
BAR_COL  equ 19         ; colonna HUD della barra di rotta
; scoglio: fasi dal contatore unico rock_t (che scende da TOTAL)
ROCK_TOTAL  equ 250
ROCK_T_FOAM equ 200     ; t>200: schiuma d'avviso
ROCK_T_RISE equ 180     ; 200>=t>180: emerge
ROCK_T_SINK equ 40      ; 40>=t>20: affonda (collide se 40<t<=200)
ROCK_T_GONE equ 20      ; t<=20: sparito
MAP_BANK0 equ 8         ; pergamene: banco 8+2k pattern, 9+2k colori
TITLE_BANK equ 20       ; title screen: banco 20 pattern, 21 colori
MUS_VA  equ 12          ; titolo: melodia avanti, basso che spinge
MUS_VB  equ 10
MUS_VC  equ 7
MAP_VA  equ 9           ; pergamena: lira in primo piano,
MAP_VB  equ 11          ; melodia soffusa
MAP_VC  equ 6
ISL_T0   equ HAZE_T0+2  ; primi degli 8 tile dell'isola (terzo 1)
ISL_PROG equ 21         ; prog_h a cui la PROSSIMA isola appare
                        ; all'orizzonte (quella della tratta, non
                        ; Itaca: Itaca e' solo l'ultima)

; ---------- RAM (16KB: C000-FFFF, area sistema da F380) ----------
banktest_ok equ 0C000h  ; 0AAh = mapper ASCII8 verificato (test tcl)
frame_cnt   equ 0C001h
cntA        equ 0C002h  ; offset di scroll banda A (0..W*8-1)
cntB        equ 0C003h
cntC        equ 0C004h
cntA2       equ 0C006h
sw_ib       equ 0C007h  ; risacca: indice swell canale B
sw_ic       equ 0C008h  ; indice swell canale C
sw_db       equ 0C009h  ; divisori di passo dei due swell
sw_dc       equ 0C00Ah
; velocita' di scroll 8.8 (px/frame) calcolate dal vento nel main
; loop; l'ISR le accumula in fracX e scrolla di un pixel a carry
spdA2_l     equ 0C00Bh
spdA2_h     equ 0C00Ch
spdA_l      equ 0C00Dh
spdA_h      equ 0C00Eh
spdB_l      equ 0C00Fh
spdB_h      equ 0C010h
spdC_l      equ 0C011h
spdC_h      equ 0C012h
fracA2      equ 0C013h
fracA       equ 0C014h
fracB       equ 0C015h
fracC       equ 0C016h
; vento di Eolo: valore corrente (signed, -96..+96), obiettivo di
; raffica, e stato della sequenza di raffiche
wind        equ 0C017h
wind_tgt    equ 0C018h
wind_div    equ 0C019h  ; slew ogni 2 frame
gust_idx    equ 0C01Ah
gust_t      equ 0C01Bh
; nave: posizione e velocita' orizzontali in 8.8
ship_xl     equ 0C01Ch
ship_xh     equ 0C01Dh
ship_vxl    equ 0C01Eh
ship_vxh    equ 0C01Fh
; sfida navale
mode        equ 0C020h  ; 0=gioco, 1=arrivo (vittoria), 2=ciurma persa
weather     equ 0C021h  ; 0=sereno, 1=tempesta
wtimer_l    equ 0C022h
wtimer_h    equ 0C023h
bolt_t      equ 0C024h  ; frame di fulmine attivo rimasti
bolt_timer  equ 0C025h  ; conto alla rovescia al prossimo fulmine
bolt_x      equ 0C026h
flash_t     equ 0C027h  ; lampo bianco (bordo)
bcol_t      equ 0C028h  ; bordo rosso dopo un colpo
iframes     equ 0C029h
thunder_t   equ 0C02Ah  ; tuono PSG (canale A)
crew        equ 0C02Bh
hud_dirty   equ 0C02Ch
prog_l      equ 0C02Dh  ; progresso di rotta a 24 bit
prog_m      equ 0C02Eh
prog_h      equ 0C02Fh
bar_cur     equ 0C030h  ; tacche di rotta mostrate
rndseed     equ 0C031h
recolor     equ 0C032h  ; 1 = passa a tempesta, 2 = torna al sereno
bolt_cnt    equ 0C033h  ; contatore fulmini (per i test)
rock_t      equ 0C034h  ; scoglio attivo: countdown fasi (vedi ROCK_*)
rock_timer  equ 0C035h  ; attesa del prossimo scoglio (solo sereno)

; la difficolta' della TRATTA corrente (da diff_tab, caricata a
; ogni init: piu' lontano da Troia = rotte piu' lunghe e cattive)
v_target    equ 0C088h  ; prog_h d'arrivo
v_boltmin   equ 0C089h  ; intervallo minimo fra i fulmini
v_rockmin   equ 0C08Ah  ; intervallo minimo fra i mostri
v_ser       equ 0C08Bh  ; dw: frame di sereno
v_sto       equ 0C08Dh  ; dw: frame di tempesta
v_islp      equ 0C08Fh  ; prog_h a cui l'isola appare

; RENZO: digitato sul titolo, la ciurma non si consuma mai.
; Il flag vive FUORI dalle aree azzerate (kernel C000-3F,
; episodi C050-C3FF) e si spegne solo a nuova partita.
god_flag    equ 0C440h  ; 0A5h = attivo
renzo_idx   equ 0C441h  ; avanzamento sequenza (bit7 = tenuto)
rock_x      equ 0C036h
gull_t      equ 0C037h  ; gabbiano in volo: countdown = anche la sua X
gull_timer  equ 0C038h
chirp_t     equ 0C039h  ; richiamo del gabbiano (tono A)
island_flag equ 0C03Ah  ; 0=no, 1=da disegnare (ISR), 2=disegnata
rock_cnt    equ 0C03Bh  ; contatore scogli (per i test)
sfx_type    equ 0C03Ch  ; profilo dell'effetto sul canale A:
                        ; 0 = tuono (schiocco + rombo), 1 = splash
cheat_idx   equ 0C03Fh  ; avanzamento della sequenza GOTO (bit7 =
                        ; attesa del rilascio del tasto accettato)
ship_y      equ 0C03Dh  ; Y della nave (fissa in gioco, sale
                        ; verso l'orizzonte durante l'approdo)
land_hold   equ 0C03Eh  ; pausa finale dell'approdo
RAM_CLR_LEN equ 64
; FUORI dall'area azzerata: la tratta corrente sopravvive al
; jp init di fine viaggio (arrivo -> tratta successiva)
leg         equ 0C040h  ; 0..N_DESTS-1: indice della traversata
leg_magic   equ 0C041h  ; 5Ah = leg valido (primo avvio a freddo)
crew_keep   equ 0C042h  ; ciurma superstite che prosegue il viaggio
; musica del titolo (vive solo prima dell'hook: init espliciti)
musA_p      equ 0C043h
musA_c      equ 0C045h
musB_p      equ 0C046h
musB_c      equ 0C048h
musC_p      equ 0C049h
musC_c      equ 0C04Bh
musVA       equ 0C04Ch  ; volumi del brano corrente (per canale)
musVB       equ 0C04Dh
musVC       equ 0C04Eh
phase       equ 0C04Fh  ; 0 = traversata, 1 = episodio a terra
                        ; (sopravvive al jp init: sbarco e retry)

; ============================================================
;  BANCO 0: kernel + Proto 0
; ============================================================
        ORG 04000h
        db  "AB"
        dw  init
        dw  0,0,0,0,0,0

init:
        di
        ; abilita il nostro slot su pagina 2 (8000-BFFF)
        call RSLREG
        rrca
        rrca
        and 3
        ld  c,a
        ld  b,0
        ld  hl,EXPTBL
        add hl,bc
        ld  a,(hl)
        and 80h
        or  c
        ld  c,a
        inc hl
        inc hl
        inc hl
        inc hl
        ld  a,(hl)
        rrca
        rrca
        and 3
        rlca
        rlca
        or  c
        ld  h,80h
        call ENASLT
        di

        ; ASCII8: banchi 0..3 sulle 4 pagine
        xor a
        ld  (BANK0R),a
        inc a
        ld  (BANK1R),a
        inc a
        ld  (BANK2R),a
        inc a
        ld  (BANK3R),a

        ; pulizia variabili
        ld  hl,banktest_ok
        ld  de,banktest_ok+1
        ld  bc,RAM_CLR_LEN-1
        ld  (hl),0
        ldir

        ei
        ld  a,2
        call CHGMOD
        ld  b,11100010b     ; screen on, IE, sprite 16x16
        ld  c,1
        call WRTVDP
        ld  b,BORDERC
        ld  c,7
        call WRTVDP

        ; la tratta corrente (le traversate collegano le isole del
        ; viaggio; Itaca e' solo l'ULTIMA destinazione). leg e
        ; crew_keep vivono FUORI dall'area azzerata.
        ld  a,(leg_magic)
        cp  05Ah
        jr  z,.legok
        xor a
        ld  (leg),a
        ld  (phase),a
        ld  (god_flag),a    ; RENZO si ridigita a ogni partita
        ld  a,CREW0
        ld  (crew_keep),a
        ld  a,05Ah
        ld  (leg_magic),a
        ; il viaggio comincia: title screen col tema del titolo
        call title_show
.legok:

        ; siamo SBARCATI? l'episodio a terra parte diretto
        ld  a,(phase)
        or  a
        jr  z,.mare
        cp  1
        jp  z,ep_start      ; 1: Polifemo (banchi 2/3, default)
        ld  a,6             ; 2: CIRCE - banchi 6 (codice) e 7 (dati)
        ld  (BANK2R),a
        ld  a,7
        ld  (BANK3R),a
        jp  circe.ep_start
.mare:

        ; la pergamena del viaggio: rotta percorsa e prossima tratta
        call map_show

        ; ---- caricamento grafica sotto DI: la lettura di S#0 fatta
        ;      dall'ISR del BIOS azzererebbe il latch indirizzi del VDP
        ;      in mezzo alle sequenze a 2 byte ----
        di

        ; pattern 0000-17FF = 0 (tile 0 = cielo vuoto)
        xor a
        ld  de,VR_PAT
        ld  bc,1800h
        call vdp_fill
        ; name table tutto tile 0
        xor a
        ld  de,VR_NAME
        ld  bc,768
        call vdp_fill
        ; sprite spenti: primo Y = 208
        ld  a,208
        ld  de,VR_SPRA
        ld  bc,1
        call vdp_fill
        ; colori: cielo ovunque (bianco su azzurro chiaro)
        ld  a,0F5h
        ld  de,VR_COL
        ld  bc,1800h
        call vdp_fill

        ; cielo: tile del terzo 0 (scritta greca + sole), righe 0-7
        ld  hl,sky_pat
        ld  de,VR_PAT
        ld  bc,128
        call vdp_copy
        ld  hl,sky_col
        ld  de,VR_COL
        ld  bc,128
        call vdp_copy
        ld  hl,sky_rows
        ld  de,VR_NAME
        ld  bc,256
        call vdp_copy

        ; nome della destinazione: glifi (slot 1-7 e 13) + riga 2
        ld  a,(leg)
        add a,a
        add a,a             ; *4 (dw pat, dw row)
        ld  l,a
        ld  h,0
        ld  bc,dest_tab
        add hl,bc
        ld  e,(hl)
        inc hl
        ld  d,(hl)
        inc hl
        ld  c,(hl)
        inc hl
        ld  b,(hl)          ; BC = riga, DE = pattern
        push bc
        ex  de,hl
        ld  de,VR_PAT+1*8   ; 7 glifi nei tile 1-7
        ld  bc,56
        call vdp_copy
        ld  de,VR_PAT+13*8  ; ottavo glifo nel tile 13
        ld  bc,8
        call vdp_copy
        pop hl
        ld  de,VR_NAME+2*32
        ld  bc,32
        call vdp_copy
        ; foschia dell'orizzonte: 2 tile statici, righe 8-9
        ld  hl,haze_pat
        ld  de,VR_PAT+0800h+HAZE_T0*8
        ld  bc,16
        call vdp_copy
        ld  hl,haze_col
        ld  de,VR_COL+0800h+HAZE_T0*8
        ld  bc,16
        call vdp_copy
        ld  a,HAZE_T0
        ld  de,VR_NAME+8*32
        ld  bc,32
        call vdp_fill
        ld  a,HAZE_T0+1
        ld  de,VR_NAME+9*32
        ld  bc,32
        call vdp_fill

        ; colori delle bande - statici: e' il contratto che rende lo
        ; scroll "gratis" (mai riscritti a runtime)
        ld  de,VR_COL+0800h+TBASE_B*8
        ld  b,WAVES_B_W
        ld  hl,wavesB_rowcol
        call fill_colors
        ld  de,VR_COL+0800h+TBASE_C*8
        ld  b,WAVES_C_W
        ld  hl,wavesC_rowcol
        call fill_colors
        ld  de,VR_COL+1000h+TBASE_A*8
        ld  b,WAVES_A_W
        ld  hl,wavesA_rowcol
        call fill_colors
        ld  de,VR_COL+1000h+TBASE_A2*8
        ld  b,WAVES_A2_W
        ld  hl,wavesA2_rowcol
        call fill_colors

        ; pattern sprite: nave + fulmine + schiuma + mostro marino
        ; (collo e 2 teste) + gabbiano + nave lontana (12 = 384 byte)
        ld  hl,ship_patterns
        ld  de,VR_SPRP
        ld  bc,384
        call vdp_copy

        ; pattern iniziali (preshift 0)
        ld  hl,wavesB_ps
        ld  de,WAVES_B_VPAT
        ld  bc,WAVES_B_W*8
        call vdp_copy
        ld  hl,wavesC_ps
        ld  de,WAVES_C_VPAT
        ld  bc,WAVES_C_W*8
        call vdp_copy
        ld  hl,wavesA_ps
        ld  de,WAVES_A_VPAT
        ld  bc,WAVES_A_W*8
        call vdp_copy
        ld  hl,wavesA2_ps
        ld  de,WAVES_A2_VPAT
        ld  bc,WAVES_A2_W*8
        call vdp_copy

        ; name table delle bande: base + (colonna AND W-1)
        ld  de,VR_NAME+10*32    ; C: righe 10-11
        ld  b,2
        ld  c,TBASE_C
        ld  l,WAVES_C_W-1
        call fill_rows
        ld  de,VR_NAME+12*32    ; B: righe 12-15
        ld  b,4
        ld  c,TBASE_B
        ld  l,WAVES_B_W-1
        call fill_rows
        ld  de,VR_NAME+16*32    ; A: righe 16-19
        ld  b,4
        ld  c,TBASE_A
        ld  l,WAVES_A_W-1
        call fill_rows
        ld  de,VR_NAME+20*32    ; A2: righe 20-23
        ld  b,4
        ld  c,TBASE_A2
        ld  l,WAVES_A2_W-1
        call fill_rows

        ; ---- self-test del mapper: il banco 4 inizia con "N4" ----
        ld  a,4
        ld  (BANK2R),a
        ld  a,(08000h)
        cp  'N'
        jr  nz,.bkbad
        ld  a,(08001h)
        cp  '4'
        jr  nz,.bkbad
        ld  a,2
        ld  (BANK2R),a
        ld  a,0AAh
        ld  (banktest_ok),a
        jr  .bkok
.bkbad:
        ld  a,055h
        ld  (banktest_ok),a
        ld  b,6             ; bordo rosso fisso: errore evidente
        ld  c,7
        call WRTVDP
        di
        halt
.bkok:

        ld  a,1
        ld  (sw_db),a
        ld  (sw_dc),a

        ; vento iniziale: brezza favorevole; velocita' gia' pronte
        ; PRIMA che l'ISR parta
        ld  a,48
        ld  (wind),a
        ld  (wind_tgt),a
        ld  a,GUST_LEN
        ld  (gust_t),a
        ld  a,SHIP_X
        ld  (ship_xh),a     ; ship_xl/vx gia' azzerati dalla pulizia
        ld  a,SHIP_Y
        ld  (ship_y),a
        call update_speeds

        ; PSG: risacca su B+C, canale A riservato al tuono, toni off
        ; (R7 bit7-6 = 10: direzioni porte I/O standard MSX)
        ld  a,7
        out (0A0h),a
        ld  a,10000110b     ; rumore su A+B+C, tono A (gabbiano)
        out (0A1h),a
        ld  a,8
        out (0A0h),a
        xor a
        out (0A1h),a        ; canale A muto finche' non tuona

        ; stato della sfida: la ciurma superstite prosegue il
        ; viaggio di tratta in tratta (12 solo a viaggio nuovo)
        ld  a,(crew_keep)
        or  a
        jr  z,.crewdef
        cp  CREW0+1
        jr  c,.crewok
.crewdef:
        ld  a,CREW0
.crewok:
        ld  (crew),a
        ld  a,1
        ld  (hud_dirty),a   ; l'HUD parte dalla ciurma vera
        ld  (rndseed),a     ; mai 0 (LFSR)
        xor a
        ld  (sfx_type),a    ; profilo di default: tuono
        ; la difficolta' della tratta: 6 byte da diff_tab[leg]
        ld  a,(leg)
        ld  l,a
        ld  h,0
        add hl,hl
        ld  b,h
        ld  c,l
        add hl,hl
        add hl,bc           ; *6
        ld  bc,diff_tab
        add hl,bc
        ld  a,(hl)
        ld  (v_target),a
        inc hl
        ld  a,(hl)
        ld  (v_boltmin),a
        inc hl
        ld  a,(hl)
        ld  (v_rockmin),a
        inc hl
        ld  e,(hl)          ; sereno/4
        inc hl
        ld  d,(hl)          ; tempesta/4
        inc hl
        ld  a,(hl)
        ld  (v_islp),a
        ld  l,e
        ld  h,0
        add hl,hl
        add hl,hl
        ld  (v_ser),hl
        ld  l,d
        ld  h,0
        add hl,hl
        add hl,hl
        ld  (v_sto),hl
        ld  hl,(v_ser)
        ld  (wtimer_l),hl
        ld  a,180
        ld  (rock_timer),a
        ld  a,100
        ld  (gull_timer),a

        ; hook di frame: tutto il lavoro VDP vive li'
        ld  a,0C3h
        ld  (HTIMI),a
        ld  hl,irq_hook
        ld  (HTIMI+1),hl
        ei

; ============================================================
;  main loop: la logica gira in display time, una volta a frame
;  (halt si sblocca all'interrupt); il lavoro VDP resta all'ISR
; ============================================================
main_loop:
        halt
        ld  a,(mode)
        or  a
        jr  z,.play
        cp  3
        jp  nz,end_sequence
        call landing_update ; approdo: l'ISR continua a disegnare
        jr  main_loop
.play:
        call update_wind
        call update_speeds
        call update_ship
        call update_weather
        call update_bolt
        call update_rock
        call update_gull
        call update_progress
        call update_timers
        jr  main_loop

; ------------------------------------------------------------
; arrivo (mode=1) o naufragio (mode=2): l'ISR e' fermo, il bordo
; e' nostro; lampeggio ~2.5s poi il viaggio ricomincia da capo
; ------------------------------------------------------------
end_sequence:
        ; silenzio: la risacca si spegne (l'ISR non tocca piu' il PSG)
        ld  a,8
        out (0A0h),a
        xor a
        out (0A1h),a
        ld  a,9
        out (0A0h),a
        xor a
        out (0A1h),a
        ld  a,10
        out (0A0h),a
        xor a
        out (0A1h),a
        ld  a,(frame_cnt)
        ld  b,a
.esloop:
        ld  a,(frame_cnt)
        sub b
        cp  150
        jr  nc,.esdone
        and 8
        jr  z,.esc2
        ld  a,(mode)
        dec a
        jr  z,.eswin1
        ld  a,08h           ; naufragio: rosso...
        jr  .esset
.eswin1:
        ld  a,0Fh           ; arrivo: bianco...
        jr  .esset
.esc2:
        ld  a,(mode)
        dec a
        jr  z,.eswin2
        ld  a,01h           ; ...e nero
        jr  .esset
.eswin2:
        ld  a,07h           ; ...e cyan
.esset:
        out (099h),a
        ld  a,80h|7
        out (099h),a
        halt
        jr  .esloop
.esdone:
        ; arrivo: se l'isola ha un episodio si SBARCA, altrimenti
        ; la ciurma superstite prosegue alla tratta dopo;
        ; naufragio: si ritenta la stessa tratta con 12 compagni
        ld  a,(mode)
        dec a
        jr  nz,.eslose
        ld  a,(crew)
        ld  (crew_keep),a
        ld  a,(leg)
        ld  l,a
        ld  h,0
        ld  bc,episode_tab
        add hl,bc
        ld  a,(hl)
        or  a
        jr  z,.noep
        ld  (phase),a       ; a terra! (leg resta: l'episodio e' suo)
        jp  init
.noep:
        ld  a,(leg)
        inc a
        cp  N_DESTS
        jr  c,.eslset
        xor a               ; viaggio completo: si torna al titolo
        ld  (leg),a
        ld  (leg_magic),a   ; magic invalidato -> title screen
        ld  a,CREW0
        ld  (crew_keep),a
        jp  init
.eslset:
        ld  (leg),a
        jp  init
.eslose:
        ld  a,CREW0
        ld  (crew_keep),a
        jp  init            ; nuova traversata (reinizializza tutto)

; ------------------------------------------------------------
; il ciclo del meteo: sereno <-> tempesta. Il cambio chiede il
; recolor del cielo all'ISR e in tempesta arma i fulmini
; ------------------------------------------------------------
update_weather:
        ld  hl,(wtimer_l)
        dec hl
        ld  (wtimer_l),hl
        ld  a,h
        or  l
        ret nz
        ld  a,(weather)
        xor 1
        ld  (weather),a
        jr  z,.tocalm
        ld  hl,(v_sto)
        ld  (wtimer_l),hl
        ld  a,1
        ld  (recolor),a
        ld  a,2
        ld  (flash_t),a     ; il cielo si spacca...
        ld  a,60
        ld  (thunder_t),a   ; ...e tuona a lungo
        xor a
        ld  (sfx_type),a
        ld  a,60
        ld  (bolt_timer),a
        ret
.tocalm:
        ld  hl,(v_ser)
        ld  (wtimer_l),hl
        ld  a,2
        ld  (recolor),a
        ret

; ------------------------------------------------------------
; fulmini (solo in tempesta): lampo di avviso, poi la scarica;
; meta' cadono vicino alla nave. Un colpo costa un compagno.
; ------------------------------------------------------------
update_bolt:
        ; PRIMA il fulmine attivo: si esaurisce sempre, anche se la
        ; tempesta e' appena finita (altrimenti resta congelato in
        ; cielo fino al maltempo successivo)
        ld  a,(bolt_t)
        or  a
        jr  nz,.active
        ld  a,(weather)
        or  a
        ret z
        ld  hl,bolt_timer
        dec (hl)
        ret nz
        ; nuovo fulmine: prossimo tra v_boltmin..+63 frame
        call rnd8
        and 63
        ld  hl,v_boltmin
        add a,(hl)
        ld  (bolt_timer),a
        call rnd8
        ld  b,a
        and 1
        jr  z,.try_near
.farx:
        ld  a,b             ; meta' a caso su tutto il mare
        and 0BFh            ; 0..191
        add a,16
        jr  .setx
.try_near:
        ; FAIRNESS: mai mirato sulla nave se uno scoglio le sta
        ; gia' limitando la manovra (niente tenaglie senza scampo)
        ld  a,(rock_t)
        or  a
        jr  nz,.farx
        ld  a,b             ; meta' addosso: ship_x - 24 .. +39
        and 63
        sub 24
        ld  b,a
        ld  a,(ship_xh)
        add a,b
        cp  16
        jr  nc,.clamphi
        ld  a,16
.clamphi:
        cp  209
        jr  c,.setx
        ld  a,208
.setx:
        ld  (bolt_x),a
        ; parte il PREAVVISO: il cielo si carica sul punto della
        ; scarica per BOLT_WARN frame (fairness: si puo' scappare)
        ld  a,BOLT_DUR+BOLT_WARN
        ld  (bolt_t),a
        ld  hl,bolt_cnt
        inc (hl)
        ret
.active:
        dec a
        ld  (bolt_t),a
        cp  BOLT_DUR
        jr  nz,.nostrike
        ; avviso scaduto: ORA il lampo e la scarica
        ld  a,2
        ld  (flash_t),a
        ld  a,50
        ld  (thunder_t),a
        xor a
        ld  (sfx_type),a
        ret
.nostrike:
        cp  BOLT_DUR-3      ; un solo frame di verifica del colpo
        ret nz
        ld  a,(iframes)
        or  a
        ret nz
        ; centro fulmine (punta) vs centro nave: |dx| < 14
        ld  a,(ship_xh)
        ld  b,a
        ld  a,(bolt_x)
        sub b
        sub 8               ; (bolt_x+8+... ) - (ship_x+16)
        jp  p,.abs
        neg
.abs:
        cp  14
        ret nc              ; mancata
        jp  ship_hit

; ------------------------------------------------------------
; lo scoglio del sereno: la schiuma avvisa, poi emerge e resta
; li' - va aggirato col timone, toccarlo costa un compagno
; ------------------------------------------------------------
update_rock:
        ld  a,(rock_t)
        or  a
        jr  nz,.active
        ld  a,(weather)     ; spawn solo col bel tempo
        or  a
        ret nz
        ld  hl,rock_timer
        dec (hl)
        ret nz
        call rnd8           ; prossimo tra v_rockmin..+127 frame
        and 127
        ld  hl,v_rockmin
        add a,(hl)
        ld  (rock_timer),a
        call rnd8           ; meta' a caso, meta' sulla rotta della nave
        ld  b,a
        and 1
        jr  z,.nearship
        ld  a,b
        and 0BFh
        add a,24
        jr  .setx
.nearship:
        ld  a,b
        and 63
        sub 24
        ld  b,a
        ld  a,(ship_xh)
        add a,b
        cp  24
        jr  nc,.clamphi
        ld  a,24
.clamphi:
        cp  201
        jr  c,.setx
        ld  a,200
.setx:
        ld  (rock_x),a
        ld  a,ROCK_TOTAL
        ld  (rock_t),a
        ld  hl,rock_cnt
        inc (hl)
        ret
.active:
        dec a
        ld  (rock_t),a
        cp  ROCK_T_FOAM
        jr  nz,.nosplash
        ; SPLASH: lo scoglio rompe l'acqua (sweep breve da
        ; brillante a scuro, tutt'altra cosa dal rombo del tuono)
        ld  a,16
        ld  (thunder_t),a
        ld  a,1
        ld  (sfx_type),a
        ld  a,(rock_t)
.nosplash:
        ; collide solo quando e' fuori dall'acqua (sink < t <= foam)
        cp  ROCK_T_SINK+1
        ret c
        cp  ROCK_T_FOAM+1
        ret nc
        ld  a,(iframes)
        or  a
        ret nz
        ld  a,(ship_xh)
        ld  b,a
        ld  a,(rock_x)
        sub b
        sub 8
        jp  p,.abs
        neg
.abs:
        cp  20
        ret nc
        jp  ship_hit

; ------------------------------------------------------------
; il gabbiano di buon auspicio: oltre meta' rotta, col sereno,
; attraversa il cielo da destra a sinistra salutando (2 beep).
; Innocuo: dice al giocatore che la terra si avvicina.
; ------------------------------------------------------------
update_gull:
        ld  a,(gull_t)
        or  a
        jr  nz,.fly
        ld  a,(weather)
        or  a
        ret nz
        ld  a,(bar_cur)
        cp  5
        ret c
        ld  hl,gull_timer
        dec (hl)
        ret nz
        call rnd8           ; il prossimo tra 150..277 frame
        and 127
        add a,150
        ld  (gull_timer),a
        ld  a,248           ; parte da destra; gull_t e' anche la X
        ld  (gull_t),a
        ld  a,24
        ld  (chirp_t),a
        ret
.fly:
        dec a
        ld  (gull_t),a
        ret

; ------------------------------------------------------------
; un colpo alla nave (fulmine o scoglio): un compagno in mare
; ------------------------------------------------------------
ship_hit:
        ld  a,IFRAMES
        ld  (iframes),a
        ld  a,12
        ld  (bcol_t),a
        ld  a,60
        ld  (thunder_t),a   ; schianto (rumore, canale A)
        xor a
        ld  (sfx_type),a
        ld  a,1
        ld  (hud_dirty),a
        call crew_lose
        ret nz
        ld  a,2             ; ciurma finita: naufragio
        ld  (mode),a
        ret

; ------------------------------------------------------------
; toglie un compagno... a meno che RENZO non vegli sulla nave.
; NZ = si prosegue, Z = ciurma finita. Vive nel kernel (banco 0,
; sempre mappato): la chiamano anche gli episodi.
; ------------------------------------------------------------
crew_lose:
        ld  a,(god_flag)
        cp  0A5h
        jr  nz,.real
        ld  a,(crew)        ; immortali: la ciurma non si tocca
        or  a
        ret
.real:
        ld  hl,crew
        dec (hl)
        ret

; ------------------------------------------------------------
; la rotta avanza alla velocita' del mare (= del vento): la
; tempesta e' rischio ma anche il modo piu' rapido di arrivare
; ------------------------------------------------------------
update_progress:
        ld  hl,(prog_l)
        ld  de,(spdA2_l)
        add hl,de
        ld  (prog_l),hl
        ld  a,(prog_h)
        adc a,0
        ld  (prog_h),a
        ld  hl,v_target     ; l'arrivo della tratta corrente
        cp  (hl)
        jr  c,.isl
        ld  a,3             ; terra! comincia l'APPRODO (cinematica)
        ld  (mode),a
        xor a
        ld  (bolt_t),a      ; niente piu' pericoli in rada
        ld  (rock_t),a
        ld  a,24
        ld  (chirp_t),a     ; il gabbiano saluta l'arrivo
        ret
.isl:
        ; quasi in porto: l'isola della tratta appare all'orizzonte
        ld  hl,v_islp
        cp  (hl)
        jr  c,.bar
        ld  b,a
        ld  a,(island_flag)
        or  a
        jr  nz,.noisl
        ld  a,1
        ld  (island_flag),a
        ld  a,24            ; "terra!": il richiamo del gabbiano
        ld  (chirp_t),a
.noisl:
        ld  a,b
.bar:
        ; tacche = prog*10 / v_target (a runtime: il target varia
        ; per tratta; divisione a sottrazioni, max 10 giri)
        ld  l,a
        ld  h,0
        ld  d,h
        ld  e,l
        add hl,hl
        add hl,hl
        add hl,de
        add hl,hl           ; HL = prog*10
        ld  a,(v_target)
        ld  e,a
        ld  d,0
        xor a
.bdiv:
        sbc hl,de
        jr  c,.bfin
        inc a
        jr  .bdiv
.bfin:
        cp  11
        jr  c,.bok
        ld  a,10
.bok:
        ld  hl,bar_cur
        cp  (hl)
        ret z
        ld  (hl),a
        ld  a,1
        ld  (hud_dirty),a
        ret

; ------------------------------------------------------------
; l'approdo: il vento si placa, la nave accosta verso l'isola
; all'orizzonte rimpicciolendo in lontananza; una pausa, e si
; passa alla sequenza di arrivo (mode=1 -> tratta successiva)
; ------------------------------------------------------------
landing_update:
        call update_timers
        call update_speeds  ; le bande rallentano col vento
        ld  a,(wind)
        cp  17
        jr  c,.wok
        dec a
        ld  (wind),a
.wok:
        ; la nave accosta verso x=196 (mezzo pixel a frame)
        ld  a,(ship_xh)
        cp  196
        jr  z,.xdone
        jr  c,.xright
        ld  hl,(ship_xl)
        ld  de,-128
        add hl,de
        ld  (ship_xl),hl
        jr  .ydo
.xright:
        ld  hl,(ship_xl)
        ld  de,128
        add hl,de
        ld  (ship_xl),hl
.xdone:
.ydo:
        ; e sale verso l'orizzonte: 1px ogni 4 frame
        ld  a,(frame_cnt)
        and 3
        jr  nz,.chk
        ld  a,(ship_y)
        cp  69
        jr  c,.chk
        dec a
        ld  (ship_y),a
.chk:
        ; approdo compiuto? (x a destinazione, sagoma all'orizzonte)
        ld  a,(ship_xh)
        cp  196
        ret nz
        ld  a,(ship_y)
        cp  69
        ret nc
        ld  hl,land_hold
        inc (hl)
        ld  a,(hl)
        cp  40
        ret c
        ld  a,1             ; sequenza di arrivo -> tratta dopo
        ld  (mode),a
        ret

update_timers:
        ld  hl,flash_t
        ld  a,(hl)
        or  a
        jr  z,.t1
        dec (hl)
.t1:
        ld  hl,bcol_t
        ld  a,(hl)
        or  a
        jr  z,.t2
        dec (hl)
.t2:
        ld  hl,iframes
        ld  a,(hl)
        or  a
        ret z
        dec (hl)
        ret

; LFSR a 8 bit (x^8+x^4+x^3+x^2+1): periodo 255, seed mai 0
rnd8:
        ld  a,(rndseed)
        add a,a
        jr  nc,.nox
        xor 1Dh
.nox:
        ld  (rndseed),a
        ret

; la difficolta' per tratta: target, fulmine-min, mostro-min,
; sereno/4, tempesta/4, isola-all'orizzonte. Piu' lontano da
; Troia = rotte piu' lunghe, cieli piu' neri, mari piu' pieni.
diff_tab:
        db  24,50,120,150,175,21    ; verso i Ciclopi
        db  28,44,104,135,185,25    ; verso Circe
        db  32,38, 92,120,195,29    ; verso Eolia
        db  36,32, 80,105,205,33    ; verso le Sirene
        db  40,27, 70, 90,215,37    ; verso Scilla e Cariddi
        db  44,22, 60, 75,225,41    ; verso Itaca

; ------------------------------------------------------------
; vento di Eolo: ogni GUST_LEN frame una nuova raffica-obiettivo
; dalla tabella; il vento corrente la insegue di 1 ogni 2 frame
; ------------------------------------------------------------
update_wind:
        ld  hl,gust_t
        dec (hl)
        jr  nz,.slew
        ld  (hl),GUST_LEN
        ; in tempesta Eolo non consulta la tabella: soffia e basta
        ld  a,(weather)
        or  a
        jr  z,.calmgust
        call rnd8
        and 31
        add a,64            ; 64..95: sempre forte
        ld  (wind_tgt),a
        jr  .slew
.calmgust:
        ld  a,(gust_idx)
        inc a
        and 15
        ld  (gust_idx),a
        ld  l,a
        ld  h,0
        ld  bc,gust_tab
        add hl,bc
        ld  a,(hl)
        ld  (wind_tgt),a
.slew:
        ld  a,(wind_div)
        xor 1
        ld  (wind_div),a
        ret nz              ; solo un frame su due
        ; confronto signed robusto in 16 bit (il delta puo' superare
        ; il range a 8 bit: -96..96 contro -96..96)
        ld  a,(wind)
        ld  l,a
        add a,a
        sbc a,a
        ld  h,a             ; HL = wind esteso di segno
        ld  a,(wind_tgt)
        ld  e,a
        add a,a
        sbc a,a
        ld  d,a             ; DE = obiettivo esteso di segno
        or  a
        sbc hl,de
        ld  a,h
        or  l
        ret z               ; gia' a bersaglio
        ld  a,(wind)
        bit 7,h
        jr  z,.dec
        inc a               ; wind < obiettivo
        ld  (wind),a
        ret
.dec:
        dec a
        ld  (wind),a
        ret

; ------------------------------------------------------------
; dal vento alle velocita' di scroll 8.8 (nessuna moltiplicazione:
; solo somme del vento esteso di segno)
;   A/A2: 1.00 + vento/128    B: 0.50 + vento/256    C: 0.33 + vento/512
; con vento -96..+96 restano tutte positive
; ------------------------------------------------------------
update_speeds:
        ld  a,(wind)
        ld  e,a
        add a,a
        sbc a,a
        ld  d,a             ; DE = vento esteso di segno
        ld  hl,0100h
        add hl,de
        add hl,de
        ld  (spdA2_l),hl
        ld  (spdA_l),hl
        ld  hl,0080h
        add hl,de
        ld  (spdB_l),hl
        sra d
        rr  e               ; vento/2
        ld  hl,0055h
        add hl,de
        ld  (spdC_l),hl
        ret

; ------------------------------------------------------------
; timone + fisica della nave (tutto 8.8):
;   vx += timone (stick sx/dx), vx += vento/16, vx -= vx/16 (attrito)
;   x += vx, clamp ai bordi (fermandosi)
; ------------------------------------------------------------
update_ship:
        call read_stick
        ld  hl,(ship_vxl)
        cp  2
        jr  c,.nodir        ; 0..1: niente est
        cp  5
        jr  nc,.trywest     ; 2..4 = est (destra)
        ld  de,RUDDER_ACC
        add hl,de
        jr  .nodir
.trywest:
        cp  6
        jr  c,.nodir
        cp  9
        jr  nc,.nodir       ; 6..8 = ovest (sinistra)
        ld  de,RUDDER_ACC
        or  a
        sbc hl,de
.nodir:
        ; spinta del vento
        ld  a,(wind)
        sra a
        sra a
        sra a
        sra a               ; vento/16: -6..+6
        ld  e,a
        add a,a
        sbc a,a
        ld  d,a
        add hl,de
        ; attrito: vx -= vx/16
        ld  d,h
        ld  e,l
        sra d
        rr  e
        sra d
        rr  e
        sra d
        rr  e
        sra d
        rr  e
        or  a
        sbc hl,de
        ld  (ship_vxl),hl
        ; x += vx
        ld  de,(ship_xl)
        add hl,de
        ; clamp ai bordi (16..208), azzerando la velocita'
        ld  a,h
        cp  16
        jr  c,.clampmin
        cp  208
        jr  nc,.clampmax
        ld  (ship_xl),hl
        ret
.clampmin:
        ld  hl,16*256
        jr  .stop
.clampmax:
        ld  hl,208*256
.stop:
        ld  (ship_xl),hl
        ld  hl,0
        ld  (ship_vxl),hl
        ret

; ------------------------------------------------------------
; read_stick: tastiera (cursori) O joystick 1 O joystick 2 -
; quello effettivamente in uso (convenzione GTSTCK di Sam.Pr)
; ------------------------------------------------------------
read_stick:
        xor a
        call GTSTCK
        or  a
        ret nz
        ld  a,1
        call GTSTCK
        or  a
        ret nz
        ld  a,2
        jp  GTSTCK

; ------------------------------------------------------------
; show_bitmap_dark: carica una bitmap SC2 da ROM (A = banco dei
; pattern, colori nel banco dopo) coi colori GIA' spenti (LUT3):
; lo schermo si accende nero, pronto per la dissolvenza in entrata.
; Gira PRIMA dell'hook di frame: halt col solo ISR del BIOS.
; ------------------------------------------------------------
show_bitmap_dark:
        push af
        di
        ld  b,10100010b     ; schermo spento durante il caricamento
        ld  c,1
        call WRTVDP
        di                  ; WRTVDP del BIOS puo' fare EI: i
                            ; caricamenti restano protetti
        ld  a,208           ; niente sprite sulla bitmap
        ld  de,VR_SPRA
        ld  bc,1
        call vdp_fill
        ; name table identita': bitmap pieno schermo (3 terzi)
        ld  de,VR_NAME
        call vdp_setwrt
        ld  c,3
.mnt:
        xor a
.mni:
        out (098h),a
        inc a
        jr  nz,.mni
        dec c
        jr  nz,.mnt
        pop af
        push af
        ld  (BANK2R),a
        ld  hl,08000h
        ld  de,VR_PAT
        ld  bc,1800h
        call vdp_copy
        ; colori attraverso la LUT piu' scura: schermo nero
        pop af
        inc a
        ld  (BANK2R),a
        ld  de,VR_COL
        call vdp_setwrt
        ld  de,08000h
        ld  h,high fade_lut3
        ld  c,24
.dcpg:
        ld  b,0
.dcbt:
        ld  a,(de)
        ld  l,a
        ld  a,(hl)
        out (098h),a
        inc de
        djnz .dcbt
        dec c
        jr  nz,.dcpg
        ld  a,2
        ld  (BANK2R),a
        ld  b,11100010b     ; schermo acceso (tutto nero)
        ld  c,1
        call WRTVDP
        ei
        ret

; ------------------------------------------------------------
; fade_pass: una passata di dissolvenza - riscrive i colori dello
; schermo leggendo dal banco ROM (A) e rimappando con la LUT
; (H = pagina). Spezzata in 6 rate da 1KB con halt: la musica
; continua a suonare durante la dissolvenza.
; ------------------------------------------------------------
fade_pass:                  ; A = banco colori ROM, H = pagina LUT
        ld  (BANK2R),a
        ld  b,h             ; B = pagina LUT (fissa per la passata)
        ld  de,08000h       ; DE = sorgente nel banco
        ld  c,6
.rate:
        halt
        push bc
        push de
        call music_tick
        pop de
        pop bc
        ; indirizzo VRAM = VR_COL + (DE - 8000h); il setwrt e' a due
        ; byte: sotto DI, che l'ISR del BIOS azzera il latch
        di
        ld  a,e
        out (099h),a
        ld  a,d
        sub 080h
        add a,high VR_COL
        or  40h
        out (099h),a
        ei
        push bc
        ld  h,b
        ld  b,4             ; 4 pagine da 256 byte per rata
.pg:
        push bc
        ld  b,0
.bt:
        ld  a,(de)
        ld  l,a
        ld  a,(hl)
        out (098h),a        ; ~54 T/byte: pacing sicuro
        inc de
        djnz .bt
        pop bc
        djnz .pg
        pop bc
        dec c
        jr  nz,.rate
        ld  a,2
        ld  (BANK2R),a
        ret

; dissolvenza in ENTRATA (da nero a colori pieni); A = banco colori
fade_in:
        push af
        ld  h,high fade_lut2
        call fade_pass
        pop af
        push af
        ld  h,high fade_lut1
        call fade_pass
        pop af
        ld  h,high fade_lut0    ; identita': colori pieni
        jp  fade_pass

; dissolvenza in USCITA (verso il nero); A = banco colori
fade_out:
        push af
        ld  h,high fade_lut1
        call fade_pass
        pop af
        push af
        ld  h,high fade_lut2
        call fade_pass
        pop af
        ld  h,high fade_lut3
        jp  fade_pass

; ------------------------------------------------------------
; il title screen: silhouette al tramonto + tema PSG a 3 canali,
; in dissolvenza; FIRE per passare alla pergamena
; ------------------------------------------------------------
title_show:
        xor a
        ld  (renzo_idx),a   ; il matcher RENZO parte pulito
        call music_title
        ld  a,TITLE_BANK
        call show_bitmap_dark
        ld  a,TITLE_BANK+1
        call fade_in
.wait:
        halt
        call music_tick
        call cheat_check    ; GOTO1..6: si salpa dritti alla tratta
        jr  nz,.go
        call renzo_check    ; RENZO: la ciurma diventa immortale
        call read_trig
        cp  0FFh
        jr  nz,.wait
.rel:                       ; il tema continua sull'anti-rimbalzo
        halt
        call music_tick
        call read_trig
        cp  0FFh
        jr  z,.rel
.go:
        ld  a,TITLE_BANK+1  ; dissolvenza in uscita, musica viva
        call fade_out
        jp  psg_mute        ; il gioco reimposta il suo PSG

; ------------------------------------------------------------
; cheat di collaudo: sul titolo, digitare GOTO seguito da una
; cifra 1..6 porta dritti a quella tratta - e al suo SBARCO se
; l'isola ha un episodio (GOTO1 = la caverna di Polifemo).
; Ritorna NZ quando la sequenza e' completa.
; ------------------------------------------------------------
cheat_check:
        ld  a,(cheat_idx)
        and 07h
        cp  4
        jr  z,.digit
        ; il prossimo tasto atteso della sequenza G,O,T,O
        add a,a
        ld  l,a
        ld  h,0
        ld  bc,cheat_tab
        add hl,bc
        ld  a,(hl)
        inc hl
        push hl
        call SNSMAT
        pop hl
        and (hl)
        jr  z,.hit          ; premuto (bit basso)
        ld  a,(cheat_idx)   ; rilasciato: riarma l'accettazione
        and 07h
        ld  (cheat_idx),a
        xor a
        ret
.hit:
        ld  a,(cheat_idx)
        bit 7,a
        jr  z,.accept
        xor a               ; ancora tenuto: gia' contato
        ret
.accept:
        inc a
        or  80h
        ld  (cheat_idx),a
        xor a
        ret
.digit:
        xor a
        call SNSMAT         ; riga 0: le cifre
        cpl                 ; 1 = premuto
        and 01111110b       ; solo 1..6
        ret z
        ld  c,0
.dg:
        srl a
        inc c
        jr  nc,.dg
        dec c               ; C = cifra 1..6
        ld  a,c
        dec a
        ld  (leg),a
        ld  l,a
        ld  h,0
        ld  bc,episode_tab
        add hl,bc
        ld  a,(hl)
        ld  (phase),a       ; sbarco diretto se c'e' l'episodio
        or  0FFh            ; NZ: scattato
        ret

; ------------------------------------------------------------
; RENZO sul titolo: la ciurma non si consuma mai. Stesso schema
; del matcher GOTO (tasto atteso, bit7 = gia' contato); al
; completamento suona la conferma e fissa god_flag.
; ------------------------------------------------------------
renzo_check:
        ld  a,(renzo_idx)
        and 07h
        cp  5
        ret z               ; gia' attivo: non si riattiva
        add a,a
        ld  l,a
        ld  h,0
        ld  bc,renzo_tab
        add hl,bc
        ld  a,(hl)
        inc hl
        push hl
        call SNSMAT
        pop hl
        and (hl)
        jr  z,.hit
        ld  a,(renzo_idx)   ; rilasciato: riarma l'accettazione
        and 07h
        ld  (renzo_idx),a
        ret
.hit:
        ld  a,(renzo_idx)
        bit 7,a
        ret nz              ; ancora tenuto: gia' contato
        inc a
        or  80h
        ld  (renzo_idx),a
        and 07h
        cp  5
        ret nz
        ; R-E-N-Z-O: la protezione veglia sulla ciurma
        ld  a,0A5h
        ld  (god_flag),a
        ld  a,5
        ld  (renzo_idx),a
        ; la conferma: tre note che salgono (la musica del titolo
        ; riprende da sola al tick successivo)
        ld  hl,renzo_notes
        ld  d,3
.n:
        ld  a,(hl)
        inc hl
        push hl
        push de
        ld  e,a
        xor a               ; tono A: la nota
        out (0A0h),a
        ld  a,e
        out (0A1h),a
        ld  a,1
        out (0A0h),a
        xor a
        out (0A1h),a
        ld  a,8
        out (0A0h),a
        ld  a,13
        out (0A1h),a
        ld  b,12
.w:
        halt
        djnz .w
        pop de
        pop hl
        dec d
        jr  nz,.n
        ld  a,8
        out (0A0h),a
        xor a
        out (0A1h),a
        ret
renzo_notes:
        db  170,127,85      ; MI5, LA5, MI6: la scala dell'immortale
; la sequenza: (riga, maschera) di R, E, N, Z, O
renzo_tab:
        db  4,80h
        db  3,04h
        db  4,08h
        db  5,80h
        db  4,10h

; la sequenza: (riga, maschera) di G, O, T, O
cheat_tab:
        db  3,10h
        db  4,10h
        db  5,02h
        db  4,10h

; ------------------------------------------------------------
; la pergamena del viaggio: rotta percorsa, tratta che inizia,
; tratte future, col tema della lira, in dissolvenza
; ------------------------------------------------------------
map_show:
        call music_map
        ld  a,(leg)
        add a,a
        add a,MAP_BANK0
        call show_bitmap_dark
        call map_colbank
        call fade_in
.wait:
        halt
        call music_tick
        call read_trig
        cp  0FFh
        jr  nz,.wait
.rel:                       ; anti-rimbalzo: aspetta il rilascio
        halt
        call music_tick
        call read_trig
        cp  0FFh
        jr  z,.rel
        call map_colbank
        call fade_out
        jp  psg_mute

map_colbank:                ; A = banco colori della pergamena
        ld  a,(leg)
        add a,a
        add a,MAP_BANK0+1
        ret

; FIRE da tastiera (SPACE) o joystick 1/2. Vale solo il valore
; "premuto" documentato 0FFh: una porta joystick scollegata non
; legge un pulito 0 (lezione di Sam.Pr)
read_trig:
        xor a
        call GTTRIG
        cp  0FFh
        ret z
        ld  a,1
        call GTTRIG
        cp  0FFh
        ret z
        ld  a,2
        jp  GTTRIG

; ------------------------------------------------------------
; musica del titolo: 3 stream (nota,durata in frame); nota 0 =
; pausa, 0FFh + dw = riavvolgi. Un tick a frame dal loop del
; titolo (nessun conflitto con l'ISR: l'hook non e' installato)
; ------------------------------------------------------------
music_title:
        ld  a,MUS_VA
        ld  (musVA),a
        ld  a,MUS_VB
        ld  (musVB),a
        ld  a,MUS_VC
        ld  (musVC),a
        ld  hl,song_title
        jr  music_start
music_map:
        ld  a,MAP_VA
        ld  (musVA),a
        ld  a,MAP_VB
        ld  (musVB),a
        ld  a,MAP_VC
        ld  (musVC),a
        ld  hl,song_map
music_start:                ; HL -> dw chA, dw chB, dw chC
        ld  e,(hl)
        inc hl
        ld  d,(hl)
        inc hl
        ld  (musA_p),de
        ld  e,(hl)
        inc hl
        ld  d,(hl)
        inc hl
        ld  (musB_p),de
        ld  e,(hl)
        inc hl
        ld  d,(hl)
        ld  (musC_p),de
        ld  a,1
        ld  (musA_c),a
        ld  (musB_c),a
        ld  (musC_c),a
        ld  a,7             ; mixer: 3 toni, niente rumore
        out (0A0h),a
        ld  a,10111000b
        out (0A1h),a
        ret

; ammutolisce i 3 canali (fine di titolo/pergamena)
psg_mute:
        ld  a,8
        out (0A0h),a
        xor a
        out (0A1h),a
        ld  a,9
        out (0A0h),a
        xor a
        out (0A1h),a
        ld  a,10
        out (0A0h),a
        xor a
        out (0A1h),a
        ret

music_tick:
        call mus_tickA
        call mus_tickB
        jp  mus_tickC

mus_tickA:
        ld  hl,musA_c
        dec (hl)
        ret nz
        ld  de,(musA_p)
.next:
        ld  a,(de)
        inc de
        cp  0FFh
        jr  nz,.note
        ld  a,(de)          ; riavvolgi: segue il dw dell'inizio
        inc de
        ld  l,a
        ld  a,(de)
        ld  d,a
        ld  e,l
        jr  .next
.note:
        or  a
        jr  nz,.tone
        ld  a,8             ; pausa: volume a zero
        out (0A0h),a
        xor a
        out (0A1h),a
        jr  .dur
.tone:
        dec a
        add a,a
        ld  l,a
        ld  h,0
        ld  bc,mus_notes
        add hl,bc
        xor a               ; R0/R1: periodo canale A
        out (0A0h),a
        ld  a,(hl)
        out (0A1h),a
        inc hl
        ld  a,1
        out (0A0h),a
        ld  a,(hl)
        out (0A1h),a
        ld  a,8
        out (0A0h),a
        ld  a,(musVA)
        out (0A1h),a
.dur:
        ld  a,(de)
        inc de
        ld  (musA_c),a
        ld  (musA_p),de
        ret

mus_tickB:
        ld  hl,musB_c
        dec (hl)
        ret nz
        ld  de,(musB_p)
.next:
        ld  a,(de)
        inc de
        cp  0FFh
        jr  nz,.note
        ld  a,(de)
        inc de
        ld  l,a
        ld  a,(de)
        ld  d,a
        ld  e,l
        jr  .next
.note:
        or  a
        jr  nz,.tone
        ld  a,9
        out (0A0h),a
        xor a
        out (0A1h),a
        jr  .dur
.tone:
        dec a
        add a,a
        ld  l,a
        ld  h,0
        ld  bc,mus_notes
        add hl,bc
        ld  a,2             ; R2/R3: periodo canale B
        out (0A0h),a
        ld  a,(hl)
        out (0A1h),a
        inc hl
        ld  a,3
        out (0A0h),a
        ld  a,(hl)
        out (0A1h),a
        ld  a,9
        out (0A0h),a
        ld  a,(musVB)
        out (0A1h),a
.dur:
        ld  a,(de)
        inc de
        ld  (musB_c),a
        ld  (musB_p),de
        ret

mus_tickC:
        ld  hl,musC_c
        dec (hl)
        ret nz
        ld  de,(musC_p)
.next:
        ld  a,(de)
        inc de
        cp  0FFh
        jr  nz,.note
        ld  a,(de)
        inc de
        ld  l,a
        ld  a,(de)
        ld  d,a
        ld  e,l
        jr  .next
.note:
        or  a
        jr  nz,.tone
        ld  a,10
        out (0A0h),a
        xor a
        out (0A1h),a
        jr  .dur
.tone:
        dec a
        add a,a
        ld  l,a
        ld  h,0
        ld  bc,mus_notes
        add hl,bc
        ld  a,4             ; R4/R5: periodo canale C
        out (0A0h),a
        ld  a,(hl)
        out (0A1h),a
        inc hl
        ld  a,5
        out (0A0h),a
        ld  a,(hl)
        out (0A1h),a
        ld  a,10
        out (0A0h),a
        ld  a,(musVC)
        out (0A1h),a
.dur:
        ld  a,(de)
        inc de
        ld  (musC_c),a
        ld  (musC_p),de
        ret

; quali isole hanno un episodio a terra (il valore = phase:
; 1 Polifemo, 2 Circe)
episode_tab:
        db  1,2,0,0,0,0

; le raffiche di Eolo: perlopiu' favorevoli (il viaggio procede),
; con bonacce e colpi contrari da governare col timone
gust_tab:
        db  48,80,96,60,20,-20,8,72
        db  96,50,-8,-48,24,88,40,-30

; ============================================================
;  ISR di frame: il blast parte QUI, all'inizio del vblank.
;  Il BIOS (KEYINT) ha gia' letto S#0 e salvato i registri
;  principali: usiamo solo A,BC,DE,HL.
; ============================================================
irq_hook:
        ; nelle sequenze di arrivo/naufragio l'ISR si ferma: il main
        ; loop resta padrone del bordo e il tempo scorre da frame_cnt.
        ; Durante l'APPRODO (mode=3) invece continua tutto: bande,
        ; nave, risacca - e' una cinematica sul motore vivo.
        ld  a,(mode)
        or  a
        jr  z,.play
        cp  3
        jr  z,.play
        ld  hl,frame_cnt
        inc (hl)
        ret
.play:
        ld  a,GAUGEC        ; gauge acceso: bordo bianco
        out (099h),a
        ld  a,80h|7
        out (099h),a
gauge_on:                   ; label per test/measure.tcl
        ; --- bande: accumulo 8.8; a passo compiuto (>=1px) si
        ;     avanza l'offset e si riscrive la banda. Il costo del
        ;     blast NON dipende dal passo: anche 2px = una passata ---
        ld  hl,fracA2
        ld  a,(spdA2_l)
        add a,(hl)
        ld  (hl),a
        ld  a,(spdA2_h)
        adc a,0
        jr  z,.skA2
        ld  b,a
        ld  a,(cntA2)
        add a,b
        and WAVES_A2_W*8-1
        ld  (cntA2),a
        call blastA2
.skA2:
        ld  hl,fracA
        ld  a,(spdA_l)
        add a,(hl)
        ld  (hl),a
        ld  a,(spdA_h)
        adc a,0
        jr  z,.skA
        ld  b,a
        ld  a,(cntA)
        add a,b
        and WAVES_A_W*8-1
        ld  (cntA),a
        call blastA
.skA:
        ld  hl,fracB
        ld  a,(spdB_l)
        add a,(hl)
        ld  (hl),a
        ld  a,(spdB_h)
        adc a,0
        jr  z,.skB
        ld  b,a
        ld  a,(cntB)
        add a,b
        and WAVES_B_W*8-1
        ld  (cntB),a
        call blastB
.skB:
        ld  hl,fracC
        ld  a,(spdC_l)
        add a,(hl)
        ld  (hl),a
        ld  a,(spdC_h)
        adc a,0
        jr  z,.skC
        ld  b,a
        ld  a,(cntC)
        add a,b
        and WAVES_C_W*8-1
        ld  (cntC),a
        call blastC
.skC:
        ; --- recolor del meteo (evento raro: cambio cielo) ---
        ld  a,(recolor)
        or  a
        jr  z,.norec
        cp  1
        jr  nz,.reclr
        ld  hl,sky_col_storm
        ld  de,haze_col_storm
        ld  bc,wavesC_colx_storm
        jr  .dorec
.reclr:
        ld  hl,sky_col
        ld  de,haze_col
        ld  bc,wavesC_colx
.dorec:
        push bc
        push de
        ; 128 byte: colori del terzo 0 (cielo/testo/sole/HUD)
        ld  a,low VR_COL
        out (099h),a
        ld  a,(high VR_COL)|40h
        out (099h),a
        ld  b,128
        call blast_bytes
        ; 16 byte: foschia
        pop hl
        ld  a,low (VR_COL+0800h+HAZE_T0*8)
        out (099h),a
        ld  a,(high (VR_COL+0800h+HAZE_T0*8))|40h
        out (099h),a
        ld  b,16
        call blast_bytes
        ; 32 byte: banda C (orizzonte)
        pop hl
        ld  a,low (VR_COL+0800h+TBASE_C*8)
        out (099h),a
        ld  a,(high (VR_COL+0800h+TBASE_C*8))|40h
        out (099h),a
        ld  b,WAVES_C_W*8
        call blast_bytes
        ; se Itaca e' gia' in vista, anche lei cambia luce
        ld  a,(island_flag)
        cp  2
        jr  nz,.recdone
        ld  a,(recolor)
        cp  1
        ld  hl,island_col_storm
        jr  z,.recisl
        ld  hl,island_col
.recisl:
        ld  a,low (VR_COL+0800h+ISL_T0*8)
        out (099h),a
        ld  a,(high (VR_COL+0800h+ISL_T0*8))|40h
        out (099h),a
        ld  b,64
        call blast_bytes
.recdone:
        xor a
        ld  (recolor),a
.norec:
        ; --- Itaca appare all'orizzonte (una volta, su richiesta
        ;     del main quando la rotta e' quasi compiuta) ---
        ld  a,(island_flag)
        cp  1
        jr  nz,.noisl
        ld  a,2
        ld  (island_flag),a
        ld  hl,island_pat
        ld  a,low (VR_PAT+0800h+ISL_T0*8)
        out (099h),a
        ld  a,(high (VR_PAT+0800h+ISL_T0*8))|40h
        out (099h),a
        ld  b,64
        call blast_bytes
        ld  a,(weather)
        or  a
        ld  hl,island_col
        jr  z,.islc
        ld  hl,island_col_storm
.islc:
        ld  a,low (VR_COL+0800h+ISL_T0*8)
        out (099h),a
        ld  a,(high (VR_COL+0800h+ISL_T0*8))|40h
        out (099h),a
        ld  b,64
        call blast_bytes
        ld  a,low (VR_NAME+10*32+26)
        out (099h),a
        ld  a,(high (VR_NAME+10*32+26))|40h
        out (099h),a
        ld  a,ISL_T0
        out (098h),a
        inc a
        out (098h),a
        inc a
        out (098h),a
        inc a
        out (098h),a
        ld  a,low (VR_NAME+11*32+26)
        out (099h),a
        ld  a,(high (VR_NAME+11*32+26))|40h
        out (099h),a
        ld  a,ISL_T0+4
        out (098h),a
        inc a
        out (098h),a
        inc a
        out (098h),a
        inc a
        out (098h),a
.noisl:
        ; --- HUD (riga 0): solo quando cambia qualcosa ---
        ld  a,(hud_dirty)
        or  a
        jr  z,.nohud
        xor a
        ld  (hud_dirty),a
        ld  a,low (VR_NAME+CREW_COL)
        out (099h),a
        ld  a,(high (VR_NAME+CREW_COL))|40h
        out (099h),a
        ld  a,(crew)
        ld  d,a
        ld  e,12
.hcrew:
        ld  a,d
        or  a
        jr  z,.hslot0
        dec d
        ld  a,HUD_MAN
        jr  .hout1
.hslot0:
        xor a
.hout1:
        out (098h),a
        dec e
        jr  nz,.hcrew
        ld  a,low (VR_NAME+BAR_COL)
        out (099h),a
        ld  a,(high (VR_NAME+BAR_COL))|40h
        out (099h),a
        ld  a,(bar_cur)
        ld  d,a
        ld  e,10
.hbar:
        ld  a,d
        or  a
        jr  z,.hdot
        dec d
        ld  a,HUD_FILL
        jr  .hout2
.hdot:
        ld  a,HUD_DOT
.hout2:
        out (098h),a
        dec e
        jr  nz,.hbar
.nohud:
        ; --- nave + fulmine: OAM riscritto ogni frame ---
        ld  a,low VR_SPRA
        out (099h),a
        ld  a,(high VR_SPRA)|40h
        out (099h),a
        ; sprite 0-2: il fulmine (nascosto a Y=209 quando non attivo);
        ; e' PRIMA della nave: priorita' alta, e sulle linee dove
        ; supera il limite di 4/linea a sparire e' la vela dx - un
        ; flicker accettabile, solo nei frame del lampo
        ld  a,(bolt_t)
        or  a
        jr  z,.bhid
        cp  BOLT_DUR+1
        jr  c,.bfull
        ; PREAVVISO: bagliore intermittente nel punto della scarica
        ld  a,(frame_cnt)
        and 2
        jr  nz,.bwoff
        ld  a,43
        out (098h),a
        ld  a,(bolt_x)
        out (098h),a
        ld  a,BOLT_PAT
        out (098h),a
        ld  a,11            ; giallo: il cielo si carica
        out (098h),a
        ld  e,2
        jp  .bhl
.bwoff:
        jp  .bhid
.bfull:
        ld  a,(bolt_x)
        ld  e,a
        ld  a,(frame_cnt)
        and 1
        ld  c,15            ; bianco/giallo alternati: guizza
        jr  z,.bcol
        ld  c,11
.bcol:
        ld  a,43
        out (098h),a
        ld  a,e
        out (098h),a
        ld  a,BOLT_PAT
        out (098h),a
        ld  a,c
        out (098h),a
        ld  a,59
        out (098h),a
        ld  a,e
        add a,3
        out (098h),a
        ld  a,BOLT_PAT
        out (098h),a
        ld  a,c
        out (098h),a
        ld  a,75
        out (098h),a
        ld  a,e
        sub 2
        out (098h),a
        ld  a,BOLT_PAT
        out (098h),a
        ld  a,c
        out (098h),a
        jp  .oam_ship
.bhid:
        ; niente fulmine: negli slot 0-1 puo' esserci il mostro
        ld  a,(rock_t)
        or  a
        jr  z,.rknone
        cp  ROCK_T_GONE+1
        jr  c,.rknone       ; coda: gia' sparito
        cp  ROCK_T_FOAM+1
        jr  nc,.rkfoam
        cp  ROCK_T_RISE+1
        jr  nc,.rkrise
        cp  ROCK_T_SINK+1
        jr  nc,.rkhold
        ; 21..40: affonda (y scende con t)
        ld  b,a
        ld  a,ROCK_T_SINK+1
        sub b               ; 1..20
        add a,93
        jr  .rkdraw
.rkrise:
        ; 181..200: emerge dall'acqua
        sub ROCK_T_RISE     ; 1..20
        add a,93
        jr  .rkdraw
.rkhold:
        ld  a,94
        jr  .rkdraw
.rkfoam:
        ; schiuma che ribolle: sfarfalla, 2 frame si' e 2 no
        ld  a,(frame_cnt)
        and 2
        jr  nz,.rknone
        ld  a,99
        out (098h),a
        ld  a,(rock_x)
        out (098h),a
        ld  a,FOAM_PAT
        out (098h),a
        ld  a,15
        out (098h),a
        ld  e,2
        jr  .bhl
.rkdraw:                    ; A = attributo Y del MOSTRO (base)
        ld  d,a
        sub 16              ; la testa ondeggia sopra il collo
        out (098h),a
        ld  a,(rock_x)
        out (098h),a
        ld  a,(frame_cnt)
        and 8
        jr  z,.rkh1
        ld  a,SERP_HEAD2
        jr  .rkh2
.rkh1:
        ld  a,SERP_HEAD1
.rkh2:
        out (098h),a
        ld  a,13            ; magenta d'abisso
        out (098h),a
        ld  a,d
        out (098h),a        ; il collo
        ld  a,(rock_x)
        out (098h),a
        ld  a,ROCK_PAT
        out (098h),a
        ld  a,13
        out (098h),a
        ld  e,1             ; l'ultimo slot fulmine: nascosto
        jr  .bhl
.rknone:
        ld  e,3
.bhl:
        ld  a,209           ; sotto lo schermo (208 = terminatore!)
        out (098h),a
        xor a
        out (098h),a
        ld  a,BOLT_PAT
        out (098h),a
        xor a
        out (098h),a
        dec e
        jr  nz,.bhl
.oam_ship:
        ld  a,(frame_cnt)
        rrca
        rrca
        rrca                ; indice di beccheggio: avanza ogni 8 frame
        and 15
        ld  l,a
        ld  h,0
        ld  bc,ship_bob
        add hl,bc
        ld  a,(hl)
        ld  hl,ship_y       ; Y variabile: sale durante l'approdo
        add a,(hl)
        ld  d,a             ; Y comune ai 4 sprite
        ; colpita di recente: lampeggia (sparisce un frame su due)
        ld  a,(iframes)
        or  a
        jr  z,.noblink
        ld  a,(frame_cnt)
        and 2
        jr  z,.noblink
        ld  d,209
.noblink:
        ld  a,(ship_xh)
        ld  e,a             ; X dalla fisica del timone
        ; approdo: quando la nave e' vicina all'orizzonte diventa
        ; una sagoma lontana (un solo sprite piccolo)
        ld  a,(ship_y)
        cp  75
        jr  nc,.bigship
        ld  a,d
        out (098h),a
        ld  a,e
        add a,8
        out (098h),a
        ld  a,36            ; pattern nave lontana
        out (098h),a
        ld  a,SHIP_C_HULL
        out (098h),a
        ld  e,3
.shl:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        xor a
        out (098h),a
        xor a
        out (098h),a
        dec e
        jr  nz,.shl
        jp  .aftership
.bigship:
        ld  a,d
        out (098h),a        ; sprite 0: scafo sx
        ld  a,e
        out (098h),a
        xor a
        out (098h),a        ; pattern 0
        ld  a,SHIP_C_HULL
        out (098h),a
        ld  a,d
        out (098h),a        ; sprite 1: scafo dx
        ld  a,e
        add a,16
        out (098h),a
        ld  a,4
        out (098h),a
        ld  a,SHIP_C_HULL
        out (098h),a
        ld  a,d
        out (098h),a        ; sprite 2: vela sx
        ld  a,e
        out (098h),a
        ld  a,8
        out (098h),a
        ld  a,SHIP_C_SAIL
        out (098h),a
        ld  a,d
        out (098h),a        ; sprite 3: vela dx
        ld  a,e
        add a,16
        out (098h),a
        ld  a,12
        out (098h),a
        ld  a,SHIP_C_SAIL
        out (098h),a
.aftership:
        ; sprite 7: il gabbiano (le sue linee non toccano ne' nave
        ; ne' fulmine: mai piu' di 4 sprite per linea con lui)
        ld  a,(gull_t)
        or  a
        jr  z,.ghid
        ld  a,(frame_cnt)
        rrca
        rrca
        and 15
        ld  l,a
        ld  h,0
        ld  bc,ship_bob
        add hl,bc
        ld  a,(hl)          ; plana sulla stessa onda della nave
        add a,47
        out (098h),a
        ld  a,(gull_t)
        out (098h),a        ; X = il countdown: da destra a sinistra
        ld  a,(frame_cnt)
        and 8
        jr  z,.gw1
        ld  a,GULL_PAT+4
        jr  .gw2
.gw1:
        ld  a,GULL_PAT
.gw2:
        out (098h),a
        ld  a,15
        out (098h),a
        jr  .gterm
.ghid:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        ld  a,GULL_PAT
        out (098h),a
        xor a
        out (098h),a
.gterm:
        ld  a,208           ; terminatore: nessun altro sprite
        out (098h),a
        ; --- risacca PSG: due swell sfasati sui canali B e C ---
        ld  hl,sw_db
        dec (hl)
        jr  nz,.swb_done
        ld  (hl),8          ; canale B: un passo ogni 8 frame
        ld  a,(sw_ib)
        inc a
        and 31
        ld  (sw_ib),a
        ld  l,a
        ld  h,0
        ld  bc,swell_tab
        add hl,bc
        ld  a,9             ; volume canale B
        out (0A0h),a
        ld  a,(hl)
        out (0A1h),a
.swb_done:
        ld  hl,sw_dc
        dec (hl)
        jr  nz,.swc_done
        ld  (hl),6          ; canale C: ogni 6 frame (interferenza)
        ld  a,(sw_ic)
        inc a
        and 31
        ld  (sw_ic),a
        add a,9             ; sfasato di ~1/3 di ciclo
        and 31
        ld  l,a
        ld  h,0
        ld  bc,swell_tab
        add hl,bc
        ld  a,10            ; volume canale C
        out (0A0h),a
        ld  a,(hl)
        out (0A1h),a
        ; il colore del rumore respira col volume: onda che si gonfia
        ; (ma durante il tuono R6 appartiene al tuono)
        ld  a,(thunder_t)
        or  a
        jr  nz,.swc_done
        ld  a,6
        out (0A0h),a
        ld  a,(hl)
        srl a
        add a,12            ; periodo 12..17: rumore basso, da mare
        out (0A1h),a
.swc_done:
        ; --- effetti sul canale A, con inviluppi veri.
        ;     DUCKING: la risacca (B/C) va in sordina per tutta la
        ;     durata (il generatore di rumore dell'AY e' UNO solo,
        ;     condiviso: quando R6 cambia, cambia per tutti; gli
        ;     swell la riprendono da soli a effetto finito).
        ;     Tuono  = SCHIOCCO brillante (8 frame a vol 15) poi
        ;              rombo cupo che ondeggia e sfuma col tremolo.
        ;     Splash = sweep rapido da brillante a scuro. ---
        ld  a,(thunder_t)
        or  a
        jp  z,.nothun
        dec a
        ld  (thunder_t),a
        ld  a,9             ; risacca in sordina su B e C
        out (0A0h),a
        ld  a,2
        out (0A1h),a
        ld  a,10
        out (0A0h),a
        ld  a,2
        out (0A1h),a
        ld  a,(sfx_type)
        or  a
        jr  nz,.sfx_splash
        ; TUONO: prima lo schiocco...
        ld  a,(thunder_t)
        cp  52
        jr  c,.rumble
        ld  b,15            ; volume pieno
        ld  c,6             ; rumore brillante: lo SCHIOCCO
        jr  .sfxout
.rumble:
        ; ...poi il rombo: colore che ondeggia, volume che sfuma
        ld  a,(thunder_t)
        srl a
        and 3
        add a,26            ; R6 = 26..29 che ondeggia
        ld  c,a
        ld  a,(thunder_t)
        srl a
        srl a
        srl a               ; t/8: 0..6
        add a,7             ; volume 7..13 che decade lentamente
        ld  b,a
        ld  a,(frame_cnt)
        and 1
        jr  z,.sfxout
        dec b               ; tremolo
        jr  .sfxout
.sfx_splash:
        ; SPLASH: volume giu' veloce, colore da brillante a scuro
        ld  a,(thunder_t)
        ld  b,a             ; volume 15 -> 0 in 16 frame
        ld  a,16
        sub b
        ld  c,a             ; R6 = 1 -> 16 (sweep verso il cupo)
.sfxout:
        ld  a,8
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        ld  a,6
        out (0A0h),a
        ld  a,c
        out (0A1h),a
        xor a               ; tono A ultrasonico: solo rumore
        out (0A0h),a
        ld  a,1
        out (0A1h),a
.nothun:
        ; --- il richiamo del gabbiano: 2 beep sul tono A (mai
        ;     sopra il tuono, che ha la precedenza sul canale) ---
        ld  a,(thunder_t)
        or  a
        jp  nz,.nofizz      ; tuono in corso: niente altro sul canale
        ld  a,(chirp_t)
        or  a
        jr  z,.nochirp
        dec a
        ld  (chirp_t),a
        ld  b,0
        bit 3,a             ; on 8 frame, off 8, on 8: due beep
        jr  z,.cvol
        ld  b,9
.cvol:
        ld  a,8
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        xor a
        out (0A0h),a
        ld  a,100           ; ~2.2kHz: stridulo giusto
        out (0A1h),a
        ld  a,1
        out (0A0h),a
        xor a
        out (0A1h),a
        jr  .nofizz         ; il richiamo occupa il canale
.nochirp:
        ; --- il ribollio della schiuma: finche' lo scoglio sta per
        ;     emergere, il canale A sfrigola a basso volume ---
        ld  a,(rock_t)
        cp  ROCK_T_FOAM+1
        jr  c,.fizzoff
        ld  a,6
        out (0A0h),a
        ld  a,3             ; rumore acido, da bollicine
        out (0A1h),a
        xor a
        out (0A0h),a
        ld  a,1             ; tono ultrasonico: solo rumore
        out (0A1h),a
        ld  a,(frame_cnt)
        and 3
        srl a
        add a,4             ; volume 4-5 che sfrigola
        ld  b,a
        ld  a,8
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        jr  .nofizz
.fizzoff:
        ; canale A libero e muto
        ld  a,8
        out (0A0h),a
        xor a
        out (0A1h),a
.nofizz:
    IF BURN_CHUNKS > 0
        ; scritture extra verso l'area sprite libera (dopo i pattern
        ; della nave) per sondare il limite: ogni chunk = 256 byte
        ld  a,low (VR_SPRP+1C0h)
        out (099h),a
        ld  a,(high (VR_SPRP+1C0h))|40h
        out (099h),a
        ld  hl,04000h       ; sorgente qualunque (ROM)
        ld  e,BURN_CHUNKS
.burn:
        ld  b,0             ; 0 = 256 byte
        call blast_bytes
        dec e
        jr  nz,.burn
    ENDIF
gauge_off:                  ; label per test/measure.tcl
        ; bordo a riposo: bianco nel lampo del fulmine, rosso dopo un
        ; colpo, altrimenti nero
        ld  a,(flash_t)
        or  a
        jr  z,.b1
        ld  a,0Fh
        jr  .bset
.b1:
        ld  a,(bcol_t)
        or  a
        jr  z,.b2
        ld  a,08h
        jr  .bset
.b2:
        ld  a,BORDERC
.bset:
        out (099h),a
        ld  a,80h|7
        out (099h),a
        ld  hl,frame_cnt
        inc (hl)
        ret

; ------------------------------------------------------------
; blast di una banda. offset = k*8+s: il tile t mostra
; preshift_s[(t+k) mod W], quindi due run OUTI contigue sulla
; stessa destinazione VRAM: da k*8 a fine texture, poi da 0.
; ------------------------------------------------------------
blastA:
        ld  a,low WAVES_A_VPAT
        out (099h),a
        ld  a,(high WAVES_A_VPAT)|40h
        out (099h),a
        ld  a,(cntA)        ; l'avanzamento lo fa il chiamante
        ld  e,a
        and 7               ; s
        add a,a
        ld  l,a
        ld  h,0
        ld  bc,wavesA_pst
        add hl,bc
        ld  a,(hl)
        inc hl
        ld  h,(hl)
        ld  l,a             ; HL = base preshift s
        ld  a,e
        and 0F8h
        ld  d,a             ; D = k*8
        ld  a,low(WAVES_A_W*8)
        sub d
        ld  b,a             ; B = byte della prima run
        jp  blast_runs

blastA2:
        ld  a,low WAVES_A2_VPAT
        out (099h),a
        ld  a,(high WAVES_A2_VPAT)|40h
        out (099h),a
        ld  a,(cntA2)
        ld  e,a
        and 7
        add a,a
        ld  l,a
        ld  h,0
        ld  bc,wavesA2_pst
        add hl,bc
        ld  a,(hl)
        inc hl
        ld  h,(hl)
        ld  l,a
        ld  a,e
        and 0F8h
        ld  d,a
        ld  a,low(WAVES_A2_W*8)
        sub d
        ld  b,a
        jp  blast_runs

blastB:
        ld  a,low WAVES_B_VPAT
        out (099h),a
        ld  a,(high WAVES_B_VPAT)|40h
        out (099h),a
        ld  a,(cntB)
        ld  e,a
        and 7
        add a,a
        ld  l,a
        ld  h,0
        ld  bc,wavesB_pst
        add hl,bc
        ld  a,(hl)
        inc hl
        ld  h,(hl)
        ld  l,a
        ld  a,e
        and 0F8h
        ld  d,a
        ld  a,low(WAVES_B_W*8)
        sub d
        ld  b,a
        jp  blast_runs

blastC:
        ld  a,low WAVES_C_VPAT
        out (099h),a
        ld  a,(high WAVES_C_VPAT)|40h
        out (099h),a
        ld  a,(cntC)
        ld  e,a
        and 7
        add a,a
        ld  l,a
        ld  h,0
        ld  bc,wavesC_pst
        add hl,bc
        ld  a,(hl)
        inc hl
        ld  h,(hl)
        ld  l,a
        ld  a,e
        and 0F8h
        ld  d,a
        ld  a,low(WAVES_C_W*8)
        sub d
        ld  b,a
        jp  blast_runs

; blast_runs: HL=base preshift, D=k*8, B=byte run 1 (0 = 256)
blast_runs:
        push hl
        push de
        ld  a,l             ; HL += k*8 (senza toccare B)
        add a,d
        ld  l,a
        jr  nc,.nc
        inc h
.nc:
        call blast_bytes
        pop de
        pop hl
        ld  a,d
        or  a
        ret z               ; k=0: niente seconda run
        ld  b,d
        jp  blast_bytes

; blast_bytes: HL=sorgente, B=byte (multiplo di 8; 0 = 256)
; 8 OUTI srotolate + JP: ~19.4 T/byte, sicure solo nel blank
blast_bytes:
        ld  c,098h
.lp:
        outi
        outi
        outi
        outi
        outi
        outi
        outi
        outi
        jp  nz,.lp
        ret

; risacca: sinusoide 0..10 a 32 passi (volumi PSG dei due swell)
swell_tab:
        db  5,6,7,8,9,9,10,10,10,10,9,9,8,7,6,5
        db  5,4,3,2,1,1,0,0,0,0,1,1,2,3,4,5

; ============================================================
;  routine VDP di init (pacing >=29T: sicure anche a schermo
;  acceso; FILVRM del BIOS e' buggato su MSX1, mai usarlo)
; ============================================================

; vdp_setwrt: DE = indirizzo VRAM in scrittura
vdp_setwrt:
        ld  a,e
        out (099h),a
        ld  a,d
        or  40h
        out (099h),a
        ret

; vdp_fill: A=valore, DE=indirizzo, BC=contatore
vdp_fill:
        ld  l,a
        call vdp_setwrt
.f:
        ld  a,l
        out (098h),a
        dec bc
        ld  a,b
        or  c
        jp  nz,.f
        ret

; vdp_copy: HL=sorgente, DE=indirizzo VRAM, BC=contatore
vdp_copy:
        call vdp_setwrt
.c:
        ld  a,(hl)
        out (098h),a
        inc hl
        dec bc
        ld  a,b
        or  c
        jp  nz,.c
        ret

; fill_rows: DE=vaddr prima riga, B=righe, C=tile base,
;            L=maschera colonna (W-1); riempie righe intere
fill_rows:
.row:
        push bc
        call vdp_setwrt
        ld  h,0
        ld  b,32
.col:
        ld  a,h
        and l
        add a,c
        out (098h),a
        inc h
        djnz .col
        pop bc
        ld  a,e
        add a,32
        ld  e,a
        jr  nc,.nc
        inc d
.nc:
        djnz .row
        ret

; fill_colors: DE=vaddr colori, B=tile, HL=8 byte rowcol
;              replica gli stessi 8 byte su tutti i tile della banda
fill_colors:
        call vdp_setwrt
.t:
        push hl
        push bc
        ld  b,8
.b:
        ld  a,(hl)
        out (098h),a
        inc hl
        djnz .b
        pop bc
        pop hl
        djnz .t
        ret

; LUT di dissolvenza (allineate a 256 byte)
        INCLUDE "fade_data.asm"

; --- fine banco 0: se trabocca sjasmplus fallisce qui con
;     "Negative BLOCK?" (la guardia anti-overflow di Sam.Pr)
        DS  06000h-$,0FFh

; ============================================================
;  BANCO 1 (pagina 6000h): dati del mare generati
; ============================================================
        INCLUDE "waves_data.asm"
        INCLUDE "ship_data.asm"
        INCLUDE "sky_data.asm"
        INCLUDE "music_data.asm"
        DS  08000h-$,0FFh

; ============================================================
;  BANCO 2 (pagina 8000h): l'episodio di Polifemo (engine)
;  (episode.asm contiene ORG 8000h e la guardia di fine banco)
; ============================================================
        INCLUDE "episode.asm"

; ============================================================
;  BANCO 3 (pagina A000h): dati dell'episodio (tileset, stanze,
;  il ciclope, sprite) generati da gen_cave.py
; ============================================================
        ORG 0A000h
        INCLUDE "cave_data.asm"
        DS  0C000h-$,0FFh

; ============================================================
;  BANCO 4: firma del self-test mapper (visibile a 8000h quando
;  selezionato su BANK2R) + asset futuri
; ============================================================
        ORG 08000h
        db  "N4"
        db  "NESSUNO-BANK4-ASSET-FUTURI"
        DS  0A000h-$,0FFh

; ---- banco 5: riserva ----
        ORG 08000h
        db  "ODYSSEY-BANK5"
        DS  0A000h-$,0FFh

; ============================================================
;  BANCHI 6-7: l'episodio di CIRCE (modulo autonomo: codice a
;  8000h nel banco 6, dati da gen_circe.py a A000h nel banco 7;
;  il kernel li mappa su BANK2R/BANK3R quando phase=2)
; ============================================================
        MODULE circe
        ORG 08000h
        INCLUDE "circe.asm"
        DS  0A000h-$,0FFh
        ORG 0A000h
        INCLUDE "circe_data.asm"
        DS  0C000h-$,0FFh
        ENDMODULE

; ============================================================
;  BANCHI 8-19: le pergamene del viaggio (bitmap SC2 generate
;  da gen_map.py; tratta k: banco 8+2k pattern, 9+2k colori,
;  6KB usati su 8 per banco)
; ============================================================
        ORG 08000h
        INCBIN "map0_pat.bin"
        DS  0A000h-$,0FFh
        ORG 08000h
        INCBIN "map0_col.bin"
        DS  0A000h-$,0FFh
        ORG 08000h
        INCBIN "map1_pat.bin"
        DS  0A000h-$,0FFh
        ORG 08000h
        INCBIN "map1_col.bin"
        DS  0A000h-$,0FFh
        ORG 08000h
        INCBIN "map2_pat.bin"
        DS  0A000h-$,0FFh
        ORG 08000h
        INCBIN "map2_col.bin"
        DS  0A000h-$,0FFh
        ORG 08000h
        INCBIN "map3_pat.bin"
        DS  0A000h-$,0FFh
        ORG 08000h
        INCBIN "map3_col.bin"
        DS  0A000h-$,0FFh
        ORG 08000h
        INCBIN "map4_pat.bin"
        DS  0A000h-$,0FFh
        ORG 08000h
        INCBIN "map4_col.bin"
        DS  0A000h-$,0FFh
        ORG 08000h
        INCBIN "map5_pat.bin"
        DS  0A000h-$,0FFh
        ORG 08000h
        INCBIN "map5_col.bin"
        DS  0A000h-$,0FFh

; ============================================================
;  BANCHI 20-21: il title screen (bitmap SC2 da gen_title.py)
; ============================================================
        ORG 08000h
        INCBIN "title_pat.bin"
        DS  0A000h-$,0FFh
        ORG 08000h
        INCBIN "title_col.bin"
        DS  0A000h-$,0FFh

; ---- banchi 22-31: riserva (ROM totale 256KB) ----
        DUP 10
        ORG 08000h
        DS  02000h,0FFh
        EDUP
