; ============================================================
;  BANCO 26 - ITACA: IL FINALE (MODULE itaca)
;  Il megaron dei Proci (niente armi: si schiva), la PROVA
;  DELL'ARCO (con l'arco, DA FERMO, FIRE scaglia la freccia
;  attraverso le scuri: la porta si apre), e la STRAGE: porte
;  sbarrate, i Proci caricano a ondate - cinque in tutto -
;  e l'arco li abbatte. L'ultimo caduto compie il viaggio.
;  FIRE in movimento resta il salto; da fermo, con l'arco, tira.
; ============================================================

; ---------- costanti ----------
EP_WALK  equ 320
EP_GRAV  equ 40
EP_JUMP  equ 0340h
EP_VYMAX equ 0400h
EP_IFR   equ 90
ARR_SPD  equ 4          ; la freccia: 4 px/frame
PROCI_N  equ 5          ; i Proci della strage

; ---------- RAM (pulita da ep_start) ----------
ep_room   equ 0C050h
ep_xl     equ 0C051h
ep_xh     equ 0C052h
ep_yl     equ 0C053h
ep_yh     equ 0C054h
ep_vyl    equ 0C055h
ep_vyh    equ 0C056h
ep_ong    equ 0C057h
arr_on    equ 0C058h    ; la freccia in volo
arr_x     equ 0C059h
arr_y     equ 0C05Ah
arr_d     equ 0C05Bh    ; 0 = verso destra, 1 = sinistra
ep_hud    equ 0C05Dh
ep_ifr    equ 0C05Eh
ep_sfx_t  equ 0C05Fh
ep_sfx_ty equ 0C060h    ; 0 tonfo, 1 colpo, 2 porta, 3 TWANG,
                        ; 4 il grido del Proco
ep_jlatch equ 0C061h
ep_mov    equ 0C062h
ep_face   equ 0C063h
ep_end    equ 0C064h
lyre_i    equ 0C065h    ; la lira di casa
lyre_t    equ 0C066h
arco      equ 0C067h    ; l'arco di Ulisse in mano
door_td   equ 0C068h
dead      equ 0C069h    ; Proci abbattuti (strage)
spawn_t   equ 0C06Ah
door_off  equ 0C06Bh    ; dw: offset NT della porta di stanza
charge_f  equ 0C06Dh    ; 1 = i Proci avanzano (carica a scatti)
bar_last  equ 0C070h
nt_qoff   equ 0C071h
nt_qval   equ 0C073h
nt_qcnt   equ 0C074h
; i PROCI (ronda nel megaron, carica nella strage)
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
;  ingresso (dal kernel, quando phase=5; banchi 26/27 mappati)
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
        ld  bc,43*32
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
        ld  a,7             ; toni A+B, rumore su A
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
        call it_arrow
        call it_proci
        call ep_timers
        jr  ep_loop

; ------------------------------------------------------------
; input: sinistra/destra; FIRE = salto, ma DA FERMO con l'arco
; in mano scaglia la FRECCIA nella direzione dello sguardo
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
        ld  a,(arco)
        or  a
        jr  z,.jump
        ld  a,(ep_room)     ; a casa l'arco si abbassa: al talamo
        cp  3               ; non si tira piu'
        jr  z,.jump
        ld  a,(ep_mov)
        or  a
        jr  nz,.jump
        ld  a,(ep_ong)
        or  a
        jr  z,.jump
        ; il TIRO: da fermo, a terra, con l'arco
        ld  a,(arr_on)
        or  a
        ret nz              ; una freccia alla volta
        ld  a,1
        ld  (arr_on),a
        ld  a,(ep_face)
        ld  (arr_d),a
        ld  a,(ep_yh)
        add a,8
        ld  (arr_y),a
        ld  a,(ep_xh)
        ld  (arr_x),a
        ld  a,3             ; il TWANG della corda
        ld  (ep_sfx_ty),a
        ld  a,10
        ld  (ep_sfx_t),a
        ret
.jump:
        ld  a,(ep_ong)
        or  a
        ret z
        ld  hl,-EP_JUMP
        ld  (ep_vyl),hl
        xor a
        ld  (ep_ong),a
        ret

; ------------------------------------------------------------
; fisica (modello Polifemo, corpo 24px)
; ------------------------------------------------------------
ep_physics:
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
        ld  a,232
        ld  (ep_xh),a
        jr  .vert
.wallr:
        add a,13
        ld  b,a
        call side_solid
        jr  nz,.vert
        ld  hl,(ep_xl)
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
        jr  nz,.vert
        ld  hl,(ep_xl)
        ld  de,EP_WALK
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
        ; l'ARCO: finalmente in mano
        ld  hl,room_map+ARCO_OFF
        ld  (hl),0
        ld  hl,room_map+ARCO_OFF+32
        ld  (hl),0
        ld  hl,ARCO_OFF
        ld  (nt_qoff),hl
        xor a
        ld  (nt_qval),a
        ld  a,2
        ld  (nt_qcnt),a
        ld  a,1
        ld  (arco),a
        ld  (ep_hud),a
        ld  a,2             ; il legno che canta gia' in mano
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
; la FRECCIA: vola dritta, si spezza sui muri, abbatte i Proci;
; nella sala dell'arco, superate le scuri, apre la porta
; ------------------------------------------------------------
it_arrow:
        ld  a,(arr_on)
        or  a
        ret z
        ld  a,(arr_d)
        or  a
        ld  a,(arr_x)
        jr  nz,.fly_l
        add a,ARR_SPD
        cp  240
        jr  nc,.offr
        jr  .flew
.fly_l:
        sub ARR_SPD
        cp  8
        jp  c,.off
.flew:
        ld  (arr_x),a
        ; contro un muro?
        add a,8
        ld  b,a
        ld  a,(arr_y)
        add a,8
        ld  c,a
        call tile_type
        cp  1
        jp  z,.off
        ; contro un Proco? (solo nella strage)
        ld  a,(ep_room)
        cp  2
        ret nz
        ld  a,(b0_on)
        or  a
        jr  z,.n0
        ld  a,(b0_x)
        ld  b,a
        call .hit
        jr  nc,.n0
        xor a
        ld  (b0_on),a
        jr  .kill
.n0:
        ld  a,(b1_on)
        or  a
        ret z
        ld  a,(b1_x)
        ld  b,a
        call .hit
        ret nc
        xor a
        ld  (b1_on),a
.kill:
        xor a
        ld  (arr_on),a
        ld  hl,dead
        inc (hl)
        ld  a,60
        ld  (spawn_t),a
        ld  a,4             ; il grido del Proco che cade
        ld  (ep_sfx_ty),a
        ld  a,25
        ld  (ep_sfx_t),a
        ld  a,1
        ld  (ep_hud),a
        ld  a,(dead)
        cp  PROCI_N
        ret c
        ld  a,1             ; l'ultimo: la porta si apre
        ld  (door_td),a
        ld  a,2
        ld  (ep_sfx_ty),a
        ld  a,16
        ld  (ep_sfx_t),a
        ret
.offr:
        ; volata oltre il bordo destro: nella sala dell'arco,
        ; a quota di tiro, e' la PROVA SUPERATA
        xor a
        ld  (arr_on),a
        ld  a,(ep_room)
        cp  1
        ret nz
        ld  a,(door_td)
        or  a
        ret nz
        ld  hl,room_map+DARK1_OFF
        ld  a,(hl)
        cp  7
        ret z               ; gia' aperta
        ld  a,1
        ld  (door_td),a
        ld  a,2             ; la porta della prova
        ld  (ep_sfx_ty),a
        ld  a,16
        ld  (ep_sfx_t),a
        ret
.off:
        xor a
        ld  (arr_on),a
        ret
.hit:
        ; B = x del Proco: C set = colpito
        ld  a,(arr_x)
        sub b
        jp  p,.ha
        neg
.ha:
        cp  10
        jr  nc,.miss
        ld  a,(arr_y)
        cp  130             ; solo ad altezza d'uomo
        jr  c,.miss
        scf
        ret
.miss:
        or  a
        ret

; ------------------------------------------------------------
; i PROCI: ronda nel megaron (invulnerabili: non hai armi),
; CARICA nella strage - corrono verso di te, l'arco li ferma.
; Il tocco costa un compagno (crew_lose: RENZO veglia comunque)
; ------------------------------------------------------------
it_proci:
        ld  a,(ep_room)
        cp  2
        jr  z,.strage
        ; --- ronda (megaron) ---
        ld  a,(b0_on)
        or  a
        jr  z,.p0done
        ld  a,(b0_d)
        or  a
        jr  nz,.p0l
        ld  a,(b0_x)
        inc a
        ld  (b0_x),a
        ld  hl,b0_mx
        cp  (hl)
        jr  c,.p0k
        ld  a,1
        ld  (b0_d),a
        jr  .p0k
.p0l:
        ld  a,(b0_x)
        dec a
        ld  (b0_x),a
        ld  hl,b0_mn
        cp  (hl)
        jr  nc,.p0k
        xor a
        ld  (b0_d),a
.p0k:
        ld  a,(b0_x)
        ld  b,a
        call proco_bite
.p0done:
        ld  a,(b1_on)
        or  a
        ret z
        ld  a,(b1_d)
        or  a
        jr  nz,.p1l
        ld  a,(b1_x)
        inc a
        ld  (b1_x),a
        ld  hl,b1_mx
        cp  (hl)
        jr  c,.p1k
        ld  a,1
        ld  (b1_d),a
        jr  .p1k
.p1l:
        ld  a,(b1_x)
        dec a
        ld  (b1_x),a
        ld  hl,b1_mn
        cp  (hl)
        jr  nc,.p1k
        xor a
        ld  (b1_d),a
.p1k:
        ld  a,(b1_x)
        ld  b,a
        jp  proco_bite
.strage:
        ; --- la carica A SCATTI: 40 frame d'assalto, 24 di
        ; spavalderia ferma - le pause sono le finestre di tiro ---
        ld  a,(frame_cnt)
        and 63
        cp  40
        ld  a,1
        jr  c,.chset
        xor a
.chset:
        ld  (charge_f),a
        ld  a,(b0_on)
        or  a
        jr  z,.s0done
        ld  a,(charge_f)
        or  a
        jr  z,.s0c          ; in pausa: niente passo, morso attivo
        ld  a,(ep_xh)
        ld  b,a
        ld  a,(b0_x)
        cp  b
        jr  z,.s0c
        jr  c,.s0r
        dec a
        ld  (b0_x),a
        ld  a,1
        ld  (b0_d),a
        jr  .s0c
.s0r:
        inc a
        ld  (b0_x),a
        xor a
        ld  (b0_d),a
.s0c:
        ld  a,(b0_x)
        ld  b,a
        call proco_bite
        jr  nc,.s0done
        ; il colpo e' andato: si ritrae, pavoneggiandosi
        ld  a,(ep_xh)
        ld  b,a
        ld  a,(b0_x)
        cp  b
        jr  c,.s0bl
        add a,48
        cp  225
        jr  c,.s0bs
        ld  a,224
        jr  .s0bs
.s0bl:
        sub 48
        cp  16
        jr  nc,.s0bs
        ld  a,16
.s0bs:
        ld  (b0_x),a
.s0done:
        ld  a,(b1_on)
        or  a
        jr  z,.respawn
        ld  a,(charge_f)
        or  a
        jr  z,.s1c
        ld  a,(ep_xh)
        ld  b,a
        ld  a,(b1_x)
        cp  b
        jr  z,.s1c
        jr  c,.s1r
        dec a
        ld  (b1_x),a
        ld  a,1
        ld  (b1_d),a
        jr  .s1c
.s1r:
        inc a
        ld  (b1_x),a
        xor a
        ld  (b1_d),a
.s1c:
        ld  a,(b1_x)
        ld  b,a
        call proco_bite
        jr  nc,.respawn
        ld  a,(ep_xh)
        ld  b,a
        ld  a,(b1_x)
        cp  b
        jr  c,.s1bl
        add a,48
        cp  225
        jr  c,.s1bs
        ld  a,224
        jr  .s1bs
.s1bl:
        sub 48
        cp  16
        jr  nc,.s1bs
        ld  a,16
.s1bs:
        ld  (b1_x),a
.respawn:
        ; entra il prossimo, se la sala non e' vuota di vivi
        ld  a,(b0_on)
        ld  b,a
        ld  a,(b1_on)
        add a,b             ; vivi
        cp  2
        ret nc              ; gia' in due
        ld  b,a
        ld  a,(dead)
        add a,b
        cp  PROCI_N
        ret nc              ; non ne restano
        ld  hl,spawn_t
        dec (hl)
        ret nz
        ld  (hl),60
        ; entra dal lato lontano da Ulisse
        ld  a,(ep_xh)
        cp  120
        ld  c,224
        jr  c,.side
        ld  c,16
.side:
        ld  a,(b0_on)
        or  a
        jr  z,.sp0
        ld  a,1
        ld  (b1_on),a
        ld  a,c
        ld  (b1_x),a
        ret
.sp0:
        ld  a,1
        ld  (b0_on),a
        ld  a,c
        ld  (b0_x),a
        ret

; B = x del Proco: ha agguantato? (piedi bassi e |dx| < 12)
; Carry = morso avvenuto (il chiamante fa ritrarre il Proco)
proco_bite:
        ld  a,(ep_ifr)
        or  a
        jr  nz,.no
        ld  a,(ep_yh)
        add a,24
        cp  144
        jr  c,.no           ; in volo: scavalcato
        ld  a,(ep_xh)
        sub b
        jp  p,.xa
        neg
.xa:
        cp  12
        jr  nc,.no
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
        add a,16
        cp  233
        jr  c,.px
        ld  a,232
        jr  .px
.pushl:
        sub 16
        cp  8
        jr  nc,.px
        ld  a,8
.px:
        ld  (ep_xh),a
        call crew_lose
        jr  z,.dead2
        scf
        ret
.dead2:
        ld  a,2
        ld  (ep_end),a
        scf
        ret
.no:
        or  a               ; niente morso: carry pulito
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
        ld  hl,(door_off)
        ld  de,room_map
        add hl,de
        ld  (hl),7
        ld  hl,(door_off)
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
        ld  (arr_on),a
        ld  (dead),a
        ld  (bar_last),a
        ld  a,60
        ld  (spawn_t),a
        ; la porta di questa stanza
        ld  hl,0
        ld  a,(ep_room)
        cp  1
        jr  nz,.d2
        ld  hl,DARK1_OFF
        jr  .dset
.d2:
        cp  2
        jr  nz,.dset
        ld  hl,DARK2_OFF
.dset:
        ld  (door_off),hl
        ; i Proci di questa stanza
        ld  a,(ep_room)
        add a,a
        add a,a
        add a,a
        ld  l,a
        ld  h,0
        ld  bc,proci_tab
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
        ld  a,(ep_room)     ; al talamo: le campane della festa
        cp  3
        jr  nz,.nofesta
        ld  a,2
        ld  (ep_sfx_ty),a
        ld  a,30
        ld  (ep_sfx_t),a
.nofesta:
        ld  b,11100010b
        ld  c,1
        call WRTVDP
        ei
        ret

; i Proci per stanza: on, quota, x min, x max (x2)
proci_tab:
        db  1,138,40,120    ; megaron: due di ronda
        db  1,138,140,208
        db  0,0,0,0         ; la prova: silenzio e rispetto
        db  0,0,0,0
        db  1,138,140,224   ; la strage: entrano DA LONTANO (li
        db  1,138,140,224   ; vedi arrivare), e ne arrivano cinque
        db  0,0,0,0         ; il talamo: solo la famiglia,
        db  0,0,0,0         ; e la pace

; ------------------------------------------------------------
; fine episodio: la vittoria qui e' il VIAGGIO COMPIUTO
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
        call crew_reward
        xor a
        ld  (phase),a
        ld  a,(leg)
        inc a
        cp  N_DESTS
        jr  c,.setleg
        xor a               ; ITACA E' RAGGIUNTA: il giro si
        ld  (leg),a         ; chiude e l'Odissea ricomincia
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
        jp  init            ; phase resta 5: si ritenta

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
        ; --- al talamo: la PIOGGIA DI PETALI (slot 5-7) ---
        ld  a,(ep_room)
        cp  3
        jp  z,.petali
        ; --- slot 5: la freccia ---
        ld  a,(arr_on)
        or  a
        jr  z,.s5h
        ld  a,(arr_y)
        dec a
        out (098h),a
        ld  a,(arr_x)
        out (098h),a
        ld  a,(arr_d)
        or  a
        jr  z,.ar
        ld  a,160
        jr  .as
.ar:
        ld  a,156
.as:
        out (098h),a
        ld  a,15
        out (098h),a
        jr  .proci
.s5h:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        out (098h),a
        out (098h),a
.proci:
        ; --- slot 6-7: i Proci (tunica rossa, spavaldi) ---
        ld  a,(frame_cnt)
        and 8
        jr  z,.pw1
        ld  c,144
        jr  .pw2
.pw1:
        ld  c,140
.pw2:
        ld  a,(b0_on)
        or  a
        jr  z,.p0h
        ld  a,(b0_y)
        dec a
        out (098h),a
        ld  a,(b0_x)
        out (098h),a
        ld  a,(b0_d)
        or  a
        ld  a,c
        jr  z,.p0p
        add a,8
.p0p:
        out (098h),a
        ld  a,8
        out (098h),a
        jr  .p1s
.p0h:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        out (098h),a
        out (098h),a
.p1s:
        ld  a,(b1_on)
        or  a
        jr  z,.p1h
        ld  a,(b1_y)
        dec a
        out (098h),a
        ld  a,(b1_x)
        out (098h),a
        ld  a,(b1_d)
        or  a
        ld  a,c
        jr  z,.p1p
        add a,8
.p1p:
        out (098h),a
        ld  a,8
        out (098h),a
        jr  .oamend
.p1h:
        ld  a,209
        out (098h),a
        xor a
        out (098h),a
        out (098h),a
        out (098h),a
        jp  .oamend
.petali:
        ; tre petali che scendono ondeggiando, colori di festa
        ld  e,0
.ptl:
        ; quota: cade piano, ogni petalo sfasato di 1/3 di giro
        ld  a,e
        rrca
        rrca                ; e*64
        ld  b,a
        ld  a,(frame_cnt)
        srl a
        add a,b
        and 127
        add a,24            ; 24..151: mai 208!
        out (098h),a
        ; x: colonna del petalo + l'ondeggio del beccheggio
        ld  a,(frame_cnt)
        rrca
        rrca
        rrca
        and 15
        ld  l,a
        ld  h,0
        ld  bc,ship_bob
        add hl,bc
        ld  a,e
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a             ; e*64
        add a,48
        add a,(hl)
        out (098h),a
        ld  a,(frame_cnt)
        and 8
        jr  z,.pt1
        ld  a,168
        jr  .pt2
.pt1:
        ld  a,164
.pt2:
        out (098h),a
        ld  a,e             ; i colori della festa: rosa, rosso,
        ld  l,a             ; giallo chiaro
        ld  h,0
        ld  bc,petal_cols
        add hl,bc
        ld  a,(hl)
        out (098h),a
        inc e
        ld  a,e
        cp  3
        jr  c,.ptl
.oamend:
        ld  a,208
        out (098h),a
        ; --- coda di poke alla name table ---
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
        ; --- HUD: ciurma, i Proci abbattuti, l'arco ---
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
        ; la barra: i Proci abbattuti (x2 per riempirla)
        ld  a,low (VR_NAME+BAR_COL)
        out (099h),a
        ld  a,(high (VR_NAME+BAR_COL))|40h
        out (099h),a
        ld  a,(dead)
        add a,a
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
        ld  a,(arco)
        or  a
        jr  z,.hs
        ld  a,ARCO_TILE
.hs:
        out (098h),a
.nohud:
        call it_audio
        ld  hl,frame_cnt
        inc (hl)
        ret

; ------------------------------------------------------------
; audio: effetti sul canale A; la LIRA DI CASA sul B (maggiore:
; per la prima volta nel viaggio, la musica non minaccia)
; ------------------------------------------------------------
it_audio:
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
        ld  a,d             ; il colpo subito
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
        ; la porta che si apre: campana chiara
        ld  a,d
        add a,a
        add a,12
        ld  b,a
        ld  a,12
        jp  .tout
.n3:
        dec a
        jr  nz,.n4
        ; il TWANG della corda: pizzico secco che sale
        ld  a,d
        add a,a
        add a,a
        add a,10
        ld  b,a
        ld  a,13
        jp  .tout
.n4:
        ; il grido del Proco: ronzio che sprofonda
        ld  a,25
        sub d
        add a,a
        add a,a
        add a,60
        ld  b,a
        ld  a,11
.tout:
        ld  c,a
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
        jp  .lyre
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
        jp  .lyre
.quiet:
        ld  a,8
        out (0A0h),a
        xor a
        out (0A1h),a
.lyre:
        ; --- la lira di casa: quieta nel palazzo, in FESTA al
        ;     talamo (piu' svelta, piu' piena) ---
        ld  a,(ep_room)
        cp  3
        jr  z,.fest
        ld  c,20            ; tempo quieto
        ld  e,5             ; volume di fondo
        jr  .go2
.fest:
        ld  c,12            ; tempo di danza
        ld  e,7
.go2:
        ld  hl,lyre_t
        inc (hl)
        ld  a,(hl)
        cp  c
        jr  c,.note
        ld  (hl),0
        ld  hl,lyre_i
        ld  a,(hl)
        inc a
        and 7
        ld  (hl),a
.note:
        ld  a,(lyre_i)
        ld  l,a
        ld  h,0
        ld  bc,lyre_tab
        ld  a,(ep_room)
        cp  3
        jr  nz,.tabok
        ld  bc,lyre_fest
.tabok:
        ld  a,(lyre_i)
        ld  l,a
        ld  h,0
        add hl,bc
        ld  a,2
        out (0A0h),a
        ld  a,(hl)
        out (0A1h),a
        ld  a,3
        out (0A0h),a
        xor a
        out (0A1h),a
        ld  a,(lyre_t)
        srl a
        srl a
        ld  b,a
        ld  a,e
        sub b
        jr  nc,.lv
        xor a
.lv:
        ld  b,a
        ld  a,9
        out (0A0h),a
        ld  a,b
        out (0A1h),a
        ret

; Do maggiore: casa, finalmente
lyre_tab:
        db  214,170,143,170,214,143,107,143
; ...e al talamo la lira FA FESTA: piu' su, piu' svelta
lyre_fest:
        db  143,107,127,107,143,107,95,80
petal_cols:
        db  9,8,11          ; rosa, rosso, giallo chiaro
