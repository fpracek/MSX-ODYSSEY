#!/usr/bin/env python3
"""
ODYSSEY - episodio di Polifemo: tileset, stanze, il ciclope, sprite

Genera src/cave_data.asm (banco 3):
  - cave_pat / cave_col: tileset (pattern+colori per tile 0..N)
  - type_tab (ALIGN 256): tile -> tipo (0 vuoto, 1 solido, 2 uscita)
  - room0/room1: name table 768 byte + meta (start x,y, flag ciclope)
  - eye_closed/eye_open: varianti dei 2 tile dell'occhio (pat+col)
  - ep_sprites: Ulisse (fermo/passo1/passo2/salto) + mano (2 pattern)

Polifemo e' disegnato proceduralmente (testa, occhio, barba, corpo,
braccio) su una griglia 48x72 e affettato in tile 8x8 (bg nero, un
colore fg per riga: vincolo SCREEN 2 rispettato per costruzione).
Le stanze sono ASCII art 32x24 con legenda; 'P' ancora il ciclope,
'U' il punto d'ingresso, 'E' l'uscita.
"""
import os
from gen_sky import PAL

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

C_ROCK = 6      # roccia (fg su nero)
C_FLOOR = 10    # pavimento
C_SAND = 11     # sabbia
C_SEA = 5       # mare della spiaggia
C_EXIT = 11     # luce dell'uscita
C_BODY = 10     # pelle del ciclope
C_HAIR = 6      # barba/capelli
C_DECO = 4      # puntini di fondo caverna

# ------------------------------------------------------------------
# tileset base: nome -> (8 righe ASCII, fg, bg)
# ------------------------------------------------------------------
def T(rows, fg, bg=4):
    return (rows, fg, bg)

BASE_TILES = {
    1: T(['########', '#.##.###', '########', '###.##.#',
          '########', '#.###.##', '########', '##.####.'], C_ROCK),
    2: T(['########', '########', '#.#..#.#', '........',
          '........', '.#..#..#', '........', '........'], C_FLOOR),
    3: T(['########', '########', '.#....#.', '........',
          '........', '........', '........', '........'], C_FLOOR),
    4: T(['########', '##.###.#', '########', '########',
          '#.##.###', '########', '###.###.', '########'], C_SAND),
    5: T(['........', '..##..##', '........', '##..##..',
          '........', '..##..##', '........', '##..##..'], C_SEA),
    7: T(['...##...', '..####..', '.######.', '.######.',
          '.######.', '.######.', '..####..', '...##...'], C_EXIT),
    8: T(['########', '.######.', '.#####..', '..###...',
          '..##....', '...#....', '...#....', '........'], C_ROCK),
    9: T(['........', '..#.....', '........', '.....#..',
          '........', '........', '.#......', '........'], C_DECO),
    # HUD (stessi indici del navale: 12 marinaio, 14/15 barra)
    12: T(['...##...', '...##...', '..####..', '...##...',
           '..####..', '..#..#..', '..#..#..', '........'], 15),
    14: T(['........', '........', '........', '.#..#...',
           '.#..#...', '........', '........', '........'], 15),
    15: T(['........', '........', '.######.', '########',
           '########', '.######.', '........', '........'], 8),
}

SOLID = {1, 2, 3, 4}
EXIT = {7}

POLI_T0 = 20            # primo tile del ciclope
POLI_W, POLI_H = 12, 14  # in tile (96x112: quasi mezzo schermo)
# l'occhio: blocco di 4x2 tile (32x16 px) con indici dedicati e
# contigui, cosi' lo swap dorme/sveglio riscrive 8 tile in fila
EYE_BX, EYE_BY, EYE_BW, EYE_BH = 4, 4, 4, 2
EYE_POS = [(bx, by) for by in range(EYE_BY, EYE_BY + EYE_BH)
           for bx in range(EYE_BX, EYE_BX + EYE_BW)]


def draw_polifemo(eye_open):
    """Il COLOSSO a 96x112 (quasi mezzo schermo), dal riferimento di
    Fausto: chioma e barba nere a ricci con CIOCCHE D'ARGENTO, viso
    chiaro con le rughe sulla fronte, monociglio aggrottato, naso
    con le narici, baffi a onda, la bocca d'ORO con la linea scura,
    spalle bronzee - e l'occhio unico di 32x16 al centro."""
    g = [[0] * 96 for _ in range(112)]
    K, W, GOLD, SKIN, GRAY = 1, 15, 10, 10, 14

    def disc(cx, cy, rx, ry, c):
        for y in range(max(0, cy - ry), min(112, cy + ry + 1)):
            for x in range(max(0, cx - rx), min(96, cx + rx + 1)):
                if ((x - cx) * ry) ** 2 + ((y - cy) * rx) ** 2 \
                        <= (rx * ry) ** 2:
                    g[y][x] = c

    # la chioma: massa nera con ricci grossi sul bordo
    disc(48, 30, 42, 29, K)
    for cx, cy in ((9, 24), (18, 11), (32, 4), (48, 1), (64, 4),
                   (78, 11), (87, 24), (5, 42), (91, 42)):
        disc(cx, cy, 9, 9, K)
    # il viso chiaro, pieno
    disc(48, 52, 29, 33, W)
    # rughe della fronte (grigio)
    for x in range(34, 63):
        g[24 + abs(x - 48) // 9][x] = GRAY
    # ombre laterali delle guance (profondita')
    disc(24, 64, 4, 10, GRAY)
    disc(72, 64, 4, 10, GRAY)
    # monociglio: arco nero spesso, aggrottato sull'occhio
    for x in range(20, 77):
        yb = 27 + abs(x - 48) // 5
        for y in range(yb, yb + 5):
            g[y][x] = K
    # naso lungo con le narici
    for y in range(48, 66):
        for x in range(43, 54):
            if x in (43, 53) or y > 63:
                g[y][x] = K
            elif g[y][x] == 0:
                g[y][x] = W
    for y in range(62, 66):
        g[y][40] = K
        g[y][41] = K
        g[y][56] = K
        g[y][57] = K
    # baffi a onda
    for x in range(22, 75):
        yb = 68 + (2 if 34 < x < 62 else 0)
        for y in range(yb, yb + 5):
            g[y][x] = K
    # la bocca d'ORO spalancata, con la linea scura in mezzo
    for y in range(74, 81):
        for x in range(36, 60):
            g[y][x] = GOLD
    for x in range(38, 58):
        g[77][x] = K
    # la barba: massone nero a ricci, con ciocche d'argento
    for y in range(80, 106):
        half = 43 - max(0, (y - 88)) * 3 // 2
        for x in range(48 - half, 48 + half):
            if 0 <= x < 96:
                if ((x * 7 + y * 13) % 11) != 0:
                    g[y][x] = GRAY if ((x * 5 + y * 7) % 31) == 0 \
                        else K
    # boccoli finali della barba
    for cx, cy in ((16, 98), (30, 104), (48, 106), (66, 104),
                   (80, 98)):
        disc(cx, cy, 7, 7, K)
    # spalle bronzee
    for y in range(104, 112):
        for x in range(2, 94):
            if abs(x - 48) < 26 + (y - 104) * 2:
                if g[y][x] == 0:
                    g[y][x] = SKIN
    # ---- L'OCCHIO (regione 32x16: blocchi EYE_POS) ----
    for y in range(32, 48):
        for x in range(32, 64):
            g[y][x] = W
    if eye_open:
        disc(48, 40, 15, 8, K)                  # orbita spalancata
        disc(48, 40, 13, 6, W)                  # sclera
        disc(48, 40, 8, 6, 8)                   # iride ROSSA, enorme
        disc(48, 40, 3, 3, K)                   # pupilla
        g[36][44] = W                           # riflesso
        g[36][45] = W
        g[37][44] = W
    else:
        for x in range(34, 63):                 # palpebra pesante
            yb = 38 + abs(x - 48) // 10
            g[yb][x] = K
            g[yb + 1][x] = K
        for x in range(36, 61, 5):              # ciglia in giu'
            g[41][x] = K
            g[42][x] = K
    return g


def grid_tile(g, bx, by):
    """Blocco 8x8 -> (pattern, colori). Per ogni riga 8x1 si scelgono
    i DUE colori piu' frequenti (bg il primo, fg il secondo): e' il
    massimo che SCREEN 2 concede, e rende il viso pieno coi dettagli
    sopra invece di pixel su fondo indaco. Gli altri colori vengono
    rimappati per luminanza (0 = sfondo indaco)."""
    from gen_map import LUM
    pat, col = [], []
    for y in range(8):
        row = [c if c else 4 for c in g[by * 8 + y][bx * 8:bx * 8 + 8]]
        freq = {}
        for c in row:
            freq[c] = freq.get(c, 0) + 1
        order = sorted(freq, key=lambda c: -freq[c])
        bg = order[0]
        fg = order[1] if len(order) > 1 else 1
        b = 0
        for i, c in enumerate(row):
            if c != bg and c != fg:
                c = fg if abs(LUM[c] - LUM[fg]) < \
                    abs(LUM[c] - LUM[bg]) else bg
            if c == fg:
                b |= 0x80 >> i
        pat.append(b)
        col.append((fg << 4) | bg)
    return pat, col


# ------------------------------------------------------------------
# stanze 32x24 (riga 0 = bordo, l'HUD la sovrascrive in parte)
# ------------------------------------------------------------------
LEGEND = {'#': 1, '=': 2, '-': 3, 's': 4, '~': 5, ' ': 0,
          'E': 7, 'v': 8, '*': 9}

# REGOLE DELLA SCALA (imparate a caro prezzo): gradini a 3 righe
# (24px, apice di salto ~34), e i gradini consecutivi NON devono
# mai sovrapporsi in colonna - qualsiasi cosa sopra la testa a
# distanza di un gradino blocca il salto. L'uscita 'E' sta DUE
# righe sopra la piattaforma d'arrivo (centro corpo = yh+12); lo
# spawn 'U' a 3 righe piene sopra il pavimento.
ROOM_BEACH = [
    '################################',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                        E     #',
    '#                              #',
    '#                       ####   #',
    '#                              #',
    '#                              #',
    '#                 ----         #',
    '#                              #',
    '#                              #',
    '#           ----               #',
    '#                              #',
    '#                              #',
    '#  U  ----                     #',
    '#                              #',
    '#                              #',
    '#ssssssssssssssssssssssssssssss',
    '#ssssssssssssssssssssssssssssss',
    '~~~ssssssssssssssssssssssssssss',
    '################################',
]

# REGOLA ASSOLUTA (seconda lezione pagata): i gradini del percorso
# non devono MAI condividere colonne nemmeno a DUE passi di
# distanza (48px: l'arco del salto ci arriva e sbatte la testa).
# La scala monotona verso destra la soddisfa per costruzione.
ROOM_CAVE = [
    '################################',
    '#                              #',
    '#            v      v      v  #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                            E #',
    '#                              #',
    '#                           ---#',
    '#                              #',
    '#                              #',
    '#                       ----   #',
    '#                              #',
    '#                              #',
    '#                  ----        #',
    '#P                             #',
    '#                              #',
    '#    U        ----             #',
    '#                              #',
    '#                              #',
    '================================',
    '################################',
    '################################',
    '################################',
]


def build_room(art):
    assert len(art) == 24
    tiles = []
    start = (24, 136)
    anchor = None
    for ry, row in enumerate(art):
        assert len(row) <= 32, 'riga %d da %d colonne' % (ry, len(row))
        row = row.ljust(32, '#')    # righe corte: muro a destra
        for rx, ch in enumerate(row):
            if ch == 'U':
                start = (rx * 8, ry * 8)
                tiles.append(0)
            elif ch == 'P':
                anchor = (rx, ry)
                tiles.append(0)
            else:
                tiles.append(LEGEND[ch])
    if anchor:
        ax, ay = anchor
        eye_t0 = POLI_T0 + POLI_W * POLI_H
        for by in range(POLI_H):
            for bx in range(POLI_W):
                if (bx, by) in EYE_POS:
                    t = eye_t0 + EYE_POS.index((bx, by))
                else:
                    t = POLI_T0 + by * POLI_W + bx
                tiles[(ay - POLI_H + 1 + by) * 32 + ax + bx] = t
    return tiles, start, 1 if anchor else 0


def db_lines(data, per_line=16):
    out = []
    for i in range(0, len(data), per_line):
        out.append('        db  ' +
                   ','.join('0%02Xh' % b for b in data[i:i + per_line]))
    return out


def sprite16(art):
    out = []
    for half in (0, 8):
        for y in range(16):
            b = 0
            for bit in range(8):
                if art[y][half + bit] == '#':
                    b |= 0x80 >> bit
            out.append(b)
    return out


# Ulisse a 3 LAYER, DI PROFILO verso destra: il profilo dell'elmo
# corinzio (calotta, paranaso, guanciale, il foro dell'occhio col
# viso che traspare) e' la sagoma greca per eccellenza. Cimiero e
# mantello ROSSI, viso/braccio/cosce in bronzo. Si disegna UNA
# griglia composita (W=bianco, R=rosso, B=bronzo) e i layer si
# separano da soli: sempre coerenti. Il layer bronzo usa lo slot
# sprite della mano del ciclope: sparisce solo durante gli attacchi,
# cosi' il limite di 4 sprite/riga del TMS9918 non si supera mai.
# 16x24: testa+busto (righe 0-15) e gambe (16-23) come due sprite
# impilati per layer -> le righe non si sovrappongono mai e il
# limite dei 4 sprite/riga resta intatto.
# Stile dal riferimento di Fausto: il VISO porta il personaggio -
# capelli e barba rossicci (R: il nero sparirebbe sul fondo della
# caverna), pelle bronzea (B) con gli OCCHI neri come spazio
# negativo, sciarpa/mantello rossi, chitone bianco (W), stivali.
UL_STAND = ['.....KKKKKK.....',
            '....KKKKKKKK....',
            '...KKKKKKKKKK...',
            '...KKBBBBBBKK...',
            '...KBBBBBBBBK...',
            '...KBBKBBKBBK...',
            '...KBBBBBBBBK...',
            '...KKBBBBBBKK...',
            '....KKKKKKKK....',
            '....WKKKKKKW....',
            '...WWWWWWWWWW...',
            '..BWWWWWWWWWWB..',
            '..BWWWWWWWWWWB..',
            '..BWWWWWWWWWWB..',
            '...WWWWWWWWWW...',
            '...WWWWWWWWWW...',
            '...WW.WWWW.WW...',
            '...WW.WWWW.WW...',
            '....BBB..BBB....',
            '....BBB..BBB....',
            '....BBB..BBB....',
            '....WWW..WWW....',
            '....WWW..WWW....',
            '...WWWW..WWWW...']
# Le pose in movimento sono DI PROFILO nella direzione di marcia
# (regola dei platform: frontale solo da fermo); le versioni verso
# sinistra sono specchiate dal generatore. Profilo verso destra:
# chioma dietro, UN occhio (spazio negativo), barba sul mento.
PR_WALKA = ['.....KKKKKK.....',
            '....KKKKKKKK....',
            '...KKKKKKKKKK...',
            '...KKKKBBBBBB...',
            '...KKKBBBBBBBB..',
            '...KKKBBBKBB....',
            '...KKKBBBBBBBB..',
            '....KKKBBBBBB...',
            '.....KKKKKKK....',
            '....WWWKKKKW....',
            '....WWWWWWWW....',
            '....WWWWWWWW....',
            '..BWWWWWWWWWBB..',
            '...WWWWWWWWWB...',
            '...WWWWWWWWW....',
            '....WWWWWWWW....',
            '....WW.WW.WW....',
            '....WW.WW.WW....',
            '...BBB...BBB....',
            '..BBB.....BBB...',
            '..BBB.....BBB...',
            '..WWW.....WWW...',
            '.WWW.......WWW..',
            '.WWW.......WWW..']
PR_WALKB = ['.....KKKKKK.....',
            '....KKKKKKKK....',
            '...KKKKKKKKKK...',
            '...KKKKBBBBBB...',
            '...KKKBBBBBBBB..',
            '...KKKBBBKBB....',
            '...KKKBBBBBBBB..',
            '....KKKBBBBBB...',
            '.....KKKKKKK....',
            '....WWWKKKKW....',
            '....WWWWWWWW....',
            '....WWWWWWWW....',
            '..BWWWWWWWWW....',
            '..BWWWWWWWWW....',
            '...WWWWWWWWW....',
            '....WWWWWWWW....',
            '....WW.WW.WW....',
            '....WW.WW.WW....',
            '....BBB.BBB.....',
            '....BBB.BBB.....',
            '....BBB.BBB.....',
            '....WWW.WWW.....',
            '....WWW.WWW.....',
            '...WWWW.WWW.....']
PR_JUMP = ['.....KKKKKK.....',
           '...KKKKKKKKK....',
           '..KKKKKKKKKKK...',
           '..KKKKKBBBBBB...',
           '..KKKKBBBBBBBB..',
           '...KKKBBBKBB....',
           '...KKKBBBBBBBB..',
           '....KKKBBBBBB...',
           '.....KKKKKKK....',
           '....WWWKKKKW....',
           '....WWWWWWWW....',
           '....WWWWWWWWB...',
           '...WWWWWWWWWB...',
           '...WWWWWWWWW....',
           '....WWWWWWWW....',
           '....WW.WW.WW....',
           '....BBB.BBB.....',
           '...WWW.WWW......',
           '...WWW.WWW......',
           '................',
           '................',
           '................',
           '................',
           '................']


def ul_mirror(art):
    """La posa specchiata (verso sinistra)."""
    return [row[::-1] for row in art]


def ul_layer(art, ch):
    """Estrae un layer dalla griglia composita."""
    return [''.join('#' if c == ch else '.' for c in row) for row in art]
HAND_L = ['................', '................', '....########....',
          '..############..', '.##############.', '################',
          '################', '################', '################',
          '################', '################', '.##############.',
          '..############..', '....########....', '................',
          '................']
HAND_R = ['................', '................', '........####....',
          '......########..', '....############', '..##############',
          '################', '################', '################',
          '################', '..##############', '....############',
          '......########..', '........####....', '................',
          '................']


def main():
    # tileset: base + polifemo (occhio chiuso) + i 6 tile dell'occhio
    npoli = POLI_W * POLI_H
    n_tiles = POLI_T0 + npoli + len(EYE_POS)
    pat = [[0] * 8 for _ in range(n_tiles)]
    col = [[0x14] * 8 for _ in range(n_tiles)]
    for idx, (rows, fg, bg) in BASE_TILES.items():
        for y in range(8):
            b = 0
            for i, ch in enumerate(rows[y]):
                if ch == '#':
                    b |= 0x80 >> i
            pat[idx][y] = b
            col[idx][y] = (fg << 4) | bg
    closed = draw_polifemo(False)
    for by in range(POLI_H):
        for bx in range(POLI_W):
            p, c = grid_tile(closed, bx, by)
            pat[POLI_T0 + by * POLI_W + bx] = p
            col[POLI_T0 + by * POLI_W + bx] = c
    # l'occhio: 6 tile dedicati e CONTIGUI (dopo la figura), cosi'
    # lo swap dorme/sveglio e' una riscrittura in fila
    eye_i0 = POLI_T0 + npoli
    opened = draw_polifemo(True)
    eye_open_p, eye_open_c = [], []
    eye_closed_p, eye_closed_c = [], []
    for i, (bx, by) in enumerate(EYE_POS):
        p, c = grid_tile(opened, bx, by)
        eye_open_p += p
        eye_open_c += c
        p, c = grid_tile(closed, bx, by)
        eye_closed_p += p
        eye_closed_c += c
        pat[eye_i0 + i] = list(p)
        col[eye_i0 + i] = list(c)

    # tipi
    types = [0] * 256
    for t in SOLID:
        types[t] = 1
    for t in EXIT:
        types[t] = 2

    rooms = [build_room(ROOM_BEACH), build_room(ROOM_CAVE)]

    out = []
    out.append('; GENERATO da tools/gen_cave.py - NON MODIFICARE A MANO')
    out.append('CAVE_NT equ %d' % n_tiles)
    out.append('EYE_T0 equ %d' % eye_i0)
    out.append('EP_NROOMS equ %d' % len(rooms))
    out.append('cave_pat:')
    for t in range(n_tiles):
        out.extend(db_lines(pat[t]))
    out.append('cave_col:')
    for t in range(n_tiles):
        out.extend(db_lines(col[t]))
    out.append('eye_open_pat:')
    out.extend(db_lines(eye_open_p))
    out.append('eye_open_col:')
    out.extend(db_lines(eye_open_c))
    out.append('eye_closed_pat:')
    out.extend(db_lines(eye_closed_p))
    out.append('eye_closed_col:')
    out.extend(db_lines(eye_closed_c))
    out.append('        ALIGN 256')
    out.append('type_tab:')
    out.extend(db_lines(types))
    for k, (tiles, start, cyc) in enumerate(rooms):
        out.append('room%d:' % k)
        out.extend(db_lines(tiles))
        out.append('room%d_meta:' % k)
        out.append('        db  %d,%d,%d   ; start x, start y, ciclope'
                   % (start[0], start[1], cyc))
    out.append('room_tab:')
    for k in range(len(rooms)):
        out.append('        dw  room%d, room%d_meta' % (k, k))
    out.append('; sprite: Ulisse 16x24 in 2 meta\' x 3 layer. Pose (base')
    out.append('; = indice*20): 0 fermo frontale, 20/40 passo A/B verso')
    out.append('; destra, 60 salto destra, 80/100/120 le stesse specchiate')
    out.append('; verso sinistra. Offsets: +0 bianco-su, +4 bianco-giu,')
    out.append('; +8 nero-su (chioma), +12 bronzo-su, +16 bronzo-giu. Mano: 140/144.')
    out.append('ep_sprites:')
    poses = [UL_STAND, PR_WALKA, PR_WALKB, PR_JUMP,
             ul_mirror(PR_WALKA), ul_mirror(PR_WALKB), ul_mirror(PR_JUMP)]
    seq = []
    for art in poses:
        assert len(art) == 24, 'frame da %d righe' % len(art)
        up = art[:16]
        dn = art[16:] + ['.' * 16] * 8
        seq += [ul_layer(up, 'W'), ul_layer(dn, 'W'),
                ul_layer(up, 'K'),
                ul_layer(up, 'B'), ul_layer(dn, 'B')]
    for art in seq + [HAND_L, HAND_R]:
        data = sprite16(art)
        for i in range(0, 32, 16):
            out.append('        db  ' +
                       ','.join('0%02Xh' % b for b in data[i:i + 16]))
    out.append('')

    dst = os.path.join(ROOT, 'src', 'cave_data.asm')
    with open(dst, 'w', newline='\n') as f:
        f.write('\n'.join(out))
    print('scritto %s (%d tile, %d stanze)' % (dst, n_tiles, len(rooms)))

    preview(pat, col, rooms[1][0])
    preview_ulisse()


def preview_ulisse():
    """I 3 frame di Ulisse composti (bianco sopra rosso sopra bronzo)."""
    try:
        from PIL import Image
    except ImportError:
        return
    frames = (UL_STAND, PR_WALKA, PR_WALKB, PR_JUMP,
              ul_mirror(PR_WALKA))
    img = Image.new('RGB', (len(frames) * 20 + 4, 28), PAL[4])
    cmap = {'W': 15, 'K': 1, 'B': 10}
    for f, art in enumerate(frames):
        for y in range(24):
            for x in range(16):
                if art[y][x] in cmap:
                    img.putpixel((f * 20 + 2 + x, y + 2),
                                 PAL[cmap[art[y][x]]])
    dst = os.path.join(ROOT, 'build', 'ulisse_preview.png')
    img.resize((img.width * 8, 224), Image.NEAREST).save(dst)
    print('scritta preview %s' % dst)


def preview(pat, col, tiles):
    try:
        from PIL import Image
    except ImportError:
        print('PIL non presente: salto la preview')
        return
    img = Image.new('RGB', (256, 192))
    for ry in range(24):
        for rx in range(32):
            t = tiles[ry * 32 + rx]
            for y in range(8):
                b = pat[t][y]
                fg = col[t][y] >> 4
                bg = col[t][y] & 15
                for i in range(8):
                    on = b & (0x80 >> i)
                    img.putpixel((rx * 8 + i, ry * 8 + y),
                                 PAL[fg if on else bg])
    dst = os.path.join(ROOT, 'build', 'cave_preview.png')
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.resize((768, 576), Image.NEAREST).save(dst)
    print('scritta preview %s' % dst)


if __name__ == '__main__':
    main()
