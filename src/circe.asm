; ============================================================
;  BANCO 6 - L'EPISODIO DI CIRCE (MODULE circe)
;  La maga canta sulla balconata e scaglia stelle che cadono
;  sulla tua verticale (avviso luccicante, poi la caduta).
;  Colpito SENZA il moly: un compagno diventa... perduto.
;  Colpito COL moly (raccolto nel bosco): resisti a meta' -
;  MAIALE per qualche secondo: basso e veloce, e solo cosi'
;  si passa nel cunicolo sotto la balconata, verso l'uscita.
;  Motore: fisica e stanze del modello Polifemo, con l'altezza
;  del corpo variabile (24 uomo / 16 maiale).
; ============================================================

; ---------- costanti ----------
EP_GRAV  equ 40
EP_VYMAX equ 0400h
EP_IFR   equ 90
PIG_T    equ 200        ; ~4 secondi da maiale: il cunicolo va CORSO
CI_CAST  equ 70         ; cadenza degli incantesimi (serrata)
WARN_T   equ 20         ; l'avviso luccicante prima della caduta
BOLT_VY  equ 3          ; la stella cade rapida

; ---------- RAM (pulita da ep_start) ----------
ep_room   equ 0C050h
ep_xl     equ 0C051h
ep_xh     equ 0C052h
ep_yl     equ 0C053h
ep_yh     equ 0C054h
ep_vyl    equ 0C055h
ep_vyh    equ 0C056h
ep_ong    equ 0C057h
ci_pig    equ 0C058h    ; timer da maiale (0 = uomo)
bolt_st   equ 0C059h    ; 0 niente, 1 avviso, 2 la stella cade
bolt_x    equ 0C05Ah
bolt_y    equ 0C05Bh
bolt_t    equ 0C05Ch
ep_hud    equ 0C05Dh
ep_ifr    equ 0C05Eh
ep_sfx_t  equ 0C05Fh
ep_sfx_ty equ 0C060h    ; 0 tonfo, 1 colpo, 2 zap, 3 pof, 4 grugnito
ep_jlatch equ 0C061h
ep_mov    equ 0C062h
ep_face   equ 0C063h
ep_end    equ 0C064h    ; 1 vittoria, 2 sconfitta
ci_here   equ 0C065h    ; Circe e' in questa stanza
cast_t    equ 0C066h
ci_moly   equ 0C067h    ; l'erba di Hermes in mano
ci_hh     equ 0C068h    ; altezza del corpo (24 uomo, 16 maiale)
ci_hc     equ 0C069h    ; mezza altezza (12 / 8)
ci_spd    equ 0C06Ah    ; dw: passo (8.8)
ci_jmp    equ 0C06Ch    ; dw: velocita' di stacco (negativa)
song_i    equ 0C06Eh
song_t    equ 0C06Fh
bar_last  equ 0C070h
nt_qoff   equ 0C071h
nt_qval   equ 0C073h
nt_qcnt   equ 0C074h
; i LEONI ammansiti: parametri (da beast_tab, 8 byte) + stato
b0_on     equ 0C075h
b0_y      equ 0C076h
b0_mn     equ 0C077h
b0_mx     equ 0C078h
b1_on     equ 0C079h
b1_y      equ 0C07Ah
b1_mn     equ 0C07Bh
b1_mx     equ 0C07Ch
b0_x      equ 0C07Dh
b0_d      equ 0C07Eh
b1_x      equ 0C07Fh
b1_d      equ 0C080h
room_map  equ 0C100h

; ============================================================
;  ingresso (dal kernel, quando phase=2; banchi 6/7 gia' mappati)
; ============================================================
ep_start:
        di
        ld  hl,ep_room
        ld  de,ep_room+1
        ld  bc,0C400h-ep_room-1
        ld  (hl),0
        ldir
        ld  b,10100010b     ; schermo spento
        ld  c,1
        call WRTVDP
        di                  ; (WRTVDP del BIOS puo' fare EI)
        ; sprite: Ulisse 35 + maiale 4 + stella 2 + leone 4 = 45
        ld  hl,ep_sprites
        ld  de,VR_SPRP
        ld  bc,45*32
        call vdp_copy
        ; tileset del palazzo nei 3 terzi
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
        ; la ciurma sbarcata
        ld  a,(crew_keep)
        or  a
        jr  z,.cdef
        cp  CREW0+1
        jr  c,.cok
.cdef:
        ld  a,CREW0
.cok:
        ld  (crew),a
        xor a
        call set_form       ; si comincia in forma umana
        call ep_load_room
        ld  a,0C3h
        ld  (HTIMI),a
        ld  hl,ep_isr
        ld  (HTIMI+1),hl
        ld  a,7             ; PSG: toni A+B, rumore su A
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
        call ci_magic
        call ci_beasts
        call ep_timers
        jr  ep_loop

; ------------------------------------------------------------
; A: 0 = uomo, 1 = maiale (corpo, passo e balzo)
; ------------------------------------------------------------
set_form:
        or  a
        jr  nz,.pig
        ld  a,24
        ld  (ci_hh),a
        ld  a,12
        ld  (ci_hc),a
        ld  hl,320
        ld  (ci_spd),hl
        ld  hl,-0340h
        ld  (ci_jmp),hl
        ret
.pig:
        ld  a,16
        ld  (ci_hh),a
        ld  a,8
        ld  (ci_hc),a
        ld  hl,384          ; zampette rapide
        ld  (ci_spd),hl
        ld  hl,-0280h       ; balzo corto
        ld  (ci_jmp),hl
        ret

; ------------------------------------------------------------
; input: sinistra/destra e salto
; ------------------------------------------------------------
ep_input:
        call read_stick
        ld  b,0
        cp  2
        jr  c,.dir
        cp  5
        jr  nc,.tw
        ld  b,1
        jr  .dir
.tw:
        cp  6
        jr  c,.dir
        cp  9
        jr  nc,.dir
        ld  b,2
.dir:
        ld  a,b
        ld  (ep_mov),a
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
        ld  hl,(ci_jmp)
        ld  (ep_vyl),hl
        xor a
        ld  (ep_ong),a
        ld  a,(ci_pig)
        or  a
        ret z
        ld  a,4             ; il grugnito del balzo
        ld  (ep_sfx_ty),a
        ld  a,8
        ld  (ep_sfx_t),a
        ret

; ------------------------------------------------------------
; fisica: come Polifemo, ma il corpo e' alto (ci_hh)
; ------------------------------------------------------------
ep_physics:
        ld  a,(ep_mov)
        or  a
        jr  z,.vert
        cp  1
        jr  nz,.left
        ld  hl,(ep_xl)
        ld  de,(ci_spd)
        add hl,de
        ld  (ep_xl),hl
        ld  a,(ep_xh)
        cp  233
        jr  c,.wallr
        ld  a,232
        ld  (ep_xh),a
        jr  .vert
.wallr:
        add a,13
        ld  b,a
        call side_solid
        jr  nz,.vert
        ld  hl,(ep_xl)
        ld  de,(ci_spd)
        or  a
        sbc hl,de
        ld  (ep_xl),hl
        jr  .vert
.left:
        ld  hl,(ep_xl)
        ld  de,(ci_spd)
        or  a
        sbc hl,de
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
        jr  nz,.vert
        ld  hl,(ep_xl)
        ld  de,(ci_spd)
        add hl,de
        ld  (ep_xl),hl
.vert:
        ld  hl,(ep_vyl)
        ld  de,EP_GRAV
        add hl,de
        bit 7,h             ; il cap risparmia la salita (segno!)
        jr  nz,.vok
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
        ; scende: i piedi (yh + altezza corpo)
        ld  a,(ep_yh)
        ld  hl,ci_hh
        add a,(hl)
        ld  c,a
        ld  a,(ep_xh)
        add a,3
        ld  b,a
        call tile_type
        cp  1
        jr  z,.land
        ld  a,(ep_yh)
        ld  hl,ci_hh
        add a,(hl)
        ld  c,a
        ld  a,(ep_xh)
        add a,12
        ld  b,a
        call tile_type
        cp  1
        jr  z,.land
        xor a
        ld  (ep_ong),a
        jr  .exitchk
.land:
        ld  a,(ep_yh)
        ld  hl,ci_hh
        add a,(hl)
        and 0F8h
        sub (hl)
        ld  (ep_yh),a
        xor a
        ld  (ep_yl),a
        ld  a,(ep_vyh)
        cp  2
        jr  c,.still
        ld  a,0             ; tonfo
        ld  (ep_sfx_ty),a
        ld  a,14
        ld  (ep_sfx_t),a
.still:
        xor a
        ld  (ep_vyl),a
        ld  (ep_vyh),a
        ld  a,1
        ld  (ep_ong),a
        jr  .exitchk
.rising:
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
        ; il centro del corpo (yh + mezza altezza)
        ld  a,(ep_yh)
        ld  hl,ci_hc
        add a,(hl)
        ld  c,a
        ld  a,(ep_xh)
        add a,8
        ld  b,a
        call tile_type
        cp  2
        jr  z,.door
        cp  3
        ret nz
        ; il MOLY: raccolto (corolla e stelo)
        ld  hl,room_map+MOLY_OFF
        ld  (hl),0
        ld  hl,room_map+MOLY_OFF+32
        ld  (hl),0
        ld  hl,MOLY_OFF
        ld  (nt_qoff),hl
        xor a
        ld  (nt_qval),a
        ld  a,2
        ld  (nt_qcnt),a
        ld  a,1
        ld  (ci_moly),a
        ld  (ep_hud),a
        ld  a,2             ; il tintinnio dell'erba magica
        ld  (ep_sfx_ty),a
        ld  a,10
        ld  (ep_sfx_t),a
        ret
.door:
        ld  a,(ep_room)
        inc a
        ld  (ep_room),a
        cp  EP_NROOMS
        jr  c,.nextroom
        ld  a,1             ; fuori dal palazzo: episodio vinto
        ld  (ep_end),a
        ret
.nextroom:
        jp  ep_load_room

; lato: B=px pronto; controlla yh+4 e yh+altezza-4; Z = muro
side_solid:
        ld  a,(ep_yh)
        add a,4
        ld  c,a
        push bc
        call tile_type
        pop bc
        cp  1
        ret z
        ld  a,(ci_hh)
        sub 4
        ld  hl,ep_yh
        add a,(hl)
        ld  c,a
        call tile_type
        cp  1
        ret

; B=px, C=py -> A = tipo tile
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

; ------------------------------------------------------------
; la magia di Circe: l'incantesimo cade sulla TUA verticale
; ------------------------------------------------------------
ci_magic:
        ld  a,(ci_here)
        or  a
        ret z
        ld  a,(bolt_st)
        or  a
        jr  z,.idle
        dec a
        jr  z,.warn
        ; --- la stella cade... e INSEGUE (1px ogni 2 frame):
        ; schivarla vuole una corsa decisa; col moly in mano il
        ; colpo non punisce - TRASFORMA. La meccanica si impara
        ; venendo presi, poi si sfrutta vicino al cunicolo.
        ld  a,(frame_cnt)
        and 1
        jr  nz,.nohome
        ld  a,(ep_xh)
        ld  b,a
        ld  a,(bolt_x)
        cp  b
        jr  z,.nohome
        jr  c,.hr
        dec a
        jr  .hs
.hr:
        inc a
.hs:
        ld  (bolt_x),a
.nohome:
        ld  a,(bolt_y)
        add a,BOLT_VY
        ld  (bolt_y),a
        cp  150
        jr  c,.coll
        xor a               ; a terra: svanisce
        ld  (bolt_st),a
        ret
.coll:
        ld  a,(ep_ifr)
        or  a
        ret nz
        ld  a,(ci_pig)
        or  a
        ret nz              ; i maiali non li degna di magia
        ld  a,(bolt_x)
        ld  b,a
        ld  a,(ep_xh)
        sub b
        jp  p,.ax
        neg
.ax:
        cp  10
        ret nc
        ld  a,(ep_yh)
        ld  hl,ci_hc
        add a,(hl)
        ld  b,a
        ld  a,(bolt_y)
        add a,8
        sub b
        jp  p,.ay
        neg
.ay:
        cp  12
        ret nc
        ; COLPITO dalla magia
        xor a
        ld  (bolt_st),a
        ld  a,(ci_moly)
        or  a
        jp  z,ep_hit        ; senza moly: un compagno
        jp  to_pig          ; col moly: MAIALE - la via bassa
.warn:
        ld  hl,bolt_t
        dec (hl)
        ret nz
        ld  a,2
        ld  (bolt_st),a
        ret
.idle:
        ld  a,(ci_pig)
        or  a
        ret nz              ; mentre sei maiale, ride e basta
        ld  hl,cast_t
        dec (hl)
        ret nz
        ld  a,CI_CAST
        ld  (hl),a
        ; la mira ANTICIPA la corsa: se ti muovi, la stella cade
        ; piu' avanti nella tua direzione - correre non basta
        ld  a,(ep_mov)
        or  a
        ld  a,(ep_xh)
        jr  z,.aim
        ld  b,a
        ld  a,(ep_face)
        or  a
        ld  a,b
        jr  nz,.aiml
        add a,20
        cp  233
        jr  c,.aim
        ld  a,232
        jr  .aim
.aiml:
        sub 20
        cp  8
        jr  nc,.aim
        ld  a,8
.aim:
        ld  (bolt_x),a
        ld  a,12
        ld  (bolt_y),a
        ld  a,1
        ld  (bolt_st),a
        ld  a,WARN_T
        ld  (bolt_t),a
        ld  a,2             ; lo ZAP dell'incantesimo
        ld  (ep_sfx_ty),a
        ld  a,14
        ld  (ep_sfx_t),a
        ret

; ------------------------------------------------------------
; i LEONI ammansiti: rondano il pavimento avanti e indietro.
; Si scavalcano solo col salto; il morso costa un compagno -
; anche al maiale (le zampette corrono, ma i denti sono denti).
; ------------------------------------------------------------
ci_beasts:
        ld  a,(b0_on)
        or  a
        jr  z,.n0
        ld  a,(b0_d)
        or  a
        jr  nz,.b0l
        ld  a,(b0_x)
        inc a
        ld  (b0_x),a
        ld  hl,b0_mx
        cp  (hl)
        jr  c,.b0k
        ld  a,1
        ld  (b0_d),a
        jr  .b0k
.b0l:
        ld  a,(b0_x)
        dec a
        ld  (b0_x),a
        ld  hl,b0_mn
        cp  (hl)
        jr  nc,.b0k
        xor a
        ld  (b0_d),a
.b0k:
        ld  a,(b0_x)
        ld  b,a
        call lion_bite
.n0:
        ld  a,(b1_on)
        or  a
        ret z
        ld  a,(b1_d)
        or  a
        jr  nz,.b1l
        ld  a,(b1_x)
        inc a
        ld  (b1_x),a
        ld  hl,b1_mx
        cp  (hl)
        jr  c,.b1k
        ld  a,1
        ld  (b1_d),a
        jr  .b1k
.b1l:
        ld  a,(b1_x)
        dec a
        ld  (b1_x),a
        ld  hl,b1_mn
        cp  (hl)
        jr  nc,.b1k
        xor a
        ld  (b1_d),a
.b1k:
        ld  a,(b1_x)
        ld  b,a
        jp  lion_bite

; B = x del leone: ha azzannato? (solo coi piedi a terra bassa:
; il salto lo scavalca, uomo o maiale che sia)
lion_bite:
        ld  a,(ep_ifr)
        or  a
        ret nz
        ld  a,(ep_yh)
        ld  hl,ci_hh
        add a,(hl)          ; i piedi
        cp  144
        ret c               ; in volo: scavalcato
        ld  a,(ep_xh)
        sub b
        jp  p,.xa
        neg
.xa:
        cp  12
        ret nc
        ; AZZANNATO: compagno, spintone, iframes
        ld  a,EP_IFR
        ld  (ep_ifr),a
        ld  a,1
        ld  (ep_sfx_ty),a
        ld  a,30
        ld  (ep_sfx_t),a
        ld  a,1
        ld  (ep_hud),a
        ld  a,(ep_xh)
        cp  b
        jr  c,.pushl
        add a,12
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
        call crew_lose
        ret nz
        ld  a,2
        ld  (ep_end),a
        ret

; leoni per stanza: on, quota, x min, x max (x2)
beast_tab:
        db  1,136,40,140    ; bosco: due, a guardia del sentiero
        db  1,136,120,224
        db  1,136,112,144   ; sala: sentinella fra il muretto
        db  1,136,16,88     ; (colonna x104-111) e l'imbocco; il
                            ; secondo ronda l'anticamera sinistra
                            ; (mai dentro il tunnel: soffitto
                            ; basso = salto negato)
        db  1,136,32,56     ; porcile: ronda corta nella zona
        db  0,0,0,0         ; d'attesa (mai nel cunicolo c9+)

; la trasformazione: MAIALE (i piedi restano dove sono)
to_pig:
        ld  a,PIG_T
        ld  (ci_pig),a
        ld  a,(ep_yh)
        add a,8
        ld  (ep_yh),a
        ld  a,1
        call set_form
        ld  a,3             ; il POF della nuvola di fumo
        ld  (ep_sfx_ty),a
        ld  a,18
        ld  (ep_sfx_t),a
        ld  a,40
        ld  (ep_ifr),a
        ld  a,1
        ld  (ep_hud),a
        ret

; colpito dalla magia senza il moly: un compagno di meno
ep_hit:
        ld  a,EP_IFR
        ld  (ep_ifr),a
        ld  a,1
        ld  (ep_sfx_ty),a
        ld  a,30
        ld  (ep_sfx_t),a
        ld  a,1
        ld  (ep_hud),a
        call crew_lose
        ret nz
        ld  a,2
        ld  (ep_end),a
        ret

; ------------------------------------------------------------
; timer: iframes, il tempo da maiale (con il controllo dell'aria
; sopra la testa prima di rialzarsi), la barra HUD
; ------------------------------------------------------------
ep_timers:
        ld  a,(ep_ifr)
        or  a
        jr  z,.pig
        dec a
        ld  (ep_ifr),a
.pig:
        ld  a,(ci_pig)
        or  a
        jr  z,.bar
        dec a
        jr  nz,.keep
        ; scaduto: c'e' spazio per rialzarsi? (8px sopra la testa)
        ld  a,(ep_yh)
        sub 8
        ld  c,a
        ld  a,(ep_xh)
        add a,3
        ld  b,a
        push bc
        call tile_type
        pop bc
        cp  1
        jr  z,.stuck
        ld  a,(ep_xh)
        add a,12
        ld  b,a
        call tile_type
        cp  1
        jr  z,.stuck
        xor a               ; di nuovo UOMO
        ld  (ci_pig),a
        ld  a,(ep_yh)
        sub 8
        ld  (ep_yh),a
        xor a
        call set_form
        ld  a,3
        ld  (ep_sfx_ty),a
        ld  a,14
        ld  (ep_sfx_t),a
        jr  .bar
.stuck:
        ld  a,1             ; resta maiale finche' non c'e' aria
.keep:
        ld  (ci_pig),a
.bar:
        ; barra HUD = tempo da maiale che resta (0..7)
        ld  a,(ci_pig)
        rrca
        rrca
        rrca
        rrca
        rrca
        and 7
        ld  b,a
        ld  a,(bar_last)
        cp  b
        ret z
        ld  a,b
        ld  (bar_last),a
        ld  a,1
        ld  (ep_hud),a
        ret

; ------------------------------------------------------------
; caricamento stanza (sotto DI, schermo spento)
; ------------------------------------------------------------
ep_load_room:
        di
        ld  b,10100010b
        ld  c,1
        call WRTVDP
        di
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
        ld  l,a
        ld  a,(hl)
        ld  (ep_xh),a
        inc hl
        ld  a,(hl)
        ld  (ep_yh),a
        inc hl
        ld  a,(hl)
        ld  (ci_here),a
        push de
        ld  h,d
        ld  l,e
        ld  de,room_map
        ld  bc,768
        ldir
        pop hl
        ld  de,VR_NAME
        ld  bc,768
        call vdp_copy
        ; stato pulito
        xor a
        ld  (ep_xl),a
        ld  (ep_yl),a
        ld  (ep_vyl),a
        ld  (ep_vyh),a
        ld  (bolt_st),a
        ld  (ci_pig),a
        ld  (bar_last),a
        call set_form       ; sempre uomo all'ingresso (A=0)
        ld  a,CI_CAST
        ld  (cast_t),a
        ; i leoni di QUESTA stanza
        ld  a,(ep_room)
        add a,a
        add a,a
        add a,a
        ld  l,a
        ld  h,0
        ld  bc,beast_tab
        add hl,bc
        ld  de,b0_on
        ld  bc,8
        ldir
        ld  a,(b0_mn)
        ld  (b0_x),a
        xor a
        ld  (b0_d),a
        ld  a,(b1_mx)
        ld  (b1_x),a
        ld  a,1
        ld  (b1_d),a
        ld  a,1
        ld  (ep_hud),a
        ld  b,11100010b
        ld  c,1
        call WRTVDP
        ei
        ret

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
        call crew_reward    ; un compagno ritrovato, se ne mancano
        xor a
        ld  (phase),a
        ld  a,(leg)
        inc a
        cp  N_DESTS
        jr  c,.setleg
        xor a
        ld  (leg),a
        ld  (leg_magic),a
        ld  a,CREW0
        ld  (crew_keep),a
        jp  init
.setleg:
        ld  (leg),a
        jp  init
.lose:
        ld  a,CREW0
        ld  (crew_keep),a
        jp  init            ; phase resta 2: si ritenta

; ============================================================
;  ISR: OAM, coda NT, HUD, audio
; ============================================================
ep_isr:
        ld  a,low VR_SPRA
        out (099h),a
        ld  a,(high VR_SPRA)|40h
        out (099h),a
        ld  a,(ep_yh)
        dec a
        ld  d,a
        ld  a,(ep_ifr)
        or  a
        jr  z,.nob
        ld  a,(frame_cnt)
        and 2
        jr  z,.nob
        ld  d,209
.nob:
        ld  a,(ci_pig)
        or  a
        jp  nz,.pigoam
        ; --- Ulisse a 3 layer (slot 0-4), come a Polifemo ---
        ld  a,(ep_ong)
        or  a
        jr  nz,.gr
        ld  c,60
        jr  .face
.gr:
        ld  a,(ep_mov)
        or  a
        jr  z,.st
        ld  a,(frame_cnt)
        and 8
        jr  z,.wb
        ld  c,20
        jr  .face
.wb:
        ld  c,40
        jr  .face
.st:
        ld  c,0
        jr  .pat
.face:
        ld  a,(ep_face)
        or  a
        jr  z,.pat
        ld  a,c
        add a,60
        ld  c,a
.pat:
        ld  a,(ep_xh)
        ld  e,a
        ld  a,d
        out (098h),a
        ld  a,e
        out (098h),a
        ld  a,c
        out (098h),a
        ld  a,15
        out (098h),a
        ld  a,d
        add a,16
        out (098h),a
        ld  a,e
        out (098h),a
        ld  a,c
        add a,4
        out (098h),a
        ld  a,15
        out (098h),a
        ld  a,d
        out (098h),a
        ld  a,e
        out (098h),a
        ld  a,c
        add a,8
        out (098h),a
        ld  a,1
        out (098h),a
        ld  a,d
        out (098h),a
        ld  a,e
        out (098h),a
        ld  a,c
        add a,12
        out (098h),a
        ld  a,10
        out (098h),a
        ld  a,d
        add a,16
        out (098h),a
        ld  a,e
        out (098h),a
        ld  a,c
        add a,16
        out (098h),a
        ld  a,10
        out (098h),a
        jp  .slot5
.pigoam:
        ; --- il MAIALE: un solo sprite rosa (slot 0) ---
        ld  a,d
        out (098h),a
        ld  a,(ep_xh)
        out (098h),a
        ld  a,(ep_mov)
        or  a
        jr  z,.pidle
        ld  a,(frame_cnt)
        and 8
        jr  z,.pw1
        ld  c,144
        jr  .pf
.pw1:
        ld  c,140
        jr  .pf
.pidle:
        ld  c,140
.pf:
        ld  a,(ep_face)
        or  a
        jr  z,.pr
        ld  a,c
        add a,8
        ld  c,a
.pr:
        ld  a,c
        out (098h),a
        ld  a,9             ; rosa maialesco
        out (098h),a
        ld  e,4             ; slot 1-4 nascosti
.ph:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        out (098h),a
        out (098h),a
        dec e
        jr  nz,.ph
.slot5:
        ; --- slot 5: la stella magica (avviso o caduta) ---
        ld  a,(bolt_st)
        or  a
        jr  z,.s5h
        cp  1
        jr  nz,.sfall
        ld  a,(frame_cnt)   ; l'avviso luccica
        and 2
        jr  nz,.s5h
.sfall:
        ld  a,(bolt_y)
        dec a
        out (098h),a
        ld  a,(bolt_x)
        out (098h),a
        ld  a,(frame_cnt)
        and 4
        jr  z,.sa
        ld  a,160
        jr  .sb
.sa:
        ld  a,156
.sb:
        out (098h),a
        ld  a,13            ; magenta: la magia
        out (098h),a
        jr  .slot67
.s5h:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        out (098h),a
        out (098h),a
.slot67:
        ; --- slot 6-7: i leoni ammansiti (dorati, al trotto) ---
        ld  a,(frame_cnt)
        and 8
        jr  z,.lw1
        ld  c,168
        jr  .lw2
.lw1:
        ld  c,164
.lw2:
        ld  a,(b0_on)
        or  a
        jr  z,.l0h
        ld  a,(b0_y)
        dec a
        out (098h),a
        ld  a,(b0_x)
        out (098h),a
        ld  a,(b0_d)
        or  a
        ld  a,c
        jr  z,.l0p
        add a,8             ; verso sinistra: specchiato
.l0p:
        out (098h),a
        ld  a,10            ; criniera d'oro
        out (098h),a
        jr  .l1s
.l0h:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        out (098h),a
        out (098h),a
.l1s:
        ld  a,(b1_on)
        or  a
        jr  z,.l1h
        ld  a,(b1_y)
        dec a
        out (098h),a
        ld  a,(b1_x)
        out (098h),a
        ld  a,(b1_d)
        or  a
        ld  a,c
        jr  z,.l1p
        add a,8
.l1p:
        out (098h),a
        ld  a,10
        out (098h),a
        jr  .oamend
.l1h:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        out (098h),a
        out (098h),a
.oamend:
        ld  a,208
        out (098h),a
        ; --- coda di poke alla name table (il moly raccolto) ---
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
        ; --- HUD: ciurma, barra del tempo-maiale, moly ---
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
        ld  a,(bar_last)
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
        ; l'icona del moly
        ld  a,low (VR_NAME+STK_COL)
        out (099h),a
        ld  a,(high (VR_NAME+STK_COL))|40h
        out (099h),a
        ld  a,(ci_moly)
        or  a
        jr  z,.hs
        ld  a,MOLY_TILE
.hs:
        out (098h),a
.nohud:
        call ci_audio
        ld  hl,frame_cnt
        inc (hl)
        ret

; ------------------------------------------------------------
; audio: effetti sul canale A, il CANTO di Circe sul B
; ------------------------------------------------------------
ci_audio:
        ld  a,(ep_sfx_t)
        or  a
        jp  z,.quiet
        dec a
        ld  (ep_sfx_t),a
        ld  d,a
        ld  a,(ep_sfx_ty)
        or  a
        jr  nz,.n1
        ld  a,d             ; tonfo: SECCO, piena botta subito
        cp  8
        jr  c,.tqu
        ld  a,15
.tqu:
        ld  b,a
        ld  c,22
        jp  .out
.n1:
        dec a
        jr  nz,.n2
        ; il colpo della magia subita
        ld  a,d
        srl a
        ld  b,a
        ld  a,d
        and 3
        add a,20
        ld  c,a
        jp  .out
.n2:
        dec a
        jr  nz,.n3
        ; lo ZAP: tono che sguscia verso l'acuto
        ld  a,d
        add a,a
        add a,16
        ld  b,a
        ld  a,12
        jp  .tout
.n3:
        dec a
        jr  nz,.n4
        ; il POF: sbuffo di fumo
        ld  a,d
        srl a
        ld  b,a
        ld  a,6
        add a,d
        ld  c,a
        jp  .out
.n4:
        ; il grugnito: basso e tozzo
        ld  b,235
        ld  a,10
.tout:
        ld  c,a             ; scrittura TONO: B=periodo, C=volume
        xor a
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        ld  a,1
        out (0A0h),a
        xor a
        out (0A1h),a
        ld  a,8
        out (0A0h),a
        ld  a,c
        out (0A1h),a
        ld  a,6
        out (0A0h),a
        ld  a,1
        out (0A1h),a
        jp  .canto
.out:
        ld  a,8             ; scrittura RUMORE: B=vol, C=colore
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
        jp  .canto
.quiet:
        ld  a,8
        out (0A0h),a
        xor a
        out (0A1h),a
.canto:
        ; --- il canto di Circe: arpa che culla (canale B) ---
        ld  a,(ci_here)
        or  a
        jr  z,.coff
        ld  hl,song_t
        inc (hl)
        ld  a,(hl)
        cp  22
        jr  c,.cnote
        ld  (hl),0
        ld  hl,song_i
        ld  a,(hl)
        inc a
        and 15
        ld  (hl),a
.cnote:
        ld  a,(song_i)
        ld  hl,canto_tab
        ld  e,a
        ld  d,0
        add hl,de
        ld  a,2
        out (0A0h),a
        ld  a,(hl)
        out (0A1h),a
        ld  a,3
        out (0A0h),a
        xor a
        out (0A1h),a
        ld  a,(song_t)      ; ogni nota si spegne come pizzicata
        srl a
        srl a
        and 3
        ld  b,a
        ld  a,7
        sub b
        ld  b,a
        ld  a,9
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        ret
.coff:
        ld  a,9
        out (0A0h),a
        xor a
        out (0A1h),a
        ret

; la melodia: La minore, una ninna nanna che non rassicura
canto_tab:
        db  254,214,190,214,170,190,214,254
        db  190,170,143,170,127,143,170,190
