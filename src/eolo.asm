; ============================================================
;  BANCO 22 - L'EPISODIO DI EOLO (MODULE eolo)
;  L'isola volante dalle mura di bronzo. La meccanica firma e'
;  il RESPIRO di Eolo: calma -> sibilo d'avviso -> RAFFICA che
;  spinge (piena in volo, mezza coi piedi a terra), col verso
;  che si alterna a ogni ciclo. La piuma in volo e la barra HUD
;  telegrafano il fiato. Nel CAMINO segnato dalle piume la
;  raffica SOLLEVA: si cavalca il vento verso l'alto sterzando
;  in volo. Nella sala, l'OTRE dei venti accende la porta.
;  Motore: fisica del modello Polifemo (corpo 24px fisso).
; ============================================================

; ---------- costanti ----------
EP_WALK  equ 320
EP_GRAV  equ 40
EP_JUMP  equ 0340h
EP_VYMAX equ 0400h
EP_IFR   equ 90
PUSH_AIR equ 160        ; spinta della raffica in volo (8.8)
PUSH_GND equ 64         ; coi piedi a terra: mezza
LIFT     equ 56         ; risalita netta nel camino (oltre la g)
UPCAP    equ -0200h     ; tetto di risalita: 2 px/frame
WARN_T   equ 45         ; frame di sibilo d'avviso
GUST_T   equ 110        ; frame di raffica

; ---------- RAM (pulita da ep_start) ----------
ep_room   equ 0C050h
ep_xl     equ 0C051h
ep_xh     equ 0C052h
ep_yl     equ 0C053h
ep_yh     equ 0C054h
ep_vyl    equ 0C055h
ep_vyh    equ 0C056h
ep_ong    equ 0C057h
we_st     equ 0C058h    ; 0 calma, 1 sibilo, 2 RAFFICA
we_t      equ 0C059h
we_dir    equ 0C05Ah    ; 0 = verso destra, 1 = verso sinistra
lf_x      equ 0C05Bh    ; la piuma in volo
ep_hud    equ 0C05Dh
ep_ifr    equ 0C05Eh
ep_sfx_t  equ 0C05Fh
ep_sfx_ty equ 0C060h    ; 0 tonfo, 1 colpo, 2 tintinnio otre
ep_jlatch equ 0C061h
ep_mov    equ 0C062h
ep_face   equ 0C063h
ep_end    equ 0C064h    ; 1 vittoria, 2 sconfitta
ci_here   equ 0C065h    ; Eolo e' in questa stanza (drone dei corni)
otre      equ 0C067h    ; l'otre dei venti in mano
door_td   equ 0C068h    ; porta da accendere (coda NT occupata)
drone_i   equ 0C069h
drone_t   equ 0C06Ah
up_x0     equ 0C06Bh    ; il camino ascensionale (0 = niente)
up_x1     equ 0C06Ch
wp_air    equ 0C06Dh    ; spinta della stanza: in volo
wp_gnd    equ 0C06Eh    ; ...e a terra
wp_gt     equ 0C06Fh    ; durata della raffica
bar_last  equ 0C070h
nt_qoff   equ 0C071h
nt_qval   equ 0C073h
nt_qcnt   equ 0C074h
; gli uccelli dei venti (come i leoni di Circe: on,y,mn,mx + x,d)
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
;  ingresso (dal kernel, quando phase=3; banchi 22/23 mappati)
; ============================================================
ep_start:
        di
        ld  hl,ep_room
        ld  de,ep_room+1
        ld  bc,0C400h-ep_room-1
        ld  (hl),0
        ldir
        ld  b,10100010b
        ld  c,1
        call WRTVDP
        di
        ; sprite: Ulisse 35 + uccello 4 + piuma 2 = 41
        ld  hl,ep_sprites
        ld  de,VR_SPRP
        ld  bc,41*32
        call vdp_copy
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
        ld  a,(crew_keep)
        or  a
        jr  z,.cdef
        cp  CREW0+1
        jr  c,.cok
.cdef:
        ld  a,CREW0
.cok:
        ld  (crew),a
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
        call we_upd
        call ci_beasts
        call ep_timers
        jr  ep_loop

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
        ld  hl,-EP_JUMP
        ld  (ep_vyl),hl
        xor a
        ld  (ep_ong),a
        ret

; ------------------------------------------------------------
; fisica: camminata, RAFFICA che spinge, gravita' e CAMINO
; ------------------------------------------------------------
ep_physics:
        ld  a,(ep_mov)
        or  a
        jr  z,.wind
        cp  1
        jr  nz,.left
        ld  hl,(ep_xl)
        ld  de,EP_WALK
        add hl,de
        ld  (ep_xl),hl
        ld  a,(ep_xh)
        cp  233
        jr  c,.wallr
        ld  a,232
        ld  (ep_xh),a
        jr  .wind
.wallr:
        add a,13
        ld  b,a
        call side_solid
        jr  nz,.wind
        ld  hl,(ep_xl)
        ld  de,-EP_WALK
        add hl,de
        ld  (ep_xl),hl
        jr  .wind
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
        jr  .wind
.walll:
        add a,2
        ld  b,a
        call side_solid
        jr  nz,.wind
        ld  hl,(ep_xl)
        ld  de,EP_WALK
        add hl,de
        ld  (ep_xl),hl
.wind:
        ; --- il RESPIRO: la raffica spinge (piena in volo);
        ;     la forza e' della STANZA (nella sala e' tempesta) ---
        ld  a,(we_st)
        cp  2
        jp  nz,.vert
        ld  a,(wp_air)
        ld  e,a
        ld  d,0
        ld  a,(ep_ong)
        or  a
        jr  z,.wf
        ld  a,(wp_gnd)
        ld  e,a
.wf:
        ld  a,(we_dir)
        or  a
        jr  nz,.wleft
        ld  hl,(ep_xl)
        add hl,de
        ld  (ep_xl),hl
        ld  a,(ep_xh)
        cp  233
        jr  c,.wr2
        ld  a,232
        ld  (ep_xh),a
        jr  .vert
.wr2:
        add a,13
        ld  b,a
        call side_solid
        jr  nz,.vert
        ld  hl,(ep_xl)
        or  a
        sbc hl,de
        ld  (ep_xl),hl
        jr  .vert
.wleft:
        ld  hl,(ep_xl)
        or  a
        sbc hl,de
        ld  (ep_xl),hl
        ld  a,(ep_xh)
        cp  8
        jr  nc,.wl2
        ld  a,8
        ld  (ep_xh),a
        xor a
        ld  (ep_xl),a
        jr  .vert
.wl2:
        add a,2
        ld  b,a
        call side_solid
        jr  nz,.vert
        ld  hl,(ep_xl)
        add hl,de
        ld  (ep_xl),hl
.vert:
        ld  hl,(ep_vyl)
        ld  de,EP_GRAV
        add hl,de
        bit 7,h
        jr  nz,.vok
        ld  a,h
        cp  high EP_VYMAX
        jr  c,.vok
        ld  hl,EP_VYMAX
.vok:
        ; --- il CAMINO: durante la raffica, il vento solleva ---
        ld  a,(we_st)
        cp  2
        jr  nz,.noup
        ld  a,(up_x0)
        or  a
        jr  z,.noup
        ld  b,a
        ld  a,(ep_xh)
        add a,8
        cp  b
        jr  c,.noup
        ld  b,a
        ld  a,(up_x1)
        cp  b
        jr  c,.noup
        ld  de,-LIFT-EP_GRAV
        add hl,de
        bit 7,h
        jr  z,.noup
        ld  a,h
        cp  high (UPCAP & 0FFFFh)
        jr  nc,.noup
        ld  hl,UPCAP
.noup:
        ld  (ep_vyl),hl
        ld  de,(ep_yl)
        add hl,de
        ld  (ep_yl),hl
        ld  a,(ep_vyh)
        bit 7,a
        jr  nz,.rising
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
        xor a
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
        ld  a,(ep_vyh)
        cp  2
        jr  c,.still
        ld  a,0
        ld  (ep_sfx_ty),a
        ld  a,8
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
        ; l'OTRE dei venti: raccolto - e la porta si accendera'
        ld  hl,room_map+OTRE_OFF
        ld  (hl),0
        ld  hl,room_map+OTRE_OFF+32
        ld  (hl),0
        ld  hl,OTRE_OFF
        ld  (nt_qoff),hl
        xor a
        ld  (nt_qval),a
        ld  a,2
        ld  (nt_qcnt),a
        ld  a,1
        ld  (otre),a
        ld  (ep_hud),a
        ld  (door_td),a     ; la porta si accende appena la coda
        ld  a,2             ; NT e' libera (vedi ep_timers)
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
        ld  a,1
        ld  (ep_end),a
        ret
.nextroom:
        jp  ep_load_room

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
; il RESPIRO di Eolo: calma -> sibilo -> raffica, verso alterno.
; La piuma vola col vento; la barra HUD mostra il fiato.
; ------------------------------------------------------------
we_upd:
        ld  hl,we_t
        dec (hl)
        jr  nz,.leaf
        ld  a,(we_st)
        or  a
        jr  z,.towarn
        dec a
        jr  z,.togust
        xor a               ; fine raffica: torna la calma
        ld  (we_st),a
        call rnd8
        and 63
        add a,90
        ld  (we_t),a
        jr  .leaf
.towarn:
        ld  a,1
        ld  (we_st),a
        ld  a,WARN_T
        ld  (we_t),a
        ld  a,(we_dir)      ; il respiro cambia verso a ogni ciclo
        xor 1
        ld  (we_dir),a
        jr  .leaf
.togust:
        ld  a,2
        ld  (we_st),a
        ld  a,(wp_gt)
        ld  (we_t),a
.leaf:
        ; la piuma vola nel verso del vento
        ld  a,(we_st)
        or  a
        jr  z,.bar
        ld  a,(we_dir)
        or  a
        ld  a,(lf_x)
        jr  nz,.ll
        add a,4
        jr  .ls
.ll:
        sub 4
.ls:
        ld  (lf_x),a
.bar:
        ; barra HUD = il fiato di Eolo (0 calma, sale col sibilo,
        ; piena in raffica)
        ld  a,(we_st)
        or  a
        jr  z,.b0
        dec a
        jr  z,.b1
        ld  a,10
        jr  .bset
.b1:
        ld  a,WARN_T
        ld  b,a
        ld  a,(we_t)
        ld  c,a
        ld  a,b
        sub c               ; trascorso del sibilo 0..45
        srl a
        srl a               ; 0..11
        cp  10
        jr  c,.bset
        ld  a,9
        jr  .bset
.b0:
        xor a
.bset:
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
; gli uccelli dei venti: pattuglie orizzontali, si scavalcano
; col salto; il morso costa un compagno (tramite crew_lose)
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
        ld  a,(b0_y)
        ld  c,a
        call bird_bite
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
        ld  a,(b1_y)
        ld  c,a
        jp  bird_bite

; B = x, C = quota dell'uccello: ha beccato?
bird_bite:
        ld  a,(ep_ifr)
        or  a
        ret nz
        ld  a,(ep_yh)
        add a,8
        sub c
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

; uccelli per stanza: on, quota, x min, x max (x2)
beast_tab:
        db  1,100,128,232   ; pendici: sull'ultimo tratto
        db  0,0,0,0
        db  1,104,32,208    ; camino: attraversa il volo
        db  0,0,0,0
        db  1,56,24,72      ; sala: in quota presso il banco...
        db  1,108,32,136    ; ...e sulla via del tuffo

; il vento per stanza: spinta in volo, a terra, durata raffica
winds_tab:
        db  160,64,110      ; pendici: la brezza che insegna
        db  160,64,120      ; camino: il soffio che solleva
        db  224,96,140      ; sala: la TEMPESTA del re

ep_timers:
        ld  a,(ep_ifr)
        or  a
        jr  z,.door
        dec a
        ld  (ep_ifr),a
.door:
        ; la porta della sala si accende appena la coda NT libera
        ld  a,(door_td)
        or  a
        ret z
        ld  a,(nt_qcnt)
        or  a
        ret nz
        xor a
        ld  (door_td),a
        ld  hl,room_map+DARK_OFF
        ld  (hl),7
        ld  hl,DARK_OFF
        ld  (nt_qoff),hl
        ld  a,7
        ld  (nt_qval),a
        ld  a,1
        ld  (nt_qcnt),a
        ret

; ------------------------------------------------------------
; caricamento stanza
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
        xor a
        ld  (ep_xl),a
        ld  (ep_yl),a
        ld  (ep_vyl),a
        ld  (ep_vyh),a
        ld  (we_st),a
        ld  (bar_last),a
        ld  a,120           ; il primo respiro arriva presto
        ld  (we_t),a
        ; il camino di questa stanza
        ld  a,(ep_room)
        add a,a
        ld  l,a
        ld  h,0
        ld  bc,updraft_tab
        add hl,bc
        ld  a,(hl)
        ld  (up_x0),a
        inc hl
        ld  a,(hl)
        ld  (up_x1),a
        ; il vento di questa stanza
        ld  a,(ep_room)
        ld  e,a
        ld  d,0
        ld  l,a
        ld  h,0
        add hl,hl
        add hl,de           ; *3
        ld  bc,winds_tab
        add hl,bc
        ld  a,(hl)
        ld  (wp_air),a
        inc hl
        ld  a,(hl)
        ld  (wp_gnd),a
        inc hl
        ld  a,(hl)
        ld  (wp_gt),a
        ; gli uccelli di questa stanza
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
; fine episodio
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
        jp  init            ; phase resta 3: si ritenta

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
        ; --- slot 5: la piuma nel vento (sibilo e raffica) ---
        ld  a,(we_st)
        or  a
        jr  z,.s5h
        ld  a,39            ; quota fissa, alta
        out (098h),a
        ld  a,(lf_x)
        out (098h),a
        ld  a,(frame_cnt)
        and 4
        jr  z,.la
        ld  a,160
        jr  .lb
.la:
        ld  a,156
.lb:
        out (098h),a
        ld  a,15
        out (098h),a
        jr  .birds
.s5h:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        out (098h),a
        out (098h),a
.birds:
        ; --- slot 6-7: gli uccelli dei venti ---
        ld  a,(frame_cnt)
        and 8
        jr  z,.bw1
        ld  c,144
        jr  .bw2
.bw1:
        ld  c,140
.bw2:
        ld  a,(b0_on)
        or  a
        jr  z,.b0h
        ld  a,(b0_y)
        dec a
        out (098h),a
        ld  a,(b0_x)
        out (098h),a
        ld  a,(b0_d)
        or  a
        ld  a,c
        jr  z,.b0p
        add a,8
.b0p:
        out (098h),a
        ld  a,15
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
        ld  a,(b1_on)
        or  a
        jr  z,.b1h
        ld  a,(b1_y)
        dec a
        out (098h),a
        ld  a,(b1_x)
        out (098h),a
        ld  a,(b1_d)
        or  a
        ld  a,c
        jr  z,.b1p
        add a,8
.b1p:
        out (098h),a
        ld  a,15
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
        ; --- coda di poke alla name table (otre/porta) ---
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
        ; --- HUD: ciurma, il fiato di Eolo, l'otre ---
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
        ld  a,low (VR_NAME+STK_COL)
        out (099h),a
        ld  a,(high (VR_NAME+STK_COL))|40h
        out (099h),a
        ld  a,(otre)
        or  a
        jr  z,.hs
        ld  a,OTRE_TILE
.hs:
        out (098h),a
.nohud:
        call eo_audio
        ld  hl,frame_cnt
        inc (hl)
        ret

; ------------------------------------------------------------
; audio: effetti brevi > vento (canale A); corni di Eolo sul B
; ------------------------------------------------------------
eo_audio:
        ld  a,(ep_sfx_t)
        or  a
        jp  z,.wind
        dec a
        ld  (ep_sfx_t),a
        ld  d,a
        ld  a,(ep_sfx_ty)
        or  a
        jr  nz,.n1
        ld  b,10            ; tonfo
        ld  c,12
        jp  .out
.n1:
        dec a
        jr  nz,.n2
        ld  a,d             ; il colpo del becco
        srl a
        ld  b,a
        ld  a,d
        and 3
        add a,20
        ld  c,a
        jp  .out
.n2:
        ; il tintinnio dell'otre: tono brillante che sale
        ld  a,d
        add a,a
        add a,14
        ld  b,a
        ld  c,12
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
        jp  .drone
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
        jp  .drone
.wind:
        ; --- il vento: sibilo che sale, poi la raffica ruvida ---
        ld  a,(we_st)
        or  a
        jr  z,.wq
        dec a
        jr  z,.whistle
        ; raffica: rumore pieno che sfarfalla
        ld  a,8
        out (0A0h),a
        ld  a,(frame_cnt)
        and 1
        add a,11
        out (0A1h),a
        ld  a,6
        out (0A0h),a
        ld  a,(frame_cnt)
        rrca
        and 7
        add a,10
        out (0A1h),a
        xor a
        out (0A0h),a
        ld  a,1
        out (0A1h),a
        jr  .drone
.whistle:
        ; sibilo: tono che sale mentre il fiato cresce
        ld  a,(we_t)
        add a,50            ; periodo 95 -> 50 (sale)
        ld  b,a
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
        ld  a,9
        out (0A1h),a
        ld  a,6
        out (0A0h),a
        ld  a,2
        out (0A1h),a
        jr  .drone
.wq:
        ld  a,8
        out (0A0h),a
        xor a
        out (0A1h),a
.drone:
        ; --- i corni di bronzo (solo nella sala del re) ---
        ld  a,(ci_here)
        or  a
        jr  z,.doff
        ld  hl,drone_t
        inc (hl)
        ld  a,(hl)
        cp  40
        jr  c,.dnote
        ld  (hl),0
        ld  hl,drone_i
        ld  a,(hl)
        xor 1
        ld  (hl),a
.dnote:
        ld  a,(drone_i)
        or  a
        jr  z,.dA
        ld  bc,02FBh        ; MI2
        jr  .dw
.dA:
        ld  bc,03F9h        ; LA1
.dw:
        ld  a,2
        out (0A0h),a
        ld  a,c
        out (0A1h),a
        ld  a,3
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        ld  a,9
        out (0A0h),a
        ld  a,5
        out (0A1h),a
        ret
.doff:
        ld  a,9
        out (0A0h),a
        xor a
        out (0A1h),a
        ret
