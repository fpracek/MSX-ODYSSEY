#!/usr/bin/env python3
"""
ODYSSEY - episodio di CIRCE: tileset, stanze, la maga, sprite

Genera src/circe_data.asm (banco 7, dentro MODULE circe):
  - cave_pat/cave_col/type_tab/room_tab: stessi nomi del modulo
    Polifemo (il motore copiato li usa pari pari)
  - la figura di Circe (48x64, ancora 'C' in basso a sinistra)
  - ep_sprites: Ulisse (stesse 7 pose a 3 layer) + MAIALE (2 frame
    x 2 versi) + STELLA magica (2 frame)

Meccanica firma: il MOLY si raccoglie nel bosco; nella sala la
magia di Circe ti trasforma in maiale (basso e veloce) e solo da
maiale si passa nel cunicolo sotto la balconata.
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
    # il palazzo
    1: T(['########', '#..#...#', '########', '#...#..#',
          '########', '#..#..##', '########', '##...#.#'], 14),
    2: T(['####....', '####....', '####....', '####....',
          '....####', '....####', '....####', '....####'], 14),
    3: T(['########', '########', '.#....#.', '........',
          '........', '........', '........', '........'], 10),
    4: T(['########', '#.####.#', '########', '##.##.##',
          '########', '#.####.#', '########', '##.##.##'], 10),
    5: T(['.######.', '.#.##.#.', '.#.##.#.', '.#.##.#.',
          '.#.##.#.', '.#.##.#.', '.#.##.#.', '.######.'], 14),
    7: T(['...##...', '..####..', '.######.', '.######.',
          '.######.', '.######.', '..####..', '...##...'], 11),
    8: T(['...#....', '..###...', '..###...', '.#####..',
          '..###...', '...#....', '..###...', '..###...'], 8),
    9: T(['........', '..#.....', '........', '.....#..',
          '........', '.#......', '........', '....#...'], 13),
    # il MOLY: corolla bianca (10) e stelo verde (13)
    10: T(['...#....', '.#.#.#..', '..###...', '.#####..',
           '..###...', '.#.#.#..', '...#....', '....#...'], 15),
    13: T(['....#...', '...##...', '...#....', '..##....',
           '...#....', '..##....', '..###...', '..###...'], 12),
    # il bosco (il vecchio 11/16 squadrato e' andato in pensione:
    # gli alberi ora sono figure a tile dedicati, vedi draw_tree)
    # tronco ondulato e radici svasate dell'albero
    104: T(['....####', '...#####', '...#####', '....####',
            '....####', '...#####', '..######', '...#####'], 6),
    105: T(['##......', '###.....', '##......', '###.....',
            '##......', '##......', '###.....', '##......'], 6),
    106: T(['...#####', '..######', '.#######', '.#######',
            '########', '########', '########', '########'], 6),
    107: T(['###.....', '####....', '#####...', '######..',
            '#######.', '########', '########', '########'], 6),
    17: T(['#.##.#.#', '########', '########', '#..##..#',
           '########', '##..##..', '########', '########'], 12),
    18: T(['########', '##.###.#', '########', '########',
           '#.##.###', '########', '###.###.', '########'], 11),
    # HUD (identici agli altri episodi)
    12: CAVE_TILES[12],
    14: CAVE_TILES[14],
    15: CAVE_TILES[15],
}

SOLID = {1, 2, 3, 4, 5, 17, 18}
EXIT = {7}
PICKUP = {10, 13}

CIRCE_T0 = 20
CIRCE_W, CIRCE_H = 6, 8      # 48x64

# l'ALBERO del bosco: chioma organica 48x48 (6x6 tile dedicati,
# stampata piu' volte), tronco ondulato e radici svasate
TREE_T0 = CIRCE_T0 + CIRCE_W * CIRCE_H      # 68
TRK_T0 = TREE_T0 + 36                        # 104: tronco+radici
GREEN_D, GREEN_L = 12, 3


def draw_tree():
    """La chioma: lobi irregolari di verde scuro con la luce da
    nord-ovest in verde chiaro e buchi di cielo nella massa -
    niente piu' rettangoli."""
    g = [[0] * 48 for _ in range(48)]

    def disc(cx, cy, rx, ry, c):
        for y in range(max(0, cy - ry), min(48, cy + ry + 1)):
            for x in range(max(0, cx - rx), min(48, cx + rx + 1)):
                if ((x - cx) * ry) ** 2 + ((y - cy) * rx) ** 2 \
                        <= (rx * ry) ** 2:
                    g[y][x] = c

    for cx, cy, rx, ry in ((24, 27, 21, 16), (11, 31, 10, 9),
                           (37, 31, 10, 9), (16, 15, 11, 9),
                           (32, 15, 11, 9), (24, 9, 9, 7)):
        disc(cx, cy, rx, ry, GREEN_D)
    for cx, cy, rx, ry in ((14, 12, 7, 5), (30, 10, 6, 4),
                           (20, 23, 8, 5), (10, 27, 5, 4)):
        disc(cx, cy, rx, ry, GREEN_L)
    for y in range(48):
        for x in range(48):
            if g[y][x] and ((x * 7 + y * 13) % 29) == 0:
                g[y][x] = 0
    return g


def stamp_tree(tiles, cells, cx):
    """Chioma (righe 1-6), tronco (7-17), radici (18) a colonna cx.
    Non copre mai celle gia' occupate (moly, uscita, deco)."""
    for by in range(6):
        for bx in range(6):
            t = cells[by * 6 + bx]
            if t is None:
                continue
            idx = (1 + by) * 32 + cx + bx
            if tiles[idx] == 0:
                tiles[idx] = t
    for ry in range(6, 18):
        for i in range(2):
            idx = ry * 32 + cx + 2 + i
            if tiles[idx] == 0:
                tiles[idx] = TRK_T0 + i
    for i in range(2):
        idx = 18 * 32 + cx + 2 + i
        if tiles[idx] == 0:
            tiles[idx] = TRK_T0 + 2 + i


def draw_circe():
    """La maga: chioma nera fluente, viso chiaro col diadema d'oro,
    chitone bianco con la cinta, il braccio alzato e il BASTONE con
    il globo magenta della magia. Guarda verso la sala (sinistra)."""
    g = [[0] * 48 for _ in range(64)]
    K, W, GOLD, RED, MAG, GRAY = 1, 15, 10, 8, 13, 14

    def disc(cx, cy, rx, ry, c):
        for y in range(max(0, cy - ry), min(64, cy + ry + 1)):
            for x in range(max(0, cx - rx), min(48, cx + rx + 1)):
                if ((x - cx) * ry) ** 2 + ((y - cy) * rx) ** 2 \
                        <= (rx * ry) ** 2:
                    g[y][x] = c

    # la chioma: massa alta e cascata fluente dietro la schiena
    disc(22, 9, 11, 9, K)
    for y in range(8, 54):
        w = 7 + y // 9
        for x in range(27, min(27 + w, 46)):
            if ((x * 5 + y * 3) % 13) != 0:
                g[y][x] = K
    # il viso
    disc(19, 10, 6, 7, W)
    g[9][16] = K                            # gli occhi
    g[9][21] = K
    g[13][18] = RED                         # le labbra
    g[13][19] = RED
    for x in range(14, 25):                 # il diadema
        g[3][x] = GOLD
    # il chitone: ampio fino ai piedi
    for y in range(18, 64):
        half = 5 + (y - 18) * 9 // 46
        for x in range(19 - half, 20 + half):
            if 0 <= x < 48 and g[y][x] == 0:
                g[y][x] = W
    for y in range(34, 62, 3):              # le pieghe
        g[y][15] = GRAY
        g[y + 1][20] = GRAY
        g[y][25] = GRAY
    for y in (29, 30):                      # la cinta d'oro
        for x in range(13, 27):
            g[y][x] = GOLD
    # il braccio alzato verso la sala, e il BASTONE
    for i in range(9):
        g[22 - i][14 - i // 2] = W
        g[22 - i][13 - i // 2] = W
    for y in range(6, 40):
        g[y][6] = GOLD
        g[y][7] = GOLD
    disc(6, 4, 3, 3, MAG)                   # il globo della magia
    g[3][5] = W                             # riflesso
    return g


# ------------------------------------------------------------------
# stanze
# ------------------------------------------------------------------
LEGEND = {'#': 1, '=': 2, '-': 3, 'b': 4, 'c': 5, ' ': 0, 'E': 7,
          'v': 8, '*': 9, 'k': 10, 'i': 13, 'f': 11, 't': 16,
          'g': 17, 's': 18}

# IL BOSCO DI EEA: sbarco tranquillo, il MOLY e' sul sentiero
# (immancabile: il centro-corpo lo tocca camminando). I tronchi
# sono fondale, non solidi.
ROOM_WOOD = [
    '################################',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#         *          *         #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                              #',
    '#                   k        E #',
    '#                   i          #',
    'gggggggggggggggggggggggggggggggg',
    '################################',
    '################################',
    '################################',
    '################################',
]

# LA SALA DEL PALAZZO: Circe canta sulla balconata ('C' ancora il
# basso-sinistra della figura, in piedi sulle 'b'). Le sue stelle
# cadono sulla tua verticale (avviso luccicante, poi la caduta).
# Il CUNICOLO: sotto la balconata e attraverso la porta bassa nel
# muro (2 file: solo un maiale ci passa) fino all'uscita.
ROOM_HALL = [
    '################################',
    '#                          ##  #',
    '# v       v        v       ##  #',
    '#                          ##  #',
    '#                          ##  #',
    '#                          ##  #',
    '#                          ##  #',
    '#                          ##  #',
    '#                          ##  #',
    '#                          ##  #',
    '#                          ##  #',
    '#                          ##  #',
    '#                          ##  #',
    '#                          ##  #',
    '#                          ##  #',
    '#                    C     ##  #',
    '# U          c     bbbbbbb ##  #',
    '#            c                 #',
    '#            c             E   #',
    '================================',
    '################################',
    '################################',
    '################################',
    '################################',
]


# IL PORCILE DELLA MAGA: l'esame finale. Due cunicoli da maiale
# sovrapposti (rows 17-18 sotto la lastra r16, e rows 11-12 fra le
# lastre r10 e r13) con risalite DA UOMO in mezzo: servono DUE
# trasformazioni al posto giusto. Circe osserva dall'alto a destra
# e le stelle piovono per tutta la scalata; da maiale i gradini di
# 3 file sono negati (balzo corto) - se ti prende al momento
# sbagliato, aspetti o ricadi. L'uscita e' in cima al centro.
ROOM_CELLAR = [
    '################################',
    '#                              #',
    '#  *                       *   #',
    '#                              #',
    '#                              #',
    '#              E               #',
    '#                              #',
    '#             ---              #',
    '#                        C     #',
    '#                              #',
    '#        ################      #',
    '#                              #',
    '#                              #',
    '#    ########################  #',
    '#                              #',
    '#                              #',
    '# U      #################   --#',
    '#                              #',
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
        for by in range(CIRCE_H):
            for bx in range(CIRCE_W):
                t = CIRCE_T0 + by * CIRCE_W + bx
                tiles[(ay - CIRCE_H + 1 + by) * 32 + ax + bx] = t
    return tiles, start, 1 if anchor else 0


# ------------------------------------------------------------------
# sprite: il maiale (16x16, 2 frame) e la stella magica (2 frame)
# ------------------------------------------------------------------
PIG_A = ['................',
         '................',
         '................',
         '................',
         '................',
         '..........##....',
         '.#..#########...',
         '#..##########...',
         '.#############..',
         '.###########.##.',
         '.##############.',
         '..############..',
         '..###########...',
         '..##...##..##...',
         '..##...##..##...',
         '.###...##...##..']
PIG_B = ['................',
         '................',
         '................',
         '................',
         '................',
         '..........##....',
         '.#..#########...',
         '#..##########...',
         '.#############..',
         '.###########.##.',
         '.##############.',
         '..############..',
         '..###########...',
         '...##..##..##...',
         '...##..##..##...',
         '...##..##..##...']

STAR_A = ['.......#........',
          '.......#........',
          '......###.......',
          '.......#........',
          '......###.......',
          '......###.......',
          '.....#####......',
          '.....#####......',
          '....#######.....',
          '....#######.....',
          '.....#####......',
          '......###.......',
          '.......#........',
          '................',
          '................',
          '................']
STAR_B = ['........#.......',
          '......#.#.......',
          '.......##.......',
          '......###.......',
          '.......##.......',
          '......####......',
          '.....#####......',
          '....#######.....',
          '....#######.....',
          '....#######.....',
          '.....#####......',
          '......###.......',
          '......#.#.......',
          '................',
          '................',
          '................']

# il LEONE ammansito: basso, dorato, ronda il pavimento
LION_A = ['................',
          '................',
          '................',
          '................',
          '................',
          '..........####..',
          '.#........#####.',
          '.##..###########',
          '..##############',
          '.############.##',
          '.###############',
          '..#############.',
          '..############..',
          '..##...##...##..',
          '..##...##...##..',
          '.###...###..###.']
LION_B = ['................',
          '................',
          '................',
          '................',
          '................',
          '..........####..',
          '.#........#####.',
          '.##..###########',
          '..##############',
          '.############.##',
          '.###############',
          '..#############.',
          '..############..',
          '...##..##..##...',
          '...##..##..##...',
          '...##..##..##...']


def main():
    n_tiles = TRK_T0 + 4
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
    fig = draw_circe()
    for by in range(CIRCE_H):
        for bx in range(CIRCE_W):
            p, c = grid_tile(fig, bx, by)
            pat[CIRCE_T0 + by * CIRCE_W + bx] = p
            col[CIRCE_T0 + by * CIRCE_W + bx] = c
    # la chioma dell'albero, affettata (le celle vuote non si
    # stampano: restano cielo)
    tree = draw_tree()
    tree_cells = []
    for by in range(6):
        for bx in range(6):
            p, c = grid_tile(tree, bx, by)
            t = TREE_T0 + by * 6 + bx
            pat[t] = list(p)
            col[t] = list(c)
            tree_cells.append(None if not any(p) else t)

    types = [0] * 256
    for t in SOLID:
        types[t] = 1
    for t in EXIT:
        types[t] = 2
    for t in PICKUP:
        types[t] = 3

    rooms = [build_room(ROOM_WOOD), build_room(ROOM_HALL),
             build_room(ROOM_CELLAR)]
    # i tre alberi del bosco
    for cx in (2, 13, 24):
        stamp_tree(rooms[0][0], tree_cells, cx)

    def find_ch(art, ch):
        for ry, row in enumerate(art):
            rx = row.find(ch)
            if rx >= 0:
                return rx, ry
        raise ValueError(ch)
    kx, ky = find_ch(ROOM_WOOD, 'k')

    out = []
    out.append('; GENERATO da tools/gen_circe.py - NON MODIFICARE A MANO')
    out.append('CAVE_NT equ %d' % n_tiles)
    out.append('EP_NROOMS equ %d' % len(rooms))
    out.append('MOLY_OFF equ %d' % (ky * 32 + kx))
    out.append('MOLY_TILE equ 10')
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
        out.append('        db  %d,%d,%d   ; start x, start y, Circe'
                   % (start[0], start[1], here))
    out.append('room_tab:')
    for k in range(len(rooms)):
        out.append('        dw  room%d, room%d_meta' % (k, k))
    out.append('; sprite: Ulisse 35 pattern (come Polifemo), poi')
    out.append('; MAIALE 140/144 dx 148/152 sx, STELLA 156/160,')
    out.append('; LEONE 164/168 dx 172/176 sx')
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
    for art in seq + [PIG_A, PIG_B, ul_mirror(PIG_A), ul_mirror(PIG_B),
                      STAR_A, STAR_B,
                      LION_A, LION_B, ul_mirror(LION_A), ul_mirror(LION_B)]:
        data = sprite16(art)
        for i in range(0, 32, 16):
            out.append('        db  ' +
                       ','.join('0%02Xh' % b for b in data[i:i + 16]))
    out.append('')

    dst = os.path.join(ROOT, 'src', 'circe_data.asm')
    with open(dst, 'w', newline='\n') as f:
        f.write('\n'.join(out))
    print('scritto %s (%d tile, %d stanze)' % (dst, n_tiles, len(rooms)))

    preview(pat, col, rooms[1][0], 'circe_preview.png')
    preview(pat, col, rooms[0][0], 'wood_preview.png')
    preview(pat, col, rooms[2][0], 'cellar_preview.png')


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
