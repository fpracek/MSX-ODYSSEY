; ============================================================
;  BANCO 24 - L'EPISODIO DELLE SIRENE (MODULE sirene)
;  Il CANTO ATTRAE: silenzio -> voce sommessa d'avviso -> CANTO,
;  e durante il canto Ulisse e' trascinato verso la sirena piu'
;  vicina - a terra si resiste a fatica, in aria il richiamo
;  VINCE (il contrario di Eolo: qui l'aria e' la condanna).
;  LEGATO a un palo d'ormeggio (fermo, a terra, nel raggio del
;  palo) il canto non prende: ci si muove nei silenzi e ci si
;  lega prima del canto. Toccare una sirena = un compagno.
;  La CERA (stanza 3) dimezza il richiamo e accende la porta.
;  Audio: il canto e' un duetto PSG in glissando con vibrato.
; ============================================================

; ---------- costanti ----------
EP_WALK  equ 320
EP_GRAV  equ 40
EP_JUMP  equ 0340h
EP_VYMAX equ 0400h
EP_IFR   equ 90
PULL_GND equ 224        ; richiamo a terra (la camminata e' 320)
PULL_AIR equ 352        ; in aria il canto VINCE
QUIET_T  equ 150        ; base del silenzio (+rnd 0..63)
HUM_T    equ 50         ; la voce sommessa d'avviso
SONG_T   equ 140        ; il canto pieno

; ---------- RAM (pulita da ep_start) ----------
ep_room   equ 0C050h
ep_xl     equ 0C051h
ep_xh     equ 0C052h
ep_yl     equ 0C053h
ep_yh     equ 0C054h
ep_vyl    equ 0C055h
ep_vyh    equ 0C056h
ep_ong    equ 0C057h
si_st     equ 0C058h    ; 0 silenzio, 1 voce sommessa, 2 CANTO
si_t      equ 0C059h
song_p    equ 0C05Ah    ; periodo corrente della voce
song_tg   equ 0C05Bh    ; periodo bersaglio (glissando)
song_i    equ 0C05Ch    ; indice della melodia
ep_hud    equ 0C05Dh
ep_ifr    equ 0C05Eh
ep_sfx_t  equ 0C05Fh
ep_sfx_ty equ 0C060h    ; 0 tonfo, 1 colpo, 2 tintinnio cera
ep_jlatch equ 0C061h
ep_mov    equ 0C062h
ep_face   equ 0C063h
ep_end    equ 0C064h
si_note   equ 0C065h    ; contatore del passo di melodia
cera      equ 0C067h    ; la cera nelle orecchie
door_td   equ 0C068h
note_x    equ 0C069h    ; la nota che vola verso di te
note_y    equ 0C06Ah
anchored  equ 0C06Bh    ; 1 = legato all'ormeggio
m_zones   equ 0C06Ch    ; 3 zone d'ormeggio: x0,x1 (6 byte)
bar_last  equ 0C070h
nt_qoff   equ 0C071h
nt_qval   equ 0C073h
nt_qcnt   equ 0C074h
s0_on     equ 0C075h    ; le sirene della stanza (centri)
s0_x      equ 0C076h
s0_y      equ 0C077h
s1_on     equ 0C078h
s1_x      equ 0C079h
s1_y      equ 0C07Ah
pull_x    equ 0C07Bh    ; il bersaglio del richiamo (aggiornato)
room_map  equ 0C100h

; ============================================================
;  ingresso (dal kernel, quando phase=4; banchi 24/25 mappati)
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
        call si_upd
        call si_touch
        call ep_timers
        jr  ep_loop

; ------------------------------------------------------------
; input
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
; fisica: camminata, il RICHIAMO del canto, gravita'
; ------------------------------------------------------------
ep_physics:
        ld  a,(ep_mov)
        or  a
        jr  z,.pull
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
        jr  .pull
.wallr:
        add a,13
        ld  b,a
        call side_solid
        jr  nz,.pull
        ld  hl,(ep_xl)
        ld  de,-EP_WALK
        add hl,de
        ld  (ep_xl),hl
        jr  .pull
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
        jr  .pull
.walll:
        add a,2
        ld  b,a
        call side_solid
        jr  nz,.pull
        ld  hl,(ep_xl)
        ld  de,EP_WALK
        add hl,de
        ld  (ep_xl),hl
.pull:
        ; --- il RICHIAMO: durante il canto, verso la sirena ---
        xor a
        ld  (anchored),a
        ld  a,(si_st)
        cp  2
        jp  nz,.vert
        ; legato? (a terra, col centro nel raggio di un palo)
        call chk_anchor
        jr  z,.notied
        ld  a,1
        ld  (anchored),a
        jp  .vert           ; l'ormeggio TIENE
.notied:
        ; il bersaglio: la sirena piu' vicina
        call nearest_siren  ; B = x della sirena
        ld  a,b
        ld  (pull_x),a
        ld  a,(ep_xh)
        add a,8
        cp  b
        jp  z,.vert
        push af             ; carry = sirena a destra
        ld  de,PULL_AIR
        ld  a,(ep_ong)
        or  a
        jr  z,.pf
        ld  de,PULL_GND
.pf:
        ld  a,(cera)        ; la cera DIMEZZA il richiamo
        or  a
        jr  z,.pc
        srl d
        rr  e
.pc:
        pop af
        jr  c,.pright
        ; sirena a sinistra: trascinato a sinistra
        ld  hl,(ep_xl)
        or  a
        sbc hl,de
        ld  (ep_xl),hl
        ld  a,(ep_xh)
        cp  8
        jr  nc,.pl2
        ld  a,8
        ld  (ep_xh),a
        xor a
        ld  (ep_xl),a
        jp  .vert
.pl2:
        add a,2
        ld  b,a
        call side_solid
        jp  nz,.vert
        ld  hl,(ep_xl)
        add hl,de
        ld  (ep_xl),hl
        jp  .vert
.pright:
        ld  hl,(ep_xl)
        add hl,de
        ld  (ep_xl),hl
        ld  a,(ep_xh)
        cp  233
        jr  c,.pr2
        ld  a,232
        ld  (ep_xh),a
        jp  .vert
.pr2:
        add a,13
        ld  b,a
        call side_solid
        jp  nz,.vert
        ld  hl,(ep_xl)
        or  a
        sbc hl,de
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
        ld  a,(ep_yh)
        add a,12
        ld  c,a
        ld  a,(ep_xh)
        add a,8
        ld  b,a
        call tile_type
        cp  2
        jr  z,.doorx
        cp  3
        ret nz
        ; la CERA: nelle orecchie - e la porta si accendera'
        ld  hl,room_map+CERA_OFF
        ld  (hl),0
        ld  hl,room_map+CERA_OFF+32
        ld  (hl),0
        ld  hl,CERA_OFF
        ld  (nt_qoff),hl
        xor a
        ld  (nt_qval),a
        ld  a,2
        ld  (nt_qcnt),a
        ld  a,1
        ld  (cera),a
        ld  (ep_hud),a
        ld  (door_td),a
        ld  a,2
        ld  (ep_sfx_ty),a
        ld  a,12
        ld  (ep_sfx_t),a
        ret
.doorx:
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

; Z = libero, NZ = legato (a terra e nel raggio di un palo)
chk_anchor:
        ld  a,(ep_ong)
        or  a
        ret z
        ld  a,(ep_xh)
        add a,8
        ld  b,a
        ld  hl,m_zones
        ld  c,3
.mz:
        ld  a,(hl)
        inc hl
        or  a
        jr  z,.skip1
        dec a               ; x0-1 (cosi' cp b copre x0 esatto)
        cp  b
        jr  nc,.skip1
        ld  a,(hl)
        cp  b
        jr  c,.skip1
        or  a               ; NZ: preso (x1 mai 0 qui)
        ret
.skip1:
        inc hl
        dec c
        jr  nz,.mz
        xor a
        ret

; B <- x della sirena piu' vicina (attive garantite per stanza)
nearest_siren:
        ld  a,(s1_on)
        or  a
        jr  z,.only0
        ld  a,(ep_xh)
        add a,8
        ld  d,a
        ld  a,(s0_x)
        sub d
        jp  p,.a0
        neg
.a0:
        ld  e,a             ; |d0|
        ld  a,(s1_x)
        sub d
        jp  p,.a1
        neg
.a1:
        cp  e
        jr  nc,.only0
        ld  a,(s1_x)
        ld  b,a
        ret
.only0:
        ld  a,(s0_x)
        ld  b,a
        ret

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
; il ciclo del CANTO: silenzio -> voce sommessa -> canto pieno.
; La nota vola dalla sirena verso di te; la barra HUD e' la voce.
; ------------------------------------------------------------
si_upd:
        ld  hl,si_t
        dec (hl)
        jr  nz,.mel
        ld  a,(si_st)
        or  a
        jr  z,.tohum
        dec a
        jr  z,.tosong
        xor a               ; il canto tace
        ld  (si_st),a
        call rnd8
        and 63
        add a,QUIET_T
        ld  (si_t),a
        jr  .mel
.tohum:
        ld  a,1
        ld  (si_st),a
        ld  a,HUM_T
        ld  (si_t),a
        jr  .mel
.tosong:
        ld  a,2
        ld  (si_st),a
        ld  a,SONG_T
        ld  (si_t),a
        ; la nota parte dalla sirena piu' vicina
        call nearest_siren
        ld  a,b
        ld  (note_x),a
        ld  a,(s0_y)
        ld  (note_y),a
.mel:
        ; il glissando: il periodo scivola verso il bersaglio
        ld  a,(si_st)
        or  a
        jr  z,.bar
        ld  hl,si_note
        inc (hl)
        ld  a,(hl)
        cp  28
        jr  c,.slide
        ld  (hl),0
        ld  hl,song_i
        ld  a,(hl)
        inc a
        and 7
        ld  (hl),a
        ld  e,a
        ld  d,0
        ld  hl,canto_tab
        add hl,de
        ld  a,(hl)
        ld  (song_tg),a
.slide:
        ld  a,(song_tg)
        ld  b,a
        ld  a,(song_p)
        cp  b
        jr  z,.note
        jr  c,.up
        dec a
        dec a
        jr  .setp
.up:
        inc a
        inc a
.setp:
        ld  (song_p),a
.note:
        ; la nota vola verso di te (solo durante il canto)
        ld  a,(si_st)
        cp  2
        jr  nz,.bar
        ld  a,(ep_xh)
        add a,8
        ld  b,a
        ld  a,(note_x)
        cp  b
        jr  z,.ny
        jr  c,.nxr
        dec a
        dec a
        jr  .nxs
.nxr:
        inc a
        inc a
.nxs:
        ld  (note_x),a
.ny:
        ld  a,(ep_yh)
        add a,8
        ld  b,a
        ld  a,(note_y)
        cp  b
        jr  z,.bar
        jr  c,.nyd
        dec a
        jr  .nys
.nyd:
        inc a
.nys:
        ld  (note_y),a
.bar:
        ; barra HUD = la voce (0 silenzio, sale, piena nel canto)
        ld  a,(si_st)
        or  a
        jr  z,.b0
        dec a
        jr  z,.b1
        ld  a,10
        jr  .bset
.b1:
        ld  a,HUM_T
        ld  b,a
        ld  a,(si_t)
        ld  c,a
        ld  a,b
        sub c
        srl a
        srl a
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
; il tocco della sirena: un compagno divorato, e via lontano
; ------------------------------------------------------------
si_touch:
        ld  a,(ep_ifr)
        or  a
        ret nz
        ld  a,(s0_on)
        or  a
        jr  z,.n0
        ld  a,(s0_x)
        ld  b,a
        ld  a,(s0_y)
        ld  c,a
        call .chk
.n0:
        ld  a,(ep_ifr)
        or  a
        ret nz
        ld  a,(s1_on)
        or  a
        ret z
        ld  a,(s1_x)
        ld  b,a
        ld  a,(s1_y)
        ld  c,a
.chk:
        ld  a,(ep_xh)
        add a,8
        sub b
        jp  p,.xa
        neg
.xa:
        cp  18
        ret nc
        ld  a,(ep_yh)
        add a,12
        sub c
        jp  p,.ya
        neg
.ya:
        cp  20
        ret nc
        ; DIVORATO... quasi: spintone violento e un compagno
        ld  a,EP_IFR
        ld  (ep_ifr),a
        ld  a,1
        ld  (ep_sfx_ty),a
        ld  a,30
        ld  (ep_sfx_t),a
        ld  a,1
        ld  (ep_hud),a
        ld  a,(ep_xh)
        add a,8
        cp  b
        jr  c,.pushl
        ld  a,(ep_xh)
        add a,24
        cp  233
        jr  c,.px
        ld  a,232
        jr  .px
.pushl:
        ld  a,(ep_xh)
        sub 24
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

ep_timers:
        ld  a,(ep_ifr)
        or  a
        jr  z,.door
        dec a
        ld  (ep_ifr),a
.door:
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
        ld  (si_st),a
        ld  (bar_last),a
        ld  a,140
        ld  (si_t),a        ; il primo canto non tarda
        ld  a,170
        ld  (song_p),a
        ld  (song_tg),a
        ; le sirene di questa stanza
        ld  a,(ep_room)
        ld  e,a
        ld  d,0
        ld  l,a
        ld  h,0
        add hl,hl
        add hl,de
        add hl,hl           ; *6
        ld  bc,siren_tab
        add hl,bc
        ld  de,s0_on
        ld  bc,6
        ldir
        ; gli ormeggi di questa stanza
        ld  a,(ep_room)
        ld  e,a
        ld  d,0
        ld  l,a
        ld  h,0
        add hl,hl
        add hl,de
        add hl,hl           ; *6
        ld  bc,mast_tab
        add hl,bc
        ld  de,m_zones
        ld  bc,6
        ldir
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
        jp  init            ; phase resta 4: si ritenta

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
        ; --- slot 5: la NOTA che vola verso di te (canto) ---
        ld  a,(si_st)
        cp  2
        jr  nz,.s5h
        ld  a,(note_y)
        dec a
        out (098h),a
        ld  a,(note_x)
        out (098h),a
        ld  a,(frame_cnt)
        and 4
        jr  z,.na
        ld  a,160
        jr  .nb
.na:
        ld  a,156
.nb:
        out (098h),a
        ld  a,13            ; magenta: la voce fatta visibile
        out (098h),a
        jr  .s67
.s5h:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        out (098h),a
        out (098h),a
.s67:
        ld  e,2             ; slot 6-7 liberi
.s67l:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        out (098h),a
        out (098h),a
        dec e
        jr  nz,.s67l
        ld  a,208
        out (098h),a
        ; --- coda di poke alla name table (cera/porta) ---
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
        ; --- HUD ---
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
        ld  a,(cera)
        or  a
        jr  z,.hs
        ld  a,CERA_TILE
.hs:
        out (098h),a
.nohud:
        call si_audio
        ld  hl,frame_cnt
        inc (hl)
        ret

; ------------------------------------------------------------
; audio: il CANTO - duetto in glissando con vibrato. Effetti
; brevi > voce sul canale A; la voce prima resta sul B.
; ------------------------------------------------------------
si_audio:
        ; il vibrato comune
        ld  a,(frame_cnt)
        rrca
        and 3
        ld  b,a             ; 0..3
        ld  a,(song_p)
        add a,b
        ld  c,a             ; periodo voce 1 (vibrato)
        ld  a,(ep_sfx_t)
        or  a
        jp  z,.voice2
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
        ld  e,22
        jp  .outn
.n1:
        dec a
        jr  nz,.n2
        ld  a,d             ; il colpo
        srl a
        ld  b,a
        ld  a,d
        and 3
        add a,20
        ld  e,a
        jp  .outn
.n2:
        ; il tintinnio della cera
        ld  a,d
        add a,a
        add a,14
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
        ld  a,12
        out (0A1h),a
        ld  a,6
        out (0A0h),a
        ld  a,1
        out (0A1h),a
        jp  .voice1
.outn:
        ld  a,8
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        ld  a,6
        out (0A0h),a
        ld  a,e
        out (0A1h),a
        xor a
        out (0A0h),a
        ld  a,1
        out (0A1h),a
        jp  .voice1
.voice2:
        ; --- voce seconda (canale A): solo nel canto pieno,
        ;     una quarta sotto (periodo + un quarto) ---
        ld  a,(si_st)
        cp  2
        jr  nz,.v2off
        ld  a,c
        srl a
        srl a
        add a,c             ; p * 1.25
        ld  e,a
        xor a
        out (0A0h),a
        ld  a,e
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
        ld  a,1
        out (0A1h),a
        jr  .voice1
.v2off:
        ld  a,8
        out (0A0h),a
        xor a
        out (0A1h),a
.voice1:
        ; --- voce prima (canale B): sommessa nell'avviso,
        ;     piena nel canto ---
        ld  a,(si_st)
        or  a
        jr  z,.voff
        ld  a,2
        out (0A0h),a
        ld  a,c
        out (0A1h),a
        ld  a,3
        out (0A0h),a
        xor a
        out (0A1h),a
        ld  a,(si_st)
        dec a
        jr  z,.vsoft
        ld  b,11
        jr  .vset
.vsoft:
        ld  b,5
.vset:
        ld  a,9
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        ret
.voff:
        ld  a,9
        out (0A0h),a
        xor a
        out (0A1h),a
        ret

; la melodia del canto: scivola di nota in nota (periodi AY)
canto_tab:
        db  170,143,160,127,150,170,190,160
