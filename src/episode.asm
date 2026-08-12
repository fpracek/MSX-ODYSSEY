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
EP_JUMP  equ 0300h      ; 3 px/f: apice ~29px (3.5 tile)
EP_VYMAX equ 0400h
NZ_JUMP  equ 12         ; rumore dello stacco
NZ_ALERT equ 20         ; soglia: l'occhio si apre
NZ_ATTACK equ 40        ; soglia: arriva la mano
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
ep_sfx_ty equ 0C060h    ; 0 tonfo, 1 schianto, 2 ringhio, 3 mano
ep_jlatch equ 0C061h
ep_mov    equ 0C062h    ; 0 fermo, 1 destra, 2 sinistra
ep_eyed   equ 0C063h    ; 1 = apri occhio, 2 = chiudi (per l'ISR)
ep_nlast  equ 0C064h
snore_t   equ 0C065h
ep_cyc    equ 0C066h    ; questa stanza ha il ciclope
ep_end    equ 0C067h    ; 1 vittoria, 2 sconfitta
ep_face   equ 0C068h    ; 0 = guarda a destra, 1 = a sinistra
room_map  equ 0C100h    ; copia RAM della stanza (768 byte)

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
        ; (frontale + profili destra/sinistra) + mano = 37 pattern
        ld  hl,ep_sprites
        ld  de,VR_SPRP
        ld  bc,37*32
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
        ld  a,7
        out (0A0h),a
        ld  a,10110100b
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
        ld  a,h
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
        ld  a,8
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
        ret nz
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
        ld  a,2             ; ringhio
        ld  (ep_sfx_ty),a
        ld  a,40
        ld  (ep_sfx_t),a
        xor a
        ld  (cyc_t),a
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
        ld  hl,crew
        dec (hl)
        ret nz
        ld  a,2             ; la ciurma e' finita
        ld  (ep_end),a
        ret

ep_timers:
        ld  a,(ep_ifr)
        or  a
        ret z
        dec a
        ld  (ep_ifr),a
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
        ld  bc,48
        call vdp_copy
        pop hl
        push hl
        ld  de,VR_PAT+0800h+EYE_T0*8
        ld  bc,48
        call vdp_copy
        pop hl
        ld  de,VR_PAT+1000h+EYE_T0*8
        ld  bc,48
        call vdp_copy
        pop hl
        push hl
        ld  de,VR_COL+EYE_T0*8
        ld  bc,48
        call vdp_copy
        pop hl
        push hl
        ld  de,VR_COL+0800h+EYE_T0*8
        ld  bc,48
        call vdp_copy
        pop hl
        ld  de,VR_COL+1000h+EYE_T0*8
        ld  bc,48
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
        ; VITTORIA: la ciurma superstite salpa verso la prossima isola
        ld  a,(crew)
        ld  (crew_keep),a
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
        ld  a,(cyc_state)   ; slot 3-4: bronzo... o la mano
        cp  2
        jr  z,.hand
        ld  a,d             ; 3: bronzo-su
        out (098h),a
        ld  a,e
        out (098h),a
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
        jr  .term
.hand:
        ld  a,HAND_Y-1
        out (098h),a
        ld  a,(hand_xx)
        out (098h),a
        ld  a,140
        out (098h),a
        ld  a,10
        out (098h),a
        ld  a,HAND_Y-1
        out (098h),a
        ld  a,(hand_xx)
        add a,16
        out (098h),a
        ld  a,144
        out (098h),a
        ld  a,10
        out (098h),a
.term:
        ld  a,208
        out (098h),a
        ; --- l'occhio del ciclope (quando cambia stato) ---
        ld  a,(ep_eyed)
        or  a
        jr  z,.noeye
        cp  1
        jr  nz,.close
        ld  hl,eye_open_pat
        ld  de,eye_open_col
        jr  .eydo
.close:
        ld  hl,eye_closed_pat
        ld  de,eye_closed_col
.eydo:
        call eye_write_fast
        xor a
        ld  (ep_eyed),a
.noeye:
        ; --- HUD: ciurma + barra del RUMORE ---
        ld  a,(ep_hud)
        or  a
        jr  z,.nohud
        xor a
        ld  (ep_hud),a
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
        ld  b,48
.wr:
        ld  a,(hl)
        out (098h),a
        inc hl
        djnz .wr
        pop hl
        ret

; ------------------------------------------------------------
; audio dell'episodio: effetti sul canale A, russare sul B
; ------------------------------------------------------------
ep_audio:
        ; --- effetti ---
        ld  a,(ep_sfx_t)
        or  a
        jr  z,.quiet
        dec a
        ld  (ep_sfx_t),a
        ld  d,a
        ld  a,(ep_sfx_ty)
        or  a
        jr  nz,.n1
        ; tonfo: breve, sordo
        ld  b,10
        ld  c,12
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
        ; whoosh della mano: verso il chiaro
        ld  a,d
        ld  c,a
        ld  b,9
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
        jr  .snore
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

; --- guardia di fine banco 2 ---
        DS  0A000h-$,0FFh
