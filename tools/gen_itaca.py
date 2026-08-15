#!/usr/bin/env python3
"""
ODYSSEY - episodio di ITACA: il finale. L'arco e i Proci.

Genera src/itaca_data.asm (banco 27, dentro MODULE itaca):
  - cave_pat/cave_col/type_tab/room_tab: stessi nomi del motore
  - PENELOPE al telaio (32x40, ancora 'C' in alto a sinistra)
  - ep_sprites: Ulisse + PROCO (2 frame x 2 versi) + FRECCIA

Il finale: megaron coi Proci di ronda (niente armi: si schiva),
la prova dell'arco (FIRE da fermo scaglia la freccia attraverso
le scuri), la STRAGE (i Proci caricano, l'arco li abbatte).
"""
import os
from gen_cave import (grid_tile, db_lines, sprite16, ul_layer, ul_mirror,
                      BASE_TILES as CAVE_TILES,
                      UL_STAND, PR_WALKA, PR_WALKB, PR_JUMP)
from gen_sky import PAL

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def T(rows, fg, bg=4):
    return (rows, fg, bg)

TILES = {
    # la pietra di casa
    1: T(['########', '#..#...#', '########', '##...#.#',
          '########', '#.#..#.#', '########', '#...#..#'], 14),
    2: T(['########', '########', '#.#..#.#', '........',
          '........', '.#..#..#', '........', '........'], 6),
    # la TAVOLA del banchetto (legno, solida)
    3: T(['########', '########', '.#....#.', '........',
          '........', '........', '........', '........'], 10),
    # le gambe della tavola (fondale)
    5: T(['.##..##.', '.##..##.', '.##..##.', '.##..##.',
          '.##..##.', '.##..##.', '.##..##.', '.##..##.'], 6),
    7: T(['...##...', '..####..', '.######.', '.######.',
          '.######.', '.######.', '..####..', '...##...'], 11),
    11: T(['...##...', '..####..', '.######.', '.######.',
           '.######.', '.######.', '..####..', '...##...'], 1),
    # la torcia di casa
    8: T(['...#....', '..###...', '..###...', '.#####..',
          '..###...', '...#....', '..###...', '..###...'], 8),
    9: T(['........', '..#.....', '........', '.....#..',
          '........', '.#......', '........', '....#...'], 15),
    # l'ARCO sul piedistallo: impugnatura (10) e base (13)
    10: T(['.....#..', '....##..', '...##...', '..###...',
           '..##....', '..###...', '...##...', '....##..'], 10),
    13: T(['....#...', '...##...', '..####..', '..####..',
           '...##...', '..####..', '.######.', '.######.'], 6),
    # la SCURE della prova: manico e occhio dell'anello
    16: T(['...##...', '..####..', '.##..##.', '.##..##.',
           '..####..', '...##...', '...##...', '...##...'], 14),
    # il pavimento del megaron
    17: T(['########', '##.###.#', '########', '########',
           '#.##.###', '########', '###.###.', '########'], 6),
    # HUD
    12: CAVE_TILES[12],
    14: CAVE_TILES[14],
    15: CAVE_TILES[15],
}

SOLID = {1, 2, 3, 17}
EXIT = {7}
PICKUP = {10, 13}

PEN_T0 = 20
PEN_W, PEN_H = 4, 5      # 32x40


def draw_penelope():
    """Penelope al TELAIO: il velo scuro, la veste chiara, la
    trama d'oro sul telaio - vent'anni di attesa."""
    g = [[0] * 32 for _ in range(40)]
    K, W, GOLD, GRAY = 1, 15, 10, 14

    def disc(cx, cy, rx, ry, c):
        for y in range(max(0, cy - ry), min(40, cy + ry + 1)):
            for x in range(max(0, cx - rx), min(32, cx + rx + 1)):
                if ((x - cx) * ry) ** 2 + ((y - cy) * rx) ** 2 \
                        <= (rx * ry) ** 2:
                    g[y][x] = c

    # il TELAIO: montanti e trama d'oro (a sinistra)
    for y in range(2, 36):
        g[y][2] = GOLD
        g[y][3] = GOLD
        g[y][12] = GOLD
        g[y][13] = GOLD
    for x in range(2, 14):
        g[2][x] = GOLD
        g[3][x] = GOLD
    for y in range(6, 34, 4):               # i fili della tela
        for x in range(4, 12):
            g[y][x] = GRAY
    # Penelope: il velo scuro sul capo, il viso, la veste
    disc(22, 8, 5, 6, K)                    # il velo
    disc(22, 10, 3, 3, W)                   # il viso
    for y in range(14, 38):                 # la veste chiara
        half = 4 + (y - 14) // 4
        for x in range(22 - half, 23 + half):
            if 0 <= x < 32 and g[y][x] == 0:
                g[y][x] = W
    for y in range(16, 20):                 # il braccio verso la tela
        g[y][15 + (19 - y)] = W
        g[y][16 + (19 - y)] = W
    for y in (22, 23):                      # la cinta
        for x in range(18, 27):
            g[y][x] = GOLD
    return g


# ------------------------------------------------------------------
# stanze ('C' = Penelope, alto-sinistra; 'x' = scure della prova)
# ------------------------------------------------------------------
LEGEND = {'#': 1, '=': 2, '-': 3, 'l': 5, ' ': 0, 'E': 7, 'D': 11,
          'v': 8, '*': 9, 'k': 10, 'i': 13, 'x': 16, 'g': 17}

# IL MEGARON DEI PROCI: banchettano da padroni e fanno la ronda.
# Sei il mendicante: niente armi - si passa schivando, sui tavoli
# e nei tempi delle loro ronde.
ROOM_MEGARON = [
    '################################',
    '#  v                        v  #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#       ----      ----         #',
    '#       l  l      l  l       E #',
    '#       l  l      l  l         #',
    'gggggggggggggggggggggggggggggggg',
    '################################',
    '################################',
    '################################',
    '################################',
]

# LA PROVA DELL'ARCO: Penelope assiste dal telaio. L'ARCO sta sul
# piedistallo; con l'arco in mano, DA FERMO, FIRE scaglia la
# freccia attraverso la fila di scuri: la porta si apre.
ROOM_BOW = [
    '################################',
    '#  v                        v  #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                        C     #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#         k                    #',
    '#         i                    #',
    '#        ---                   #',
    '#                              #',
    '#                              #',
    '#   x   x   x   x   x        D #',
    '#                              #',
    'gggggggggggggggggggggggggggggggg',
    '################################',
    '################################',
    '################################',
    '################################',
]

# LA STRAGE: porte sbarrate, i Proci CARICANO a ondate - l'arco
# li abbatte, i tavoli danno respiro ma da lassu' non si tira
# (la freccia parte all'altezza del petto). L'ultimo caduto apre
# la porta: il viaggio e' compiuto.
ROOM_STRAGE = [
    '################################',
    '#  v         v v            v  #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#     ----          ----       #',
    '#     l  l          l  l     D #',
    '#     l  l          l  l       #',
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
    anchor = None
    for ry, row in enumerate(art):
        assert len(row) == 32, 'riga %d da %d colonne' % (ry, len(row))
        for rx, ch in enumerate(row):
            if ch == 'U':
                start = (rx * 8, ry * 8)
                tiles.append(0)
            elif ch == 'C':
                anchor = (rx, ry)
                tiles.append(0)
            else:
                tiles.append(LEGEND[ch])
    if anchor:
        ax, ay = anchor
        for by in range(PEN_H):
            for bx in range(PEN_W):
                t = PEN_T0 + by * PEN_W + bx
                idx = (ay + by) * 32 + ax + bx
                if tiles[idx] == 0:
                    tiles[idx] = t
    return tiles, start, anchor


# il PROCO: nobile spavaldo in tunica, coppa in mano
PROCO_A = ['................',
           '.....####.......',
           '....######......',
           '....#.##.#......',
           '....######......',
           '..#..####..#....',
           '.##.######......',
           '.#.########.#...',
           '....######.##...',
           '....######......',
           '....##..##......',
           '....##..##......',
           '...###..###.....',
           '................',
           '................',
           '................']
PROCO_B = ['................',
           '.....####.......',
           '....######......',
           '....#.##.#......',
           '....######......',
           '....####..#.....',
           '..########.##...',
           '.#.########.....',
           '.##.######......',
           '....######......',
           '...##....##.....',
           '...##....##.....',
           '..###....###....',
           '................',
           '................',
           '................']

# la freccia (verso destra; la sinistra e' specchiata)
ARROW_R = ['................',
           '................',
           '................',
           '................',
           '................',
           '................',
           '............#...',
           '#.#########.##..',
           '#.###########.#.',
           '#.#########.##..',
           '............#...',
           '................',
           '................',
           '................',
           '................',
           '................']


def main():
    n_tiles = PEN_T0 + PEN_W * PEN_H
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
    fig = draw_penelope()
    for by in range(PEN_H):
        for bx in range(PEN_W):
            p, c = grid_tile(fig, bx, by)
            t = PEN_T0 + by * PEN_W + bx
            pat[t] = list(p)
            col[t] = list(c)

    types = [0] * 256
    for t in SOLID:
        types[t] = 1
    for t in EXIT:
        types[t] = 2
    for t in PICKUP:
        types[t] = 3

    rooms = [build_room(ROOM_MEGARON), build_room(ROOM_BOW),
             build_room(ROOM_STRAGE)]

    def find_ch(art, ch):
        for ry, row in enumerate(art):
            rx = row.find(ch)
            if rx >= 0:
                return rx, ry
        raise ValueError(ch)
    kx, ky = find_ch(ROOM_BOW, 'k')
    d1x, d1y = find_ch(ROOM_BOW, 'D')
    d2x, d2y = find_ch(ROOM_STRAGE, 'D')

    out = []
    out.append('; GENERATO da tools/gen_itaca.py - NON MODIFICARE A MANO')
    out.append('CAVE_NT equ %d' % n_tiles)
    out.append('EP_NROOMS equ %d' % len(rooms))
    out.append('ARCO_OFF equ %d' % (ky * 32 + kx))
    out.append('ARCO_TILE equ 10')
    out.append('DARK1_OFF equ %d' % (d1y * 32 + d1x))
    out.append('DARK2_OFF equ %d' % (d2y * 32 + d2x))
    out.append('cave_pat:')
    for t in range(n_tiles):
        out.extend(db_lines(pat[t]))
    out.append('cave_col:')
    for t in range(n_tiles):
        out.extend(db_lines(col[t]))
    out.append('        ALIGN 256')
    out.append('type_tab:')
    out.extend(db_lines(types))
    for k, (tiles, start, anchor) in enumerate(rooms):
        out.append('room%d:' % k)
        out.extend(db_lines(tiles))
        out.append('room%d_meta:' % k)
        out.append('        db  %d,%d,%d   ; start x, start y, stanza'
                   % (start[0], start[1], k))
    out.append('room_tab:')
    for k in range(len(rooms)):
        out.append('        dw  room%d, room%d_meta' % (k, k))
    out.append('; sprite: Ulisse 35 pattern, PROCO 140/144 dx')
    out.append('; 148/152 sx, FRECCIA 156 dx 160 sx')
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
    for art in seq + [PROCO_A, PROCO_B, ul_mirror(PROCO_A),
                      ul_mirror(PROCO_B), ARROW_R, ul_mirror(ARROW_R)]:
        data = sprite16(art)
        for i in range(0, 32, 16):
            out.append('        db  ' +
                       ','.join('0%02Xh' % b for b in data[i:i + 16]))
    out.append('')

    dst = os.path.join(ROOT, 'src', 'itaca_data.asm')
    with open(dst, 'w', newline='\n') as f:
        f.write('\n'.join(out))
    print('scritto %s (%d tile, %d stanze)' % (dst, n_tiles, len(rooms)))

    preview(pat, col, rooms[1][0], 'bow_preview.png')
    preview(pat, col, rooms[2][0], 'strage_preview.png')


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
