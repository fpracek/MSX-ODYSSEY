#!/usr/bin/env python3
"""
ODYSSEY - episodio di EOLO: tileset, stanze, il re dei venti, sprite

Genera src/eolo_data.asm (banco 23, dentro MODULE eolo):
  - cave_pat/cave_col/type_tab/room_tab: stessi nomi del motore
  - la figura di Eolo (48x64, ancora 'C' in basso a sinistra)
  - ep_sprites: Ulisse (7 pose x 3 layer) + UCCELLO (2 frame x 2
    versi) + PIUMA (2 frame)
  - updraft_tab: il camino ascensionale per stanza (da '|')

Meccanica firma: il RESPIRO di Eolo - calma, sibilo d'avviso,
RAFFICA che spinge (piena in volo, mezza a terra); nel camino
segnato dalle piume la raffica SOLLEVA. L'otre dei venti apre
la porta della sala.
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
    # le mura di BRONZO dell'isola volante
    1: T(['########', '#.#..#.#', '########', '##.##.##',
          '########', '#..##..#', '########', '#.#..#.#'], 10),
    2: T(['########', '########', '#.#..#.#', '........',
          '........', '.#..#..#', '........', '........'], 10),
    3: T(['########', '########', '.#....#.', '........',
          '........', '........', '........', '........'], 15),
    # la nuvola SOLIDA (il banco su cui siede il re)
    4: T(['..####..', '.######.', '########', '########',
          '########', '########', '.######.', '..####..'], 15),
    # il camino del vento: piume che salgono (fondale, non solido)
    5: T(['...#....', '..#.....', '...#....', '....#...',
          '...#....', '..#.....', '...#....', '....#...'], 5),
    7: T(['...##...', '..####..', '.######.', '.######.',
          '.######.', '.######.', '..####..', '...##...'], 11),
    # il gonfalone rosso (banderuola della sala)
    8: T(['#.......', '###.....', '#####...', '###.....',
          '#.......', '#.......', '#.......', '#.......'], 8),
    9: T(['........', '..#.....', '........', '.....#..',
          '........', '.#......', '........', '....#...'], 15),
    # l'OTRE dei venti: sacco di cuoio legato d'oro
    10: T(['..####..', '.######.', '..####..', '...##...',
           '..####..', '.######.', '.######.', '..####..'], 6),
    13: T(['.######.', '.######.', '..####..', '..####..',
           '...##...', '...##...', '..####..', '...##...'], 6),
    # nuvola di fondale (non solida)
    16: T(['..##.#..', '.######.', '########', '.##.###.',
           '..#.##..', '........', '........', '........'], 15),
    # il suolo di bronzo
    17: T(['#.##.#.#', '########', '########', '#..##..#',
           '########', '##..##..', '########', '########'], 10),
    # HUD
    12: CAVE_TILES[12],
    14: CAVE_TILES[14],
    15: CAVE_TILES[15],
}

SOLID = {1, 2, 3, 4, 17}
EXIT = {7}
PICKUP = {10, 13}

EOLO_T0 = 20
EOLO_W, EOLO_H = 6, 8


def draw_eolo():
    """Il re dei venti: corona d'oro, volto bronzeo, la BARBA
    bianca immensa che fluisce come nubi, spalle candide - seduto
    sul suo banco di nuvole (le nuvole solide stanno nella mappa)."""
    g = [[0] * 48 for _ in range(64)]
    K, W, GOLD, SKIN, RED = 1, 15, 10, 10, 8

    def disc(cx, cy, rx, ry, c):
        for y in range(max(0, cy - ry), min(64, cy + ry + 1)):
            for x in range(max(0, cx - rx), min(48, cx + rx + 1)):
                if ((x - cx) * ry) ** 2 + ((y - cy) * rx) ** 2 \
                        <= (rx * ry) ** 2:
                    g[y][x] = c

    # la corona: punte d'oro
    for px in (16, 22, 28):
        for y in range(2, 8):
            g[y][px] = GOLD
            g[y][px + 1] = GOLD
    for x in range(14, 32):
        g[7][x] = GOLD
        g[8][x] = GOLD
    # il volto
    disc(23, 14, 8, 7, SKIN)
    g[13][19] = K                           # gli occhi severi
    g[13][27] = K
    # la BARBA: massa bianca che fluisce e si allarga come nube
    for y in range(18, 46):
        half = 8 + (y - 18) * 2 // 3
        for x in range(23 - half, 24 + half):
            if 0 <= x < 48:
                if ((x * 7 + y * 5) % 13) != 0:
                    g[y][x] = W
    # boccoli della barba
    for cx, cy in ((8, 44), (18, 48), (28, 48), (38, 44)):
        disc(cx, cy, 5, 5, W)
    # le spalle/manto candido, e il fermaglio d'oro
    for y in range(46, 64):
        for x in range(4, 44):
            if g[y][x] == 0 and abs(x - 24) < 14 + (y - 46):
                g[y][x] = W
    for x in range(20, 28):
        g[50][x] = GOLD
        g[51][x] = GOLD
    return g


# ------------------------------------------------------------------
# stanze
# ------------------------------------------------------------------
LEGEND = {'#': 1, '=': 2, '-': 3, '~': 4, '|': 5, ' ': 0, 'E': 7,
          'v': 8, '*': 9, 'k': 10, 'i': 13, 'n': 16, 'g': 17,
          'D': 11}
# la porta buia (si accende con l'otre)
TILES[11] = T(['...##...', '..####..', '.######.', '.######.',
               '.######.', '.######.', '..####..', '...##...'], 1)

# LE PENDICI dell'isola volante: la scala della spiaggia, ma il
# RESPIRO di Eolo piega i salti - si spicca in calma o col vento
# a favore, mai contro la raffica.
ROOM_SLOPE = [
    '################################',
    '#                              #',
    '#   nn    nnn        nn   nn   #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                         E    #',
    '#                              #',
    '#                       ----   #',
    '#                              #',
    '#                              #',
    '#                 ---          #',
    '#                              #',
    '#                              #',
    '#           ---                #',
    '#                              #',
    '#                              #',
    '# U   ---                      #',
    '#                              #',
    'gggggggggggggggggggggggggggggggg',
    '################################',
    '################################',
    '################################',
    '################################',
]

# IL CAMINO DEI VENTI: la salita e' impossibile coi salti - ci si
# mette nel camino segnato dalle piume ('|') e si CAVALCA la
# raffica verso l'alto, sterzando in volo; le cenge a destra sono
# i punti di riposo. Cadere non costa nulla: si riprende il fiato.
ROOM_SHAFT = [
    '################################',
    '#                              #',
    '#            E                 #',
    '#                              #',
    '#           ---                #',
    '#                              #',
    '#                              #',
    '#        |                     #',
    '#        |           ----      #',
    '#        |                     #',
    '#        |                     #',
    '#        |                     #',
    '#        |                     #',
    '#        |           ----      #',
    '#        |                     #',
    '#        |                     #',
    '#        |                     #',
    '#        |                     #',
    '#                              #',
    'gggggggggggggggggggggggggggggggg',
    '################################',
    '################################',
    '################################',
    '################################',
]

# LA SALA DI EOLO: il re sul banco di nuvole, l'OTRE dei venti sul
# piedistallo, la porta buia che si accende solo con l'otre in
# mano. Le raffiche alternate qui sono le piu' forti del viaggio.
ROOM_HALL_E = [
    '################################',
    '#  v                        v  #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#            C                 #',
    '#           ~~~~~~~~           #',
    '#                              #',
    '#     ---                      #',
    '#               k              #',
    '#               i              #',
    '#              ---             #',
    '#                              #',
    '#                              #',
    '#         ---                D #',
    '#                              #',
    '================================',
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
        for by in range(EOLO_H):
            for bx in range(EOLO_W):
                t = EOLO_T0 + by * EOLO_W + bx
                tiles[(ay - EOLO_H + 1 + by) * 32 + ax + bx] = t
    return tiles, start, 1 if anchor else 0


def updraft_range(art):
    """Il camino: dalla colonna dei tile '|' (con un margine)."""
    cols = [rx for row in art for rx, ch in enumerate(row) if ch == '|']
    if not cols:
        return 0, 0
    return (min(cols) - 1) * 8, (max(cols) + 2) * 8 - 1


# l'uccello di Eolo (gabbiano dei venti) e la piuma
BIRD_A = ['................',
          '................',
          '................',
          '.##..........##.',
          '..###......###..',
          '....########....',
          '......####......',
          '.......###......',
          '................', '................', '................',
          '................', '................', '................',
          '................', '................']
BIRD_B = ['................',
          '................',
          '................',
          '................',
          '................',
          '....########....',
          '..###.####.###..',
          '.##....##....##.',
          '................', '................', '................',
          '................', '................', '................',
          '................', '................']
LEAF_A = ['................',
          '................',
          '................',
          '................',
          '................',
          '......##........',
          '....####........',
          '.....##.........',
          '................', '................', '................',
          '................', '................', '................',
          '................', '................']
LEAF_B = ['................',
          '................',
          '................',
          '................',
          '................',
          '........##......',
          '........####....',
          '.........##.....',
          '................', '................', '................',
          '................', '................', '................',
          '................', '................']


def main():
    n_tiles = EOLO_T0 + EOLO_W * EOLO_H
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
    fig = draw_eolo()
    for by in range(EOLO_H):
        for bx in range(EOLO_W):
            p, c = grid_tile(fig, bx, by)
            pat[EOLO_T0 + by * EOLO_W + bx] = p
            col[EOLO_T0 + by * EOLO_W + bx] = c

    types = [0] * 256
    for t in SOLID:
        types[t] = 1
    for t in EXIT:
        types[t] = 2
    for t in PICKUP:
        types[t] = 3

    rooms = [build_room(ROOM_SLOPE), build_room(ROOM_SHAFT),
             build_room(ROOM_HALL_E)]
    arts = [ROOM_SLOPE, ROOM_SHAFT, ROOM_HALL_E]

    def find_ch(art, ch):
        for ry, row in enumerate(art):
            rx = row.find(ch)
            if rx >= 0:
                return rx, ry
        raise ValueError(ch)
    kx, ky = find_ch(ROOM_HALL_E, 'k')
    dx_, dy_ = find_ch(ROOM_HALL_E, 'D')

    out = []
    out.append('; GENERATO da tools/gen_eolo.py - NON MODIFICARE A MANO')
    out.append('CAVE_NT equ %d' % n_tiles)
    out.append('EP_NROOMS equ %d' % len(rooms))
    out.append('OTRE_OFF equ %d' % (ky * 32 + kx))
    out.append('OTRE_TILE equ 10')
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
    for k, (tiles, start, here) in enumerate(rooms):
        out.append('room%d:' % k)
        out.extend(db_lines(tiles))
        out.append('room%d_meta:' % k)
        out.append('        db  %d,%d,%d   ; start x, start y, Eolo'
                   % (start[0], start[1], here))
    out.append('room_tab:')
    for k in range(len(rooms)):
        out.append('        dw  room%d, room%d_meta' % (k, k))
    out.append('; il camino ascensionale per stanza: x0,x1 (0,0 = niente)')
    out.append('updraft_tab:')
    for art in arts:
        x0, x1 = updraft_range(art)
        out.append('        db  %d,%d' % (x0, x1))
    out.append('; sprite: Ulisse 35 pattern, UCCELLO 140/144 dx')
    out.append('; 148/152 sx, PIUMA 156/160')
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

    dst = os.path.join(ROOT, 'src', 'eolo_data.asm')
    with open(dst, 'w', newline='\n') as f:
        f.write('\n'.join(out))
    print('scritto %s (%d tile, %d stanze)' % (dst, n_tiles, len(rooms)))

    preview(pat, col, rooms[2][0], 'eolo_preview.png')
    preview(pat, col, rooms[1][0], 'shaft_preview.png')


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
