; ============================================================
;  BANCO 2 - L'EPISODIO DI POLIFEMO
;  Platform flip-screen + stealth a RUMORE: il ciclope e' cieco
;  e ti ascolta. Camminare e' quasi silenzioso; saltare - e
;  soprattutto atterrare da una caduta - genera rumore. Oltre la
;  prima soglia l'occhio si apre; oltre la seconda la sua mano
;  spazza il pavimento della caverna. L'uscita e' in alto: il
;  salto finale e' il climax.
;  Gira coi banchi 2 (codice) e 3 (dati) mappati - mai commutati
;  durante l'episodio. Riusa dal kernel: read_stick, read_trig,
;  vdp_copy/fill, psg_mute, WRTVDP.
; ============================================================
        ORG 08000h

; ---------- costanti ----------
EP_WALK  equ 320        ; 1.25 px/frame (8.8)
EP_GRAV  equ 40         ; 0.156 px/f^2
EP_JUMP  equ 0340h      ; 3.25 px/f: apice ~34px (i gradini da
                        ; 24px si salgono con margine comodo)
EP_VYMAX equ 0400h
NZ_JUMP  equ 12         ; rumore dello stacco
NZ_ALERT equ 16         ; soglia: l'occhio si apre
NZ_ATTACK equ 40        ; soglia: arriva la mano
NZ_BAT   equ 20         ; lo strillo del pipistrello fa RUMORE
; i pipistrelli: pattugliano le quote dei salti; il morso costa
; un compagno E il rumore dello strillo (doppio tradimento)
BAT_PAT  equ 148        ; pattern (148/152: due frame d'ali)
EP_IFR   equ 90
HAND_Y   equ 144        ; la mano spazza il pavimento (y=160)
HAND_MIN equ 56
HAND_MAX equ 200

; ---------- RAM dell'episodio (pulita da ep_start) ----------
ep_room   equ 0C050h
ep_xl     equ 0C051h
ep_xh     equ 0C052h
ep_yl     equ 0C053h
ep_yh     equ 0C054h
ep_vyl    equ 0C055h
ep_vyh    equ 0C056h
ep_ong    equ 0C057h    ; 1 = a terra
ep_noise  equ 0C058h    ; 0..80
cyc_state equ 0C059h    ; 0 dorme, 1 all'erta, 2 attacco
cyc_t     equ 0C05Ah
hand_xx   equ 0C05Bh
hand_dir  equ 0C05Ch
ep_hud    equ 0C05Dh
ep_ifr    equ 0C05Eh
ep_sfx_t  equ 0C05Fh
ep_sfx_ty equ 0C060h    ; 0 tonfo, 1 schianto, 2 ringhio, 3 mano,
                        ; 4 strillo pipistrello, 5 URLO del ciclope
ep_jlatch equ 0C061h
ep_mov    equ 0C062h    ; 0 fermo, 1 destra, 2 sinistra
ep_eyed   equ 0C063h    ; 1 = apri occhio, 2 = chiudi (per l'ISR)
ep_nlast  equ 0C064h
snore_t   equ 0C065h
ep_cyc    equ 0C066h    ; questa stanza ha il ciclope
ep_end    equ 0C067h    ; 1 vittoria, 2 sconfitta
ep_face   equ 0C068h    ; 0 = guarda a destra, 1 = a sinistra
bat0_x    equ 0C069h
bat0_d    equ 0C06Ah
bat1_x    equ 0C06Bh
bat1_d    equ 0C06Ch
; parametri dei pipistrelli della stanza (copiati da bat_tab)
bat0_on   equ 0C06Eh
bat0_y    equ 0C06Fh
bat0_mn   equ 0C070h
bat0_mx   equ 0C071h
bat1_on   equ 0C072h
bat1_y    equ 0C073h
bat1_mn   equ 0C074h
bat1_mx   equ 0C075h
; la terza stanza: il palo e l'accecamento
ep_stake  equ 0C076h    ; 1 = il palo d'ulivo e' in mano
ep_blind  equ 0C077h    ; 1 = accecato: furia cieca, uscita accesa
nt_qoff   equ 0C078h    ; coda di poke alla name table (dw offset)
nt_qval   equ 0C07Ah    ; valore da scrivere
nt_qcnt   equ 0C07Bh    ; celle (passo 32 = in colonna); 0 = vuota
pain_step equ 0C07Ch    ; volto del dolore: 3 sopracciglio,
                        ; 2 bocca-su, 1 bocca-giu (uno per frame)
pup_last  equ 0C07Dh    ; ultima posa della pupilla mostrata
cmus_i    equ 0C07Eh    ; la musica di fondo della caverna
cmus_t    equ 0C07Fh
room_map  equ 0C100h    ; copia RAM della stanza (768 byte)

STK_COL  equ 15         ; colonna HUD dell'icona del palo

; ============================================================
;  ingresso dell'episodio (dal kernel, quando phase=1)
; ============================================================
ep_start:
        di
        ; pulizia variabili + mappa
        ld  hl,ep_room
        ld  de,ep_room+1
        ld  bc,0C400h-ep_room-1
        ld  (hl),0
        ldir
        ld  b,10100010b     ; schermo spento
        ld  c,1
        call WRTVDP
        di                  ; WRTVDP del BIOS puo' riabilitare gli
                            ; interrupt: i caricamenti vanno protetti
        ; sprite dell'episodio: Ulisse 16x24, 7 pose x 5 pattern
        ; + mano + pipistrello (2 frame) = 39 pattern
        ld  hl,ep_sprites
        ld  de,VR_SPRP
        ld  bc,39*32
        call vdp_copy
        ; tileset della caverna nei 3 terzi (pattern + colori)
        ld  hl,cave_pat
        ld  de,VR_PAT
        ld  bc,CAVE_NT*8
        call vdp_copy
        ld  hl,cave_pat
        ld  de,VR_PAT+0800h
        ld  bc,CAVE_NT*8
        call vdp_copy
        ld  hl,cave_pat
        ld  de,VR_PAT+1000h
        ld  bc,CAVE_NT*8
        call vdp_copy
        ld  hl,cave_col
        ld  de,VR_COL
        ld  bc,CAVE_NT*8
        call vdp_copy
        ld  hl,cave_col
        ld  de,VR_COL+0800h
        ld  bc,CAVE_NT*8
        call vdp_copy
        ld  hl,cave_col
        ld  de,VR_COL+1000h
        ld  bc,CAVE_NT*8
        call vdp_copy
        ; la ciurma sbarcata: e' le vite dell'episodio
        ld  a,(crew_keep)
        or  a
        jr  z,.cdef
        cp  CREW0+1
        jr  c,.cok
.cdef:
        ld  a,CREW0
.cok:
        ld  (crew),a
        ; prima stanza: la spiaggia
        call ep_load_room
        ; hook di frame dell'episodio
        ld  a,0C3h
        ld  (HTIMI),a
        ld  hl,ep_isr
        ld  (HTIMI+1),hl
        ; PSG: tono A+B (effetti e russare), rumore su A
        ld  a,7             ; toni A+B+C (C = la musica di fondo),
        out (0A0h),a        ; rumore sul canale A
        ld  a,10110000b
        out (0A1h),a
        call psg_mute
        ei

ep_loop:
        halt
        ld  a,(ep_end)
        or  a
        jp  nz,ep_finish
        call ep_input
        call ep_physics
        call ep_noise_upd
        call ep_cyclops
        call ep_pupil
        call ep_repel
        call ep_stab
        call ep_bats
        call ep_timers
        jr  ep_loop

; ------------------------------------------------------------
; input: timone... no, gambe. Sinistra/destra e salto (FIRE)
; ------------------------------------------------------------
ep_input:
        call read_stick
        ld  b,0
        cp  2
        jr  c,.dir
        cp  5
        jr  nc,.tw
        ld  b,1             ; est
        jr  .dir
.tw:
        cp  6
        jr  c,.dir
        cp  9
        jr  nc,.dir
        ld  b,2             ; ovest
.dir:
        ld  a,b
        ld  (ep_mov),a
        ; la direzione di sguardo segue il movimento
        cp  1
        jr  nz,.nfr
        xor a
        ld  (ep_face),a
.nfr:
        cp  2
        jr  nz,.nfl
        ld  a,1
        ld  (ep_face),a
.nfl:
        ; salto: fronte di salita di FIRE, solo a terra
        call read_trig
        cp  0FFh
        jr  z,.pressed
        xor a
        ld  (ep_jlatch),a
        ret
.pressed:
        ld  a,(ep_jlatch)
        or  a
        ret nz
        ld  a,1
        ld  (ep_jlatch),a
        call stab_ready     ; sul ciglio, pronto al colpo:
        ret nz              ; FIRE affonda il palo, non salta
        ld  a,(ep_ong)
        or  a
        ret z
        ; stacco: via, e il rumore del balzo
        ld  hl,-EP_JUMP
        ld  (ep_vyl),hl
        xor a
        ld  (ep_ong),a
        ld  a,NZ_JUMP
        jp  ep_addnoise

; ------------------------------------------------------------
; fisica: orizzontale a prova-e-annulla, verticale con neve...
; con snap al tile. La caduta paga in rumore all'atterraggio.
; ------------------------------------------------------------
ep_physics:
        ; --- orizzontale ---
        ld  a,(ep_mov)
        or  a
        jr  z,.vert
        cp  1
        jr  nz,.left
        ld  hl,(ep_xl)
        ld  de,EP_WALK
        add hl,de
        ld  (ep_xl),hl
        ld  a,(ep_xh)
        cp  233
        jr  c,.wallr
        ld  a,232           ; bordo destro
        ld  (ep_xh),a
        jr  .vert
.wallr:
        add a,13            ; bordo avanzante
        ld  b,a
        call side_solid
        jr  nz,.vert        ; libero: avanti
        ld  hl,(ep_xl)      ; muro: annulla
        ld  de,-EP_WALK
        add hl,de
        ld  (ep_xl),hl
        jr  .vert
.left:
        ld  hl,(ep_xl)
        ld  de,-EP_WALK
        add hl,de
        ld  (ep_xl),hl
        ld  a,(ep_xh)
        cp  8
        jr  nc,.walll
        ld  a,8
        ld  (ep_xh),a
        xor a
        ld  (ep_xl),a
        jr  .vert
.walll:
        add a,2
        ld  b,a
        call side_solid
        jr  nz,.vert        ; libero: avanti
        ld  hl,(ep_xl)
        ld  de,EP_WALK
        add hl,de
        ld  (ep_xl),hl
.vert:
        ; --- verticale: gravita' ---
        ld  hl,(ep_vyl)
        ld  de,EP_GRAV
        add hl,de
        bit 7,h             ; in SALITA (vy negativa): mai cappare -
        jr  nz,.vok         ; il confronto senza segno la scambiava
        ld  a,h             ; per caduta massima e uccideva il salto
        cp  high EP_VYMAX
        jr  c,.vok
        ld  hl,EP_VYMAX
.vok:
        ld  (ep_vyl),hl
        ld  de,(ep_yl)
        add hl,de
        ld  (ep_yl),hl
        ld  a,(ep_vyh)
        bit 7,a
        jr  nz,.rising
        ; scende (o fermo): i piedi toccano? (alto 24)
        ld  a,(ep_yh)
        add a,24
        ld  c,a
        ld  a,(ep_xh)
        add a,3
        ld  b,a
        call tile_type
        cp  1
        jr  z,.land
        ld  a,(ep_yh)
        add a,24
        ld  c,a
        ld  a,(ep_xh)
        add a,12
        ld  b,a
        call tile_type
        cp  1
        jr  z,.land
        xor a               ; in aria
        ld  (ep_ong),a
        jr  .exitchk
.land:
        ld  a,(ep_yh)
        add a,24
        and 0F8h
        sub 24
        ld  (ep_yh),a
        xor a
        ld  (ep_yl),a
        ; il conto dell'atterraggio: rumore = vy d'impatto * 8
        ld  a,(ep_vyh)
        or  a
        jr  z,.still
        cp  2
        jr  c,.quiet
        push af
        ld  a,0             ; tonfo
        ld  (ep_sfx_ty),a
        ld  a,14
        ld  (ep_sfx_t),a
        pop af
.quiet:
        add a,a
        add a,a
        add a,a
        call ep_addnoise
.still:
        xor a
        ld  (ep_vyl),a
        ld  (ep_vyh),a
        ld  a,1
        ld  (ep_ong),a
        jr  .exitchk
.rising:
        ; sale: la testa sbatte?
        ld  a,(ep_yh)
        ld  c,a
        ld  a,(ep_xh)
        add a,3
        ld  b,a
        call tile_type
        cp  1
        jr  z,.bump
        ld  a,(ep_yh)
        ld  c,a
        ld  a,(ep_xh)
        add a,12
        ld  b,a
        call tile_type
        cp  1
        jr  nz,.exitchk
.bump:
        ld  a,(ep_yh)
        and 0F8h
        add a,8
        ld  (ep_yh),a
        xor a
        ld  (ep_yl),a
        ld  (ep_vyl),a
        ld  (ep_vyh),a
.exitchk:
        ; il centro del corpo tocca l'uscita? (alto 24: centro +12)
        ld  a,(ep_yh)
        add a,12
        ld  c,a
        ld  a,(ep_xh)
        add a,8
        ld  b,a
        call tile_type
        cp  2
        jr  z,.door
        cp  3
        ret nz
        ; il PALO d'ulivo: raccolto (punta e gambo, due celle)
        ld  hl,room_map+STK3_OFF
        ld  (hl),0
        ld  hl,room_map+STK3_OFF+32
        ld  (hl),0
        ld  hl,STK3_OFF
        ld  (nt_qoff),hl
        xor a
        ld  (nt_qval),a
        ld  a,2
        ld  (nt_qcnt),a
        ld  a,1
        ld  (ep_stake),a
        ld  (ep_hud),a      ; l'icona nell'HUD
        xor a               ; "clack" del legno
        ld  (ep_sfx_ty),a
        ld  a,12
        ld  (ep_sfx_t),a
        ret
.door:
        ld  a,(ep_room)
        inc a
        ld  (ep_room),a
        cp  EP_NROOMS
        jr  c,.nextroom
        ld  a,1             ; fuori dalla caverna: episodio vinto
        ld  (ep_end),a
        ret
.nextroom:
        jp  ep_load_room

; lato: B=px gia' pronto; controlla a yh+4 e yh+20 (alto 24);
; Z = muro
side_solid:
        ld  a,(ep_yh)
        add a,4
        ld  c,a
        push bc
        call tile_type
        pop bc
        cp  1
        ret z
        ld  a,(ep_yh)
        add a,20
        ld  c,a
        call tile_type
        cp  1
        ret

; B=px, C=py -> A = tipo tile (0 vuoto, 1 solido, 2 uscita)
tile_type:
        ld  a,c
        and 0F8h
        ld  l,a
        ld  h,0
        add hl,hl
        add hl,hl
        ld  a,b
        rrca
        rrca
        rrca
        and 31
        or  l
        ld  l,a
        ld  de,room_map
        add hl,de
        ld  a,(hl)
        ld  h,high type_tab
        ld  l,a
        ld  a,(hl)
        ret

; A = rumore da aggiungere (tetto 80)
ep_addnoise:
        ld  b,a
        ld  a,(ep_noise)
        add a,b
        cp  81
        jr  c,.st
        ld  a,80
.st:
        ld  (ep_noise),a
        ret

; ------------------------------------------------------------
; rumore: decade 1 ogni 2 frame; camminare aggiunge un filo
; ------------------------------------------------------------
ep_noise_upd:
        ld  a,(frame_cnt)
        rrca
        jr  c,.walkn
        ld  a,(ep_noise)
        or  a
        jr  z,.walkn
        dec a
        ld  (ep_noise),a
.walkn:
        ld  a,(ep_mov)
        or  a
        jr  z,.bar
        ld  a,(ep_ong)
        or  a
        jr  z,.bar
        ld  a,(frame_cnt)
        and 7
        jr  nz,.bar
        ld  a,1
        call ep_addnoise
.bar:
        ld  a,(ep_noise)
        rrca
        rrca
        rrca
        and 31
        cp  11
        jr  c,.b2
        ld  a,10
.b2:
        ld  b,a
        ld  a,(ep_nlast)
        cp  b
        ret z
        ld  a,b
        ld  (ep_nlast),a
        ld  a,1
        ld  (ep_hud),a
        ret

; ------------------------------------------------------------
; Polifemo: dorme finche' il rumore non lo desta. La mano spazza
; il pavimento; si schiva solo dalle sporgenze... saltando.
; ------------------------------------------------------------
ep_cyclops:
        ld  a,(ep_cyc)
        or  a
        ret z
        ld  a,(cyc_state)
        or  a
        jp  z,.sleep
        dec a
        jp  z,.alert
        ; --- attacco: la mano spazza ---
        ld  a,(hand_dir)
        or  a
        jr  nz,.back
        ld  a,(hand_xx)
        add a,2
        ld  (hand_xx),a
        cp  HAND_MAX
        jr  c,.coll
        ld  a,1
        ld  (hand_dir),a
        jr  .coll
.back:
        ld  a,(hand_xx)
        sub 2
        ld  (hand_xx),a
        cp  HAND_MIN
        jr  nc,.coll
        ld  a,(ep_blind)    ; accecato: la furia non si placa MAI
        or  a
        jr  z,.calmh
        xor a
        ld  (hand_dir),a    ; riparte: spazzata continua
        jr  .coll
.calmh:
        ld  a,1             ; la mano rientra: torna all'erta
        ld  (cyc_state),a
        xor a
        ld  (cyc_t),a
        ret
.coll:
        ; la mano ha preso Ulisse? (solo se e' in basso)
        ld  a,(ep_ifr)
        or  a
        ret nz
        ld  a,(ep_yh)
        cp  HAND_Y-22       ; il corpo (24px) arriva alla mano?
        ret c
        ld  a,(ep_xh)
        add a,8
        ld  b,a
        ld  a,(hand_xx)
        add a,16
        sub b
        jp  p,.habs
        neg
.habs:
        cp  22
        ret nc
        jp  ep_hit
.alert:
        ; --- all'erta: o si placa, o attacca ---
        ld  a,(ep_noise)
        cp  NZ_ATTACK
        jr  c,.calmdn
        ld  a,2
        ld  (cyc_state),a
        ld  a,HAND_MIN
        ld  (hand_xx),a
        xor a
        ld  (hand_dir),a
        ld  a,3             ; whoosh della manata
        ld  (ep_sfx_ty),a
        ld  a,20
        ld  (ep_sfx_t),a
        ret
.calmdn:
        ld  a,(ep_noise)
        cp  6
        jr  nc,.restless
        ld  hl,cyc_t
        inc (hl)
        ld  a,(hl)
        cp  120
        ret c
        xor a               ; si riaddormenta
        ld  (cyc_state),a
        ld  a,2
        ld  (ep_eyed),a
        ret
.restless:
        xor a
        ld  (cyc_t),a
        ret
.sleep:
        ; --- dorme: russa; il rumore lo sveglia ---
        ld  a,(ep_noise)
        cp  NZ_ALERT
        ret c
        ld  a,1
        ld  (cyc_state),a
        ld  (ep_eyed),a     ; l'occhio si SPALANCA
        ld  (pup_last),a    ; ...con l'iride al centro
        ld  a,2             ; ringhio
        ld  (ep_sfx_ty),a
        ld  a,40
        ld  (ep_sfx_t),a
        xor a
        ld  (cyc_t),a
        ret

; ------------------------------------------------------------
; la pupilla che BALLA: a occhio aperto (all'erta o attacco, non
; da accecato) l'iride scruta la caverna - centro, destra,
; centro, sinistra - un passo ogni 16 frame. L'ISR riscrive il
; blocco dell'occhio solo quando la posa cambia davvero.
; ------------------------------------------------------------
ep_pupil:
        ld  a,(ep_cyc)
        or  a
        ret z
        ld  a,(ep_blind)
        or  a
        ret nz
        ld  a,(cyc_state)
        or  a
        ret z               ; dorme: occhio chiuso
        ld  a,(frame_cnt)
        rrca
        rrca
        rrca
        rrca
        and 3
        ld  hl,pup_seq
        ld  e,a
        ld  d,0
        add hl,de
        ld  a,(hl)
        ld  hl,pup_last
        cp  (hl)
        ret z
        ld  (hl),a
        ld  (ep_eyed),a
        ret
pup_seq:
        db  1,5,1,4         ; centro, destra, centro, sinistra

; ------------------------------------------------------------
; l'occhio APERTO ti vede: alla testa non ci si avvicina.
; Nella zona del viso (in alto, verso il gigante) una forza -
; lo sguardo, il braccio pronto - ti respinge; se si sveglia
; mentre sei sulla fronte, ti spazza giu'. Da accecato, niente:
; non vede piu'.
; ------------------------------------------------------------
ep_repel:
        ld  a,(ep_cyc)
        or  a
        ret z
        ld  a,(ep_blind)
        or  a
        ret nz
        ld  a,(cyc_state)
        or  a
        ret z               ; dorme: via libera alla scalata
        ld  a,(ep_yh)
        cp  81
        ret nc              ; in basso: fuori dalla zona-viso
        ld  a,(ep_xh)
        add a,8
        cp  97
        ret nc              ; lontano dal viso
        ld  a,(ep_xh)       ; respinto: 2px a frame, piu' della
        add a,2             ; camminata - avvicinarsi e' inutile
        cp  233
        jr  c,.rok
        ld  a,232
.rok:
        ld  (ep_xh),a
        ld  a,(frame_cnt)
        and 31
        ret nz
        ld  a,(ep_sfx_t)
        or  a
        ret nz
        ld  a,2             ; ringhia: ti tiene d'occhio
        ld  (ep_sfx_ty),a
        ld  a,12
        ld  (ep_sfx_t),a
        ret

; ------------------------------------------------------------
; NZ = pronto alla stoccata: palo in mano, in piedi sul
; sopracciglio sopra l'occhio, e il ciclope ADDORMENTATO
; (l'occhio DEVE essere chiuso: da sveglio ti sente)
; ------------------------------------------------------------
stab_ready:
        ld  a,(ep_stake)
        or  a
        ret z
        ld  a,(ep_blind)
        or  a
        jr  z,.b1
.no:
        xor a
        ret
.b1:
        ld  a,(cyc_state)
        or  a
        jr  nz,.no
        ld  a,(ep_ong)
        or  a
        jr  z,.no
        ld  a,(ep_yh)
        cp  STAB3_Y-4
        jr  c,.no
        cp  STAB3_Y+5
        jr  nc,.no
        ld  a,(ep_xh)
        add a,8
        cp  STAB3_PX0
        jr  c,.no
        cp  STAB3_PX1+1
        jr  nc,.no
        or  a               ; NZ: in posizione (a = centro-x > 0)
        ret

; ------------------------------------------------------------
; la STOCCATA: in posizione e nel sonno, il colpo va SFERRATO -
; SPAZIO o freccia in basso affondano il palo. Poi la furia
; cieca e la bocca della caverna s'illumina: la via di fuga.
; ------------------------------------------------------------
ep_stab:
        call stab_ready
        ret z
        call read_trig      ; SPAZIO/FIRE...
        cp  0FFh
        jr  z,.colpo
        call read_stick     ; ...o la freccia in basso
        cp  5
        ret nz
.colpo:
        ; ACCECATO!
        ld  a,1
        ld  (ep_blind),a
        ld  a,3
        ld  (ep_eyed),a     ; l'occhio ferito (lo scrive l'ISR)
        ld  (pain_step),a   ; ...e il volto si contrae dal dolore
        ld  a,2
        ld  (cyc_state),a   ; furia: la mano spazza per sempre
        ld  a,HAND_MIN
        ld  (hand_xx),a
        xor a
        ld  (hand_dir),a
        ld  a,5             ; l'URLO vero, straziante
        ld  (ep_sfx_ty),a
        ld  a,100
        ld  (ep_sfx_t),a
        ld  a,EP_IFR        ; il tempo di scendere dal viso
        ld  (ep_ifr),a
        ; la bocca della caverna s'illumina
        ld  hl,room_map+DARK3_OFF
        ld  (hl),7
        ld  hl,DARK3_OFF
        ld  (nt_qoff),hl
        ld  a,7
        ld  (nt_qval),a
        ld  a,1
        ld  (nt_qcnt),a
        ret

; colpito dalla mano: un compagno in mare... in caverna
ep_hit:
        ld  a,EP_IFR
        ld  (ep_ifr),a
        ld  a,1             ; schianto
        ld  (ep_sfx_ty),a
        ld  a,30
        ld  (ep_sfx_t),a
        ld  a,1
        ld  (ep_hud),a
        ; sbalzato via dalla manata
        ld  a,(ep_xh)
        add a,20
        cp  225
        jr  c,.kb
        ld  a,224
.kb:
        ld  (ep_xh),a
        call crew_lose
        ret nz
        ld  a,2             ; la ciurma e' finita
        ld  (ep_end),a
        ret

; ------------------------------------------------------------
; i pipistrelli: volano avanti e indietro sulle quote dei salti.
; Il morso non costa compagni: costa RUMORE (e lo spintone).
; ------------------------------------------------------------
ep_bats:
        ; pipistrello 0
        ld  a,(bat0_on)
        or  a
        jr  z,.n0
        ld  a,(bat0_d)
        or  a
        jr  nz,.b0l
        ld  a,(bat0_x)
        inc a
        ld  (bat0_x),a
        ld  hl,bat0_mx
        cp  (hl)
        jr  c,.b0k
        ld  a,1
        ld  (bat0_d),a
        jr  .b0k
.b0l:
        ld  a,(bat0_x)
        dec a
        ld  (bat0_x),a
        ld  hl,bat0_mn
        cp  (hl)
        jr  nc,.b0k
        xor a
        ld  (bat0_d),a
.b0k:
        ld  a,(bat0_x)
        ld  b,a
        ld  a,(bat0_y)
        ld  c,a
        call bat_bite
.n0:
        ; pipistrello 1
        ld  a,(bat1_on)
        or  a
        ret z
        ld  a,(bat1_d)
        or  a
        jr  nz,.b1l
        ld  a,(bat1_x)
        inc a
        ld  (bat1_x),a
        ld  hl,bat1_mx
        cp  (hl)
        jr  c,.b1k
        ld  a,1
        ld  (bat1_d),a
        jr  .b1k
.b1l:
        ld  a,(bat1_x)
        dec a
        ld  (bat1_x),a
        ld  hl,bat1_mn
        cp  (hl)
        jr  nc,.b1k
        xor a
        ld  (bat1_d),a
.b1k:
        ld  a,(bat1_x)
        ld  b,a
        ld  a,(bat1_y)
        ld  c,a
        jp  bat_bite

; B = x del pipistrello, C = la sua quota: ha preso Ulisse?
; Il morso costa un COMPAGNO, piu' lo strillo che fa rumore.
bat_bite:
        ld  a,(ep_ifr)
        or  a
        ret nz
        ld  a,(ep_yh)
        add a,8
        sub c               ; (yh+8) - bat_y
        jp  p,.ya
        neg
.ya:
        cp  14
        ret nc
        ld  a,(ep_xh)
        sub b
        jp  p,.xa
        neg
.xa:
        cp  12
        ret nc
        ; MORSO: un compagno in meno, strillo, spintone
        ld  a,EP_IFR
        ld  (ep_ifr),a
        ld  a,4             ; strillo acutissimo
        ld  (ep_sfx_ty),a
        ld  a,12
        ld  (ep_sfx_t),a
        ld  a,1
        ld  (ep_hud),a
        ld  a,(ep_xh)
        cp  b
        jr  c,.pushl
        add a,12            ; il pipistrello e' a sinistra: via a destra
        cp  233
        jr  c,.px
        ld  a,232
        jr  .px
.pushl:
        sub 12
        cp  8
        jr  nc,.px
        ld  a,8
.px:
        ld  (ep_xh),a
        ld  a,NZ_BAT
        call ep_addnoise
        call crew_lose
        ret nz
        ld  a,2             ; la ciurma e' finita
        ld  (ep_end),a
        ret

; pipistrelli per stanza: on, quota, x min, x max (x2)
bat_tab:
        db  1,108,64,200    ; spiaggia: sui salti bassi...
        db  1,84,180,232    ; ...e a guardia dell'ultimo tratto
        db  1,100,96,200    ; caverna: due
        db  1,76,120,224
        db  1,112,96,176    ; antro: sulla scalata bassa...
        db  1,76,136,224    ; ...e sui salti di mezza quota

ep_timers:
        ld  a,(ep_ifr)
        or  a
        jr  z,.roar
        dec a
        ld  (ep_ifr),a
.roar:
        ; il lamento periodico della furia cieca: la stessa voce
        ; dell'urlo, ma corta e gia' grave (parte a meta' caduta)
        ld  a,(ep_blind)
        or  a
        ret z
        ld  a,(ep_sfx_t)
        or  a
        ret nz
        ld  a,(frame_cnt)
        and 127
        ret nz
        ld  a,5
        ld  (ep_sfx_ty),a
        ld  a,44
        ld  (ep_sfx_t),a
        ret

; ------------------------------------------------------------
; caricamento stanza (sotto DI, schermo spento)
; ------------------------------------------------------------
ep_load_room:
        di
        ld  b,10100010b
        ld  c,1
        call WRTVDP
        di                  ; (WRTVDP puo' aver fatto EI)
        ; puntatori della stanza
        ld  a,(ep_room)
        add a,a
        add a,a
        ld  l,a
        ld  h,0
        ld  bc,room_tab
        add hl,bc
        ld  e,(hl)
        inc hl
        ld  d,(hl)
        inc hl
        ld  a,(hl)
        inc hl
        ld  h,(hl)
        ld  l,a             ; HL = meta, DE = mappa
        ; meta: start x, start y, ciclope
        ld  a,(hl)
        ld  (ep_xh),a
        inc hl
        ld  a,(hl)
        ld  (ep_yh),a
        inc hl
        ld  a,(hl)
        ld  (ep_cyc),a
        ; mappa in RAM per le collisioni
        push de
        ld  h,d
        ld  l,e
        ld  de,room_map
        ld  bc,768
        ldir
        ; e nella name table
        pop hl
        ld  de,VR_NAME
        ld  bc,768
        call vdp_copy
        ; stato pulito della stanza
        xor a
        ld  (ep_xl),a
        ld  (ep_yl),a
        ld  (ep_vyl),a
        ld  (ep_vyh),a
        ld  (ep_noise),a
        ld  (cyc_state),a
        ld  (hand_xx),a
        ld  (ep_nlast),a
        ld  (bat0_d),a
        ; parametri dei pipistrelli di QUESTA stanza
        ld  a,(ep_room)
        add a,a
        add a,a
        add a,a             ; *8
        ld  l,a
        ld  h,0
        ld  bc,bat_tab
        add hl,bc
        ld  de,bat0_on
        ld  bc,8
        ldir
        ld  a,(bat0_mn)
        ld  (bat0_x),a
        ld  a,(bat1_mx)
        ld  (bat1_x),a
        ld  a,1
        ld  (bat1_d),a
        ld  a,1
        ld  (ep_hud),a
        ; occhio chiuso (se c'e' il ciclope)
        ld  a,(ep_cyc)
        or  a
        jr  z,.noeye
        ld  hl,eye_closed_pat
        ld  de,eye_closed_col
        call eye_write_di
.noeye:
        ld  b,11100010b
        ld  c,1
        call WRTVDP
        ei
        ret

; scrive i 2 tile dell'occhio nei 3 terzi (pat da HL, col da DE)
; versione per il caricamento (sotto DI, con vdp_copy paced)
eye_write_di:
        push de
        push hl
        ld  de,VR_PAT+EYE_T0*8
        ld  bc,64
        call vdp_copy
        pop hl
        push hl
        ld  de,VR_PAT+0800h+EYE_T0*8
        ld  bc,64
        call vdp_copy
        pop hl
        ld  de,VR_PAT+1000h+EYE_T0*8
        ld  bc,64
        call vdp_copy
        pop hl
        push hl
        ld  de,VR_COL+EYE_T0*8
        ld  bc,64
        call vdp_copy
        pop hl
        push hl
        ld  de,VR_COL+0800h+EYE_T0*8
        ld  bc,64
        call vdp_copy
        pop hl
        ld  de,VR_COL+1000h+EYE_T0*8
        ld  bc,64
        jp  vdp_copy

; ------------------------------------------------------------
; fine episodio: lampeggio e ritorno al viaggio
; ------------------------------------------------------------
ep_finish:
        call psg_mute
        ld  a,(frame_cnt)
        ld  b,a
.fl:
        ld  a,(frame_cnt)
        sub b
        cp  120
        jr  nc,.done
        and 8
        jr  z,.c2
        ld  a,(ep_end)
        dec a
        jr  z,.w1
        ld  a,08h
        jr  .set
.w1:
        ld  a,0Fh
        jr  .set
.c2:
        ld  a,(ep_end)
        dec a
        jr  z,.w2
        ld  a,01h
        jr  .set
.w2:
        ld  a,07h
.set:
        di
        out (099h),a
        ld  a,80h|7
        out (099h),a
        ei
        halt
        jr  .fl
.done:
        ld  a,(ep_end)
        dec a
        jr  nz,.lose
        ; VITTORIA: la ciurma salpa - e un compagno ritrovato
        ; sull'isola si unisce, se ne mancano (crew_reward)
        call crew_reward
        xor a
        ld  (phase),a
        ld  a,(leg)
        inc a
        cp  N_DESTS
        jr  c,.setleg
        xor a
        ld  (leg),a
        ld  (leg_magic),a   ; giro completo: si torna al titolo
        ld  a,CREW0
        ld  (crew_keep),a
        jp  init
.setleg:
        ld  (leg),a
        jp  init
.lose:
        ; tutti i compagni perduti: si ritenta la caverna
        ld  a,CREW0
        ld  (crew_keep),a
        jp  init            ; phase resta 1

; ============================================================
;  ISR dell'episodio: OAM, occhio, HUD, audio
; ============================================================
ep_isr:
        ; --- OAM ---
        ld  a,low VR_SPRA
        out (099h),a
        ld  a,(high VR_SPRA)|40h
        out (099h),a
        ; Ulisse 16x24: due meta' impilate per layer (le righe non
        ; si sovrappongono: mai piu' di 3 sprite/riga sopra, 2
        ; sotto). I layer BRONZO usano gli slot della mano: quando
        ; il ciclope attacca cedono il posto - limite mai superato.
        ; slot: 0=bianco-su 1=bianco-giu 2=rosso-su
        ;       3=bronzo-su/manoSX 4=bronzo-giu/manoDX
        ld  a,(ep_yh)
        dec a
        ld  d,a
        ld  a,(ep_ifr)
        or  a
        jr  z,.nob
        ld  a,(frame_cnt)
        and 2
        jr  z,.nob
        ld  d,209           ; colpito: lampeggia tutto (giu' = 225)
.nob:
        ; C = base della posa. REGOLA DEI PLATFORM: frontale solo
        ; da fermo; in movimento e in volo e' DI PROFILO nella
        ; direzione di marcia (a sinistra: pose specchiate, +60)
        ld  a,(ep_ong)
        or  a
        jr  nz,.gr
        ld  c,60            ; salto, di profilo
        jr  .face
.gr:
        ld  a,(ep_mov)
        or  a
        jr  z,.st
        ld  a,(frame_cnt)
        and 8
        jr  z,.wb
        ld  c,20            ; falcata
        jr  .face
.wb:
        ld  c,40            ; passo raccolto
        jr  .face
.st:
        ld  c,0             ; fermo: frontale, il viso al giocatore
        jr  .pat
.face:
        ld  a,(ep_face)
        or  a
        jr  z,.pat
        ld  a,c
        add a,60            ; versione specchiata
        ld  c,a
.pat:
        ld  a,(ep_xh)
        ld  e,a
        ld  a,d             ; 0: bianco-su
        out (098h),a
        ld  a,e
        out (098h),a
        ld  a,c
        out (098h),a
        ld  a,15
        out (098h),a
        ld  a,d             ; 1: bianco-giu
        add a,16
        out (098h),a
        ld  a,e
        out (098h),a
        ld  a,c
        add a,4
        out (098h),a
        ld  a,15
        out (098h),a
        ld  a,d             ; 2: chioma e barba (nero-su)
        out (098h),a
        ld  a,e
        out (098h),a
        ld  a,c
        add a,8
        out (098h),a
        ld  a,1             ; NERE, sullo sfondo indaco dei livelli
        out (098h),a
        ld  a,d             ; 3: bronzo-su - SEMPRE visibile: la
        out (098h),a        ; mano ora e' un solo sprite, quindi la
        ld  a,e             ; faccia non "diventa trasparente" piu'
        out (098h),a        ; (4 per riga: W,K,B + mano = esatti)
        ld  a,c
        add a,12
        out (098h),a
        ld  a,10
        out (098h),a
        ld  a,d             ; 4: bronzo-giu
        add a,16
        out (098h),a
        ld  a,e
        out (098h),a
        ld  a,c
        add a,16
        out (098h),a
        ld  a,10
        out (098h),a
        ; slot 5: la mano (un solo sprite da 16, centrata)
        ld  a,(cyc_state)
        cp  2
        jr  nz,.hhid
        ld  a,HAND_Y-1
        out (098h),a
        ld  a,(hand_xx)
        add a,8
        out (098h),a
        ld  a,(frame_cnt)   ; le dita brancolano: 2 frame
        and 8
        jr  z,.hh1
        ld  a,144
        jr  .hh2
.hh1:
        ld  a,140
.hh2:
        out (098h),a
        ld  a,10
        out (098h),a
        jr  .batsec
.hhid:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        out (098h),a
        out (098h),a
.batsec:
        ; slot 6-7: i pipistrelli della stanza (quote lontane
        ; dalle righe della mano per costruzione)
        ld  a,(frame_cnt)
        and 4
        jr  z,.bw1
        ld  c,BAT_PAT+4
        jr  .bw2
.bw1:
        ld  c,BAT_PAT
.bw2:
        ld  a,(bat0_on)
        or  a
        jr  z,.b0h
        ld  a,(bat0_y)
        dec a
        out (098h),a
        ld  a,(bat0_x)
        out (098h),a
        ld  a,c
        out (098h),a
        ld  a,1             ; neri, come si deve
        out (098h),a
        jr  .b1s
.b0h:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        out (098h),a
        out (098h),a
.b1s:
        ld  a,(bat1_on)
        or  a
        jr  z,.b1h
        ld  a,(bat1_y)
        dec a
        out (098h),a
        ld  a,(bat1_x)
        out (098h),a
        ld  a,c
        out (098h),a
        ld  a,1
        out (098h),a
        jr  .oamend
.b1h:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        out (098h),a
        out (098h),a
.oamend:
        ld  a,208
        out (098h),a
        ; --- poke in coda alla name table (palo/uscita) ---
        ld  a,(nt_qcnt)
        or  a
        jr  z,.noq
        ld  b,a
        ld  hl,(nt_qoff)
        ld  de,VR_NAME
        add hl,de
.ql:
        ld  a,l
        out (099h),a
        ld  a,h
        or  40h
        out (099h),a
        ld  a,(nt_qval)
        out (098h),a
        ld  de,32
        add hl,de
        djnz .ql
        xor a
        ld  (nt_qcnt),a
.noq:
        ; --- l'occhio del ciclope (quando cambia stato) ---
        ld  a,(ep_eyed)
        or  a
        jr  z,.noeye
        cp  1
        jr  z,.eop
        cp  3
        jr  z,.ebl
        cp  4
        jr  z,.eol
        cp  5
        jr  z,.eor
        ld  hl,eye_closed_pat
        ld  de,eye_closed_col
        jr  .eydo
.eop:
        ld  hl,eye_open_pat
        ld  de,eye_open_col
        jr  .eydo
.eol:
        ld  hl,eye_openl_pat
        ld  de,eye_openl_col
        jr  .eydo
.eor:
        ld  hl,eye_openr_pat
        ld  de,eye_openr_col
        jr  .eydo
.ebl:
        ld  hl,eye_blind_pat
        ld  de,eye_blind_col
.eydo:
        call eye_write_fast
        xor a
        ld  (ep_eyed),a
        jr  .nopain         ; un blocco VRAM per frame, non due
.noeye:
        ; --- il volto del dolore: un blocco per frame ---
        ld  a,(pain_step)
        or  a
        jr  z,.nopain
        dec a
        ld  (pain_step),a
        cp  2
        jr  z,.pbrow
        cp  1
        jr  z,.pma
        ld  hl,pain_mb_pat  ; passo 1: bocca, meta' inferiore
        ld  de,pain_mb_col
        ld  a,PAIN_MB_T0
        ld  c,PAIN_MB_N
        jr  .pgo
.pbrow:
        ld  hl,pain_brow_pat ; passo 3: il sopracciglio inarcato
        ld  de,pain_brow_col
        ld  a,PAIN_BROW_T0
        ld  c,PAIN_BROW_N
        jr  .pgo
.pma:
        ld  hl,pain_ma_pat  ; passo 2: bocca, meta' superiore
        ld  de,pain_ma_col
        ld  a,PAIN_MA_T0
        ld  c,PAIN_MA_N
.pgo:
        call tile_write_fast
.nopain:
        ; --- HUD: ciurma + barra del RUMORE ---
        ld  a,(ep_hud)
        or  a
        jr  z,.nohud
        xor a
        ld  (ep_hud),a
        ; il colore della ciurma: bianco, GIALLO (<=6), ROSSO (<=2)
        ld  a,(crew)
        cp  3
        ld  b,84h
        jr  c,.cwset
        cp  7
        ld  b,0B4h
        jr  c,.cwset
        ld  b,0F4h
.cwset:
        ld  a,low (VR_COL+HUD_MAN*8)
        out (099h),a
        ld  a,(high (VR_COL+HUD_MAN*8))|40h
        out (099h),a
        ld  e,8
.cwl:
        ld  a,b
        out (098h),a
        dec e
        jr  nz,.cwl
        ld  a,low (VR_NAME+CREW_COL)
        out (099h),a
        ld  a,(high (VR_NAME+CREW_COL))|40h
        out (099h),a
        ld  a,(crew)
        ld  d,a
        ld  e,12
.hc:
        ld  a,d
        or  a
        jr  z,.h0
        dec d
        ld  a,HUD_MAN
        jr  .h1
.h0:
        xor a
.h1:
        out (098h),a
        dec e
        jr  nz,.hc
        ld  a,low (VR_NAME+BAR_COL)
        out (099h),a
        ld  a,(high (VR_NAME+BAR_COL))|40h
        out (099h),a
        ld  a,(ep_nlast)
        ld  d,a
        ld  e,10
.hb:
        ld  a,d
        or  a
        jr  z,.hd
        dec d
        ld  a,HUD_FILL
        jr  .h2
.hd:
        ld  a,HUD_DOT
.h2:
        out (098h),a
        dec e
        jr  nz,.hb
        ; l'icona del palo (quando e' in mano)
        ld  a,low (VR_NAME+STK_COL)
        out (099h),a
        ld  a,(high (VR_NAME+STK_COL))|40h
        out (099h),a
        ld  a,(ep_stake)
        or  a
        jr  z,.hs
        ld  a,STAKE_TILE
.hs:
        out (098h),a
.nohud:
        call ep_audio
        ld  hl,frame_cnt
        inc (hl)
        ret

; occhio: scrittura veloce da ISR (siamo nel vblank).
; HL = pattern (16 byte), DE = colori (16 byte); ogni blocco va
; scritto identico nei 3 terzi, .one preserva la sorgente.
eye_write_fast:
        push de
        ld  bc,VR_PAT+EYE_T0*8
        call .one
        ld  bc,VR_PAT+0800h+EYE_T0*8
        call .one
        ld  bc,VR_PAT+1000h+EYE_T0*8
        call .one
        pop hl              ; ora i colori
        ld  bc,VR_COL+EYE_T0*8
        call .one
        ld  bc,VR_COL+0800h+EYE_T0*8
        call .one
        ld  bc,VR_COL+1000h+EYE_T0*8
.one:                       ; l'ultima chiamata cade qui e ritorna
        push hl
        ld  a,c
        out (099h),a
        ld  a,b
        or  40h
        out (099h),a
        ld  b,64
.wr:
        ld  a,(hl)
        out (098h),a
        inc hl
        djnz .wr
        pop hl
        ret

; scrive C tile CONTIGUI nei 3 terzi: A = primo tile, C = numero,
; HL = pattern (C*8 byte), DE = colori (C*8 byte). Da ISR (vblank).
tile_write_fast:
        push de             ; sorgente colori, per dopo
        push hl
        ld  h,0
        ld  l,a
        add hl,hl
        add hl,hl
        add hl,hl           ; HL = tile*8
        ld  d,h
        ld  e,l
        pop hl              ; sorgente pattern
        push de
        ld  a,d
        add a,high VR_PAT
        ld  d,a
        call .runs
        pop de
        push de
        ld  a,d
        add a,high (VR_PAT+0800h)
        ld  d,a
        call .runs
        pop de
        push de
        ld  a,d
        add a,high (VR_PAT+1000h)
        ld  d,a
        call .runs
        pop de
        pop hl              ; ora i colori
        push de
        ld  a,d
        add a,high VR_COL
        ld  d,a
        call .runs
        pop de
        push de
        ld  a,d
        add a,high (VR_COL+0800h)
        ld  d,a
        call .runs
        pop de
        ld  a,d
        add a,high (VR_COL+1000h)
        ld  d,a
        jp  .runs           ; l'ultima corsa ritorna al chiamante
.runs:                      ; DE = VRAM, HL = sorgente (preservata)
        push hl
        ld  a,e
        out (099h),a
        ld  a,d
        or  40h
        out (099h),a
        ld  b,c
.rt:
        push bc
        ld  b,8
.rb:
        ld  a,(hl)
        out (098h),a
        inc hl
        djnz .rb
        pop bc
        djnz .rt
        pop hl
        ret

; ------------------------------------------------------------
; audio dell'episodio: effetti sul canale A, russare sul B
; ------------------------------------------------------------
ep_audio:
        call cave_music     ; il fondo sommesso non tace mai
        ; --- effetti ---
        ld  a,(ep_sfx_t)
        or  a
        jp  z,.quiet
        dec a
        ld  (ep_sfx_t),a
        ld  d,a
        ld  a,(ep_sfx_ty)
        or  a
        jr  nz,.n1
        ; tonfo: SECCO - piena botta subito, coda breve
        ld  a,d
        cp  8
        jr  c,.tqu
        ld  a,15
.tqu:
        ld  b,a
        ld  c,22
        jr  .out
.n1:
        dec a
        jr  nz,.n2
        ; schianto della manata presa
        ld  a,d
        cp  26
        jr  c,.cr2
        ld  b,15
        ld  c,6
        jr  .out
.cr2:
        ld  a,d
        srl a
        ld  b,a
        ld  a,d
        and 3
        add a,24
        ld  c,a
        jr  .out
.n2:
        dec a
        jr  nz,.n3
        ; ringhio: rumore che sprofonda
        ld  a,d
        srl a
        ld  c,a
        ld  a,32
        sub c
        ld  c,a
        ld  a,d
        cp  12
        jr  c,.gv
        ld  a,11
.gv:
        ld  b,a
        jr  .out
.n3:
        dec a
        jr  nz,.n4
        ; whoosh della mano: verso il chiaro
        ld  a,d
        ld  c,a
        ld  b,9
        jr  .out
.n4:
        dec a
        jr  nz,.n5
        ; lo strillo del pipistrello: acutissimo e corto
        ld  a,d
        add a,4
        cp  13
        jr  c,.sv
        ld  a,12
.sv:
        ld  b,a
        ld  c,1
.out:
        ld  a,8
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        ld  a,6
        out (0A0h),a
        ld  a,c
        out (0A1h),a
        xor a
        out (0A0h),a
        ld  a,1
        out (0A1h),a
        jp  .snore
.n5:
        ; l'URLO dell'accecamento: un ruggito GUTTURALE, non un
        ; laser - attacco che sale dal registro grave, sostegno
        ; col growl (trillo largo del periodo ogni 2 frame: la
        ; gola che raspa) e una dissonanza larga sul secondo
        ; canale, rumore ruvido che sfarfalla sopra, coda che
        ; sprofonda e si spegne.
        ld  a,d
        cp  70
        jr  c,.us
        sub 70              ; attacco (d 100..70): sale al sostegno
        add a,a
        add a,180           ; periodo 240 -> 180 (grave -> medio)
        ld  b,a
        jr  .uv
.us:
        ld  a,70
        sub d
        srl a
        add a,180           ; sostegno: sprofonda piano (180..215)
        ld  b,a
        ld  a,d             ; il growl, solo qui: raspo di gola
        and 2
        jr  z,.uv
        ld  a,b
        add a,24
        ld  b,a
.uv:
        xor a               ; tono A: il corpo del ruggito
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        ld  a,1
        out (0A0h),a
        xor a
        out (0A1h),a
        ld  a,2             ; tono B: dissonanza larga (battiti)
        out (0A0h),a
        ld  a,b
        add a,13
        out (0A1h),a
        ld  a,3
        out (0A0h),a
        xor a
        out (0A1h),a
        ld  a,6             ; il rumore ruvido che sfarfalla
        out (0A0h),a
        ld  a,d
        and 7
        add a,8
        out (0A1h),a
        ld  a,d             ; inviluppo: pieno, coda in dissolvenza
        cp  25
        jr  c,.ud
        ld  a,15
        jr  .uw
.ud:
        srl a
.uw:
        ld  b,a
        ld  a,8
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        ld  a,9
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        ret                 ; niente russare: e' sveglio eccome
.quiet:
        ld  a,8
        out (0A0h),a
        xor a
        out (0A1h),a
.snore:
        ; --- il russare del ciclope (solo se dorme) ---
        ld  a,(ep_cyc)
        or  a
        jr  z,.snoff
        ld  a,(cyc_state)
        or  a
        jr  nz,.snoff
        ld  hl,snore_t
        inc (hl)
        ld  a,(hl)
        cp  160
        jr  c,.snenv
        ld  (hl),0
.snenv:
        ld  a,(hl)
        cp  48
        jr  nc,.snoff
        cp  24
        jr  c,.snup
        ld  b,a
        ld  a,48
        sub b
.snup:
        srl a
        srl a               ; 0..6
        ld  b,a
        ld  a,2
        out (0A0h),a
        ld  a,low 3400
        out (0A1h),a
        ld  a,3
        out (0A0h),a
        ld  a,high 3400
        out (0A1h),a
        ld  a,9
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        ret
.snoff:
        ld  a,9
        out (0A0h),a
        xor a
        out (0A1h),a
        ret

; ------------------------------------------------------------
; la musica della caverna (canale C): note basse e rade, in
; minore, pizzicate - un fondo che respira SOTTO i suoni di
; gioco (effetti a volume 10-15, il fondo si spegne da 5 a 1:
; i rumori che svegliano il ciclope restano in primo piano)
; ------------------------------------------------------------
cave_music:
        ld  hl,cmus_t
        inc (hl)
        ld  a,(hl)
        cp  32
        jr  c,.note
        ld  (hl),0
        ld  hl,cmus_i
        ld  a,(hl)
        inc a
        and 7
        ld  (hl),a
.note:
        ld  a,(cmus_i)
        add a,a
        ld  l,a
        ld  h,0
        ld  bc,cave_mus_tab
        add hl,bc
        ld  a,4             ; periodo del canale C (fine+coarse:
        out (0A0h),a        ; le note basse vogliono 16 bit)
        ld  a,(hl)
        out (0A1h),a
        inc hl
        ld  a,5
        out (0A0h),a
        ld  a,(hl)
        out (0A1h),a
        ld  a,(cmus_t)      ; ogni nota si spegne come pizzicata
        srl a
        srl a
        srl a
        ld  b,a
        ld  a,5
        sub b
        jr  nc,.vok
        xor a
.vok:
        ld  b,a
        ld  a,10
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        ret

; La minore, bassa e inquieta: la caverna respira
cave_mus_tab:
        dw  1017, 679, 855, 679, 762, 1017, 855, 640

; --- guardia di fine banco 2 ---
        DS  0A000h-$,0FFh
