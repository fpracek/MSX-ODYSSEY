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
POLI_W, POLI_H = 6, 9   # in tile (48x72 pixel)


def draw_polifemo(eye_open):
    """Il VOLTO gigante di Polifemo che incombe dal buio (48x72),
    dal riferimento di Fausto: chioma e barba NERE a ricci attorno a
    un viso chiaro, monociglio, l'occhio unico centrale, baffi e la
    bocca d'ORO; spalle bronzee in basso."""
    g = [[0] * 48 for _ in range(72)]
    K, W, GOLD, SKIN = 1, 15, 10, 10

    def disc(cx, cy, rx, ry, c):
        for y in range(max(0, cy - ry), min(72, cy + ry + 1)):
            for x in range(max(0, cx - rx), min(48, cx + rx + 1)):
                if ((x - cx) * ry) ** 2 + ((y - cy) * rx) ** 2 \
                        <= (rx * ry) ** 2:
                    g[y][x] = c

    # la chioma: massa nera con ricci sul bordo
    disc(24, 16, 20, 14, K)
    for cx, cy in ((5, 14), (10, 6), (18, 3), (30, 3), (38, 6),
                   (43, 14), (4, 24), (44, 24)):
        disc(cx, cy, 5, 5, K)
    # il viso chiaro (ampio: guance visibili sotto l'occhio)
    disc(24, 26, 14, 15, W)
    # monociglio: arco nero sopra l'occhio
    for x in range(13, 36):
        yb = 13 + abs(x - 24) // 6
        for y in range(yb, yb + 3):
            g[y][x] = K
    # naso
    for y in range(24, 31):
        for x in range(22, 26):
            g[y][x] = K if x in (22, 25) else W
    # baffi a onda
    for x in range(12, 37):
        yb = 31 + (1 if 17 < x < 31 else 0)
        for y in range(yb, yb + 2):
            g[y][x] = K
    # la bocca d'oro
    for y in range(34, 37):
        for x in range(19, 30):
            g[y][x] = GOLD
    # la barba: massone nero a ricci (i buchi sono la texture)
    for y in range(37, 62):
        half = 23 - max(0, (y - 48)) * 3 // 4
        for x in range(24 - half, 24 + half):
            if 0 <= x < 48:
                if ((x * 7 + y * 13) % 11) != 0:
                    g[y][x] = K
    # ricci finali della barba
    for cx, cy in ((10, 58), (18, 62), (26, 63), (34, 60)):
        disc(cx, cy, 4, 4, K)
    # spalle bronzee
    for y in range(62, 72):
        for x in range(2, 46):
            if abs(x - 24) < 12 + (y - 62):
                if g[y][x] == 0:
                    g[y][x] = SKIN
    # l'occhio unico: regione 16x8 ai blocchi (2,2)-(3,2)
    for y in range(16, 24):
        for x in range(16, 32):
            if 17 <= x <= 30:
                g[y][x] = W
    if eye_open:
        disc(24, 20, 5, 3, K)                   # orbita spalancata
        disc(24, 20, 4, 3, 8)                   # iride iniettata
        disc(24, 20, 1, 1, K)                   # pupilla
    else:
        for x in range(17, 31):                 # palpebra pesante
            g[18][x] = K
            g[19][x] = K
        for x in range(18, 30, 3):              # ciglia
            g[20][x] = K
    return g


def grid_tile(g, bx, by):
    """Blocco 8x8 -> (pattern, colori); per ogni riga 8x1 il fg e'
    il colore non-sfondo piu' frequente (vincolo SCREEN 2)."""
    pat, col = [], []
    for y in range(8):
        row = g[by * 8 + y][bx * 8:bx * 8 + 8]
        freq = {}
        for c in row:
            if c:
                freq[c] = freq.get(c, 0) + 1
        fg = max(freq, key=freq.get) if freq else 1
        b = 0
        for i, c in enumerate(row):
            if c:
                b |= 0x80 >> i
        pat.append(b)
        col.append((fg << 4) | 4)
    return pat, col


# ------------------------------------------------------------------
# stanze 32x24 (riga 0 = bordo, l'HUD la sovrascrive in parte)
# ------------------------------------------------------------------
LEGEND = {'#': 1, '=': 2, '-': 3, 's': 4, '~': 5, ' ': 0,
          'E': 7, 'v': 8, '*': 9}

# gradini da 2 righe (16px): l'eroe e' alto 24px e salta ~29px.
# L'uscita 'E' sta DUE righe sopra la piattaforma d'arrivo (il
# centro del corpo e' a yh+12). Lo spawn 'U' va a 3 righe piene
# sopra il pavimento (mai a cavallo di file solide).
ROOM_BEACH = [
    '################################',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                            E #',
    '#                              #',
    '#                          ####',
    '#                              #',
    '#                      ----    #',
    '#                              #',
    '#                  ----        #',
    '#                              #',
    '#              ----            #',
    '#                              #',
    '#          ----                #',
    '#  U                           #',
    '#      ----                    #',
    '#                              #',
    '#ssssssssssssssssssssssssssssss',
    '#ssssssssssssssssssssssssssssss',
    '~~~ssssssssssssssssssssssssssss',
    '################################',
]

ROOM_CAVE = [
    '################################',
    '#                              #',
    '#  v      v         v      v  #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                           E  #',
    '#                              #',
    '#                         -----#',
    '#                              #',
    '#P                  -----      #',
    '#                              #',
    '#             -----            #',
    '#        *                     #',
    '#                   -----      #',
    '#                              #',
    '#             -----     *      #',
    '# U                            #',
    '#        -----                 #',
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
        for by in range(POLI_H):
            for bx in range(POLI_W):
                tiles[(ay - POLI_H + 1 + by) * 32 + ax + bx] = \
                    POLI_T0 + by * POLI_W + bx
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
    # tileset: base + polifemo (occhio chiuso)
    npoli = POLI_W * POLI_H
    n_tiles = POLI_T0 + npoli
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
    # occhio: blocchi (2,2) e (3,2) della figura
    eye_i0 = POLI_T0 + 2 * POLI_W + 2
    opened = draw_polifemo(True)
    eye_open_p, eye_open_c = [], []
    eye_closed_p, eye_closed_c = [], []
    for bx in (2, 3):
        p, c = grid_tile(opened, bx, 2)
        eye_open_p += p
        eye_open_c += c
        p, c = grid_tile(closed, bx, 2)
        eye_closed_p += p
        eye_closed_c += c

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
