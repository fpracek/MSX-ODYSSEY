#!/usr/bin/env python3
"""
ODYSSEY - episodio delle SIRENE: tileset, stanze, le cantatrici

Genera src/sirene_data.asm (banco 25, dentro MODULE sirene):
  - cave_pat/cave_col/type_tab/room_tab: stessi nomi del motore
  - la SIRENA (32x40, 4x5 tile, stampata piu' volte per stanza
    con l'ancora 'S' in alto a sinistra della figura)
  - siren_tab (per stanza: on,x,y del centro x2), mast_tab (per
    stanza: 3 zone d'ormeggio x0,x1 dai pali 'M')
  - ep_sprites: Ulisse + uccello + piuma (set di Eolo riusato)

Meccanica firma: il CANTO ATTRAE - durante il canto Ulisse e'
trascinato verso la sirena piu' vicina (a terra si resiste a
fatica, in aria il richiamo vince); legato a un palo d'ormeggio
il canto non prende. La CERA dimezza il richiamo e apre la porta.
"""
import os
from gen_cave import (grid_tile, db_lines, sprite16, ul_layer, ul_mirror,
                      BASE_TILES as CAVE_TILES,
                      UL_STAND, PR_WALKA, PR_WALKB, PR_JUMP)
from gen_eolo import BIRD_A, BIRD_B, LEAF_A, LEAF_B
from gen_sky import PAL

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def T(rows, fg, bg=4):
    return (rows, fg, bg)

TILES = {
    # gli scogli grigi dell'isola
    1: T(['########', '#..#...#', '########', '##...#.#',
          '########', '#.#...##', '########', '#...#..#'], 14),
    2: T(['########', '########', '#.#..#.#', '........',
          '........', '.#..#..#', '........', '........'], 14),
    3: T(['########', '########', '.#....#.', '........',
          '........', '........', '........', '........'], 15),
    7: T(['...##...', '..####..', '.######.', '.######.',
          '.######.', '.######.', '..####..', '...##...'], 11),
    11: T(['...##...', '..####..', '.######.', '.######.',
           '.######.', '.######.', '..####..', '...##...'], 1),
    # il prato fiorito fra le OSSA (il mito: ossa e fiori)
    8: T(['........', '...#....', '..###...', '...#....',
          '..#.#...', '...#....', '...#....', '........'], 8),
    9: T(['........', '.##.....', '........', '....###.',
          '........', '.#......', '...##...', '........'], 15),
    # la CERA: panetto beige legato
    10: T(['..####..', '.######.', '########', '##.##.##',
           '########', '.######.', '..####..', '........'], 11),
    13: T(['..####..', '.######.', '########', '########',
           '.######.', '..####..', '........', '........'], 11),
    # il palo d'ORMEGGIO: pomo d'oro e fusto di legno
    18: T(['...##...', '..####..', '..####..', '...##...',
           '...##...', '...##...', '...##...', '...##...'], 10),
    19: T(['...##...', '...##...', '..##....', '...##...',
           '...##...', '..##....', '...##...', '..###...'], 6),
    # la sabbia
    17: T(['########', '##.###.#', '########', '########',
           '#.##.###', '########', '###.###.', '########'], 11),
    # HUD
    12: CAVE_TILES[12],
    14: CAVE_TILES[14],
    15: CAVE_TILES[15],
}

SOLID = {1, 2, 3, 17}
EXIT = {7}
PICKUP = {10, 13}

SIR_T0 = 20
SIR_W, SIR_H = 4, 5      # 32x40


def draw_siren():
    """La sirena del mito: donna-uccello - chioma nera, viso e
    torso chiari, le ALI grigie spiegate, artigli sullo scoglio."""
    g = [[0] * 32 for _ in range(40)]
    K, W, GRAY, GOLD = 1, 15, 14, 10

    def disc(cx, cy, rx, ry, c):
        for y in range(max(0, cy - ry), min(40, cy + ry + 1)):
            for x in range(max(0, cx - rx), min(32, cx + rx + 1)):
                if ((x - cx) * ry) ** 2 + ((y - cy) * rx) ** 2 \
                        <= (rx * ry) ** 2:
                    g[y][x] = c

    # le ali spiegate (grigie), piume a dente
    for i in range(12):
        y0 = 6 + i
        for x in range(2 + i // 3, 12 - i // 4):
            g[y0][x] = GRAY
        for x in range(20 + i // 4, 30 - i // 3):
            g[y0][x] = GRAY
    for x in range(2, 12, 3):               # punte delle piume
        g[18][x] = GRAY
        g[19][x + 1] = GRAY
    for x in range(21, 31, 3):
        g[18][x] = GRAY
        g[19][x - 1] = GRAY
    # la chioma e il viso
    disc(16, 7, 6, 6, K)
    disc(16, 9, 4, 4, W)
    g[8][14] = K                            # occhi neri
    g[8][18] = K
    g[11][16] = K                           # la bocca che CANTA
    g[12][16] = K
    # il torso chiaro che si stringe
    for y in range(13, 24):
        half = 5 - (y - 13) // 3
        for x in range(16 - half, 17 + half):
            g[y][x] = W
    # il diadema
    g[3][15] = GOLD
    g[3][16] = GOLD
    g[3][17] = GOLD
    # zampe d'uccello e artigli
    for y in range(24, 30):
        g[y][13] = GOLD
        g[y][19] = GOLD
    for x in (11, 13, 15):
        g[30][x] = GOLD
    for x in (17, 19, 21):
        g[30][x] = GOLD
    # lo scoglio del nido
    for y in range(31, 40):
        half = 6 + (y - 31)
        for x in range(16 - half, 17 + half):
            if 0 <= x < 32:
                if ((x * 5 + y * 7) % 11) != 0:
                    g[y][x] = GRAY
    return g


# ------------------------------------------------------------------
# stanze ('S' = sirena, alto-sinistra della figura; 'M' = palo)
# ------------------------------------------------------------------
LEGEND = {'#': 1, '=': 2, '-': 3, ' ': 0, 'E': 7, 'D': 11,
          'w': 8, 'o': 9, 'k': 10, 'i': 13, 'g': 17}

# LA SPIAGGIA DELLE OSSA: si impara il ritmo - nei silenzi si
# cammina, al canto ci si LEGA al palo. La sirena sul suo scoglio
# a destra tira verso il muro chi resta scoperto.
ROOM_SHORE = [
    '################################',
    '#                              #',
    '#                              #',
    '#                       S      #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                       #####  #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#    o    M    w    M    o   E #',
    '#  w                    o      #',
    'gggggggggggggggggggggggggggggggg',
    '################################',
    '################################',
    '################################',
    '################################',
]

# GLI SCOGLI DEL CANTO: due sirene, una per lato - in mezzo il
# tiro alla fune. La scalata si fa nei silenzi, con gli ormeggi a
# meta' via; saltare durante il canto e' consegnarsi.
ROOM_ROCKS = [
    '################################',
    '#                              #',
    '#                              #',
    '#                              #',
    '# S                            #',
    '#                              #',
    '#             E                #',
    '#                          S   #',
    '#            ---               #',
    '######                         #',
    '#                              #',
    '#                  ---         #',
    '#                M        ######',
    '#                              #',
    '#               ---            #',
    '#                              #',
    '#                              #',
    '#         ---       M          #',
    '#                              #',
    'gggggggggggggggggggggggggggggggg',
    '################################',
    '################################',
    '################################',
    '################################',
]

# IL NIDO: la CERA sul piedistallo fra le due cantatrici - presa,
# il richiamo si dimezza e la porta s'accende. La fuga passa
# sotto i nidi, d'ormeggio in ormeggio.
ROOM_NEST = [
    '################################',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#       S           S          #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#               k              #',
    '#      #####    i   #####      #',
    '#              ---             #',
    '#                              #',
    '#                              #',
    '#         ---                  #',
    '#                              #',
    '#                              #',
    '#    ---     M        M      D #',
    '#  o     w         o      w    #',
    'gggggggggggggggggggggggggggggggg',
    '################################',
    '################################',
    '################################',
    '################################',
]


def build_room(art):
    assert len(art) == 24
    tiles = []
    start = (24, 128)
    sirens = []
    masts = []
    for ry, row in enumerate(art):
        assert len(row) == 32, 'riga %d da %d colonne' % (ry, len(row))
        for rx, ch in enumerate(row):
            if ch == 'U':
                start = (rx * 8, ry * 8)
                tiles.append(0)
            elif ch == 'S':
                sirens.append((rx, ry))
                tiles.append(0)
            elif ch == 'M':
                masts.append((rx, ry))
                tiles.append(0)
            else:
                tiles.append(LEGEND[ch])
    # i pali d'ormeggio: pomo + fusto sotto
    for mx, my in masts:
        tiles[my * 32 + mx] = 18
        tiles[(my + 1) * 32 + mx] = 19
    return tiles, start, sirens, masts


def stamp_siren(tiles, cells, cx, cy):
    for by in range(SIR_H):
        for bx in range(SIR_W):
            t = cells[by * SIR_W + bx]
            if t is None:
                continue
            idx = (cy + by) * 32 + cx + bx
            if tiles[idx] == 0:
                tiles[idx] = t


def main():
    n_tiles = SIR_T0 + SIR_W * SIR_H
    pat = [[0] * 8 for _ in range(n_tiles)]
    col = [[0x14] * 8 for _ in range(n_tiles)]
    for idx, (rows, fg, bg) in TILES.items():
        for y in range(8):
            b = 0
            for i, ch in enumerate(rows[y]):
                if ch == '#':
                    b |= 0x80 >> i
            pat[idx][y] = b
            col[idx][y] = (fg << 4) | bg
    fig = draw_siren()
    cells = []
    for by in range(SIR_H):
        for bx in range(SIR_W):
            p, c = grid_tile(fig, bx, by)
            t = SIR_T0 + by * SIR_W + bx
            pat[t] = list(p)
            col[t] = list(c)
            cells.append(None if not any(p) else t)

    types = [0] * 256
    for t in SOLID:
        types[t] = 1
    for t in EXIT:
        types[t] = 2
    for t in PICKUP:
        types[t] = 3

    arts = [ROOM_SHORE, ROOM_ROCKS, ROOM_NEST]
    rooms = []
    for art in arts:
        tiles, start, sirens, masts = build_room(art)
        for sx, sy in sirens:
            stamp_siren(tiles, cells, sx, sy)
        rooms.append((tiles, start, sirens, masts))

    def find_ch(art, ch):
        for ry, row in enumerate(art):
            rx = row.find(ch)
            if rx >= 0:
                return rx, ry
        raise ValueError(ch)
    kx, ky = find_ch(ROOM_NEST, 'k')
    dx_, dy_ = find_ch(ROOM_NEST, 'D')

    out = []
    out.append('; GENERATO da tools/gen_sirene.py - NON MODIFICARE A MANO')
    out.append('CAVE_NT equ %d' % n_tiles)
    out.append('EP_NROOMS equ %d' % len(rooms))
    out.append('CERA_OFF equ %d' % (ky * 32 + kx))
    out.append('CERA_TILE equ 10')
    out.append('DARK_OFF equ %d' % (dy_ * 32 + dx_))
    out.append('cave_pat:')
    for t in range(n_tiles):
        out.extend(db_lines(pat[t]))
    out.append('cave_col:')
    for t in range(n_tiles):
        out.extend(db_lines(col[t]))
    out.append('        ALIGN 256')
    out.append('type_tab:')
    out.extend(db_lines(types))
    for k, (tiles, start, sirens, masts) in enumerate(rooms):
        out.append('room%d:' % k)
        out.extend(db_lines(tiles))
        out.append('room%d_meta:' % k)
        out.append('        db  %d,%d,1   ; start x, start y, canto'
                   % (start[0], start[1]))
    out.append('room_tab:')
    for k in range(len(rooms)):
        out.append('        dw  room%d, room%d_meta' % (k, k))
    out.append('; le sirene per stanza: on, x centro, y centro (x2)')
    out.append('siren_tab:')
    for tiles, start, sirens, masts in rooms:
        ss = list(sirens)[:2]
        while len(ss) < 2:
            ss.append(None)
        for s in ss:
            if s is None:
                out.append('        db  0,0,0')
            else:
                out.append('        db  1,%d,%d'
                           % (s[0] * 8 + 16, s[1] * 8 + 16))
    out.append('; le zone d\'ormeggio per stanza: x0,x1 (x3, 0=vuota)')
    out.append('mast_tab:')
    for tiles, start, sirens, masts in rooms:
        mm = list(masts)[:3]
        while len(mm) < 3:
            mm.append(None)
        for m in mm:
            if m is None:
                out.append('        db  0,0')
            else:
                out.append('        db  %d,%d'
                           % ((m[0] - 1) * 8, (m[0] + 2) * 8 - 1))
    out.append('; sprite: Ulisse 35 pattern, UCCELLO 140-152, PIUMA 156/160')
    out.append('ep_sprites:')
    poses = [UL_STAND, PR_WALKA, PR_WALKB, PR_JUMP,
             ul_mirror(PR_WALKA), ul_mirror(PR_WALKB), ul_mirror(PR_JUMP)]
    seq = []
    for art in poses:
        up = art[:16]
        dn = art[16:] + ['.' * 16] * 8
        seq += [ul_layer(up, 'W'), ul_layer(dn, 'W'),
                ul_layer(up, 'K'),
                ul_layer(up, 'B'), ul_layer(dn, 'B')]
    for art in seq + [BIRD_A, BIRD_B, ul_mirror(BIRD_A), ul_mirror(BIRD_B),
                      LEAF_A, LEAF_B]:
        data = sprite16(art)
        for i in range(0, 32, 16):
            out.append('        db  ' +
                       ','.join('0%02Xh' % b for b in data[i:i + 16]))
    out.append('')

    dst = os.path.join(ROOT, 'src', 'sirene_data.asm')
    with open(dst, 'w', newline='\n') as f:
        f.write('\n'.join(out))
    print('scritto %s (%d tile, %d stanze)' % (dst, n_tiles, len(rooms)))

    preview(pat, col, rooms[0][0], 'shore_preview.png')
    preview(pat, col, rooms[1][0], 'rocks_preview.png')
    preview(pat, col, rooms[2][0], 'nest_preview.png')


def preview(pat, col, tiles, name):
    try:
        from PIL import Image
    except ImportError:
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
    dst = os.path.join(ROOT, 'build', name)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.resize((768, 576), Image.NEAREST).save(dst)
    print('scritta preview %s' % dst)


if __name__ == '__main__':
    main()
