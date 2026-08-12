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
def T(rows, fg, bg=1):
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
    """Griglia 48x72 di indici colore (0 = sfondo nero)."""
    g = [[0] * 48 for _ in range(72)]

    def disc(cx, cy, r, c):
        for y in range(max(0, cy - r), min(72, cy + r + 1)):
            for x in range(max(0, cx - r), min(48, cx + r + 1)):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    g[y][x] = c

    disc(22, 16, 14, C_BODY)                    # testa
    for y in range(26, 34):                     # barba
        for x in range(10, 36):
            if (x + y) % 3:
                g[y][x] = C_HAIR
    for y in range(4, 9):                       # ciuffo
        for x in range(14, 32):
            if (x + y) % 2:
                g[y][x] = C_HAIR
    disc(22, 48, 17, C_BODY)                    # corpo
    for y in range(40, 52):                     # braccio verso destra
        for x in range(34, 48):
            if (y - 40) + (47 - x) < 12:
                g[y][x] = C_BODY
    for y in range(62, 72):                     # gambe raccolte
        for x in range(6, 40):
            g[y][x] = C_BODY if (y < 68 or (x + y) % 3) else C_HAIR
    # l'occhio unico: regione 16x8 ai blocchi (2,2)-(3,2)
    for y in range(16, 24):
        for x in range(16, 32):
            if eye_open:
                g[y][x] = 15                    # sbarrato, bianco
            else:
                g[y][x] = C_BODY
    if eye_open:
        disc(24, 19, 3, 8)                      # pupilla iniettata
    else:
        for x in range(17, 31):                 # palpebra chiusa
            g[19][x] = C_HAIR
    return g


def grid_tile(g, bx, by):
    """Blocco 8x8 -> (pattern, colori); un fg per riga, bg nero."""
    pat, col = [], []
    for y in range(8):
        row = g[by * 8 + y][bx * 8:bx * 8 + 8]
        fg = 0
        for c in row:
            if c:
                fg = c
                break
        b = 0
        for i, c in enumerate(row):
            if c:
                b |= 0x80 >> i
        pat.append(b)
        col.append(((fg if fg else 1) << 4) | 1)
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
UL_STAND = ['.....RRRRRR.....',
            '....RRRRRRRR....',
            '...RRRRRRRRRR...',
            '...RRBBBBBBRR...',
            '...RBBBBBBBBR...',
            '...RBB.BB.BBR...',
            '...RBBBBBBBBR...',
            '...RBBBBBBBBR...',
            '....RRRRRRRR....',
            '...RRRRRRRRRR...',
            '...RRRRRRRRRR...',
            '.RRWWWWWWWWWWB..',
            '.RRWWWWWWWWWWB..',
            '.RRWWWWWWWWWWB..',
            '.RRWWWWWWWWWW...',
            '..RWWWWWWWWWW...',
            '...WW.WWWW.WW...',
            '...WW.WWWW.WW...',
            '....BBB..BBB....',
            '....BBB..BBB....',
            '....BBB..BBB....',
            '....WWW..WWW....',
            '....WWW..WWW....',
            '...WWWW..WWWW...']
UL_WALK = ['.....RRRRRR.....',
           '....RRRRRRRR....',
           '...RRRRRRRRRR...',
           '...RRBBBBBBRR...',
           '...RBBBBBBBBR...',
           '...RBB.BB.BBR...',
           '...RBBBBBBBBR...',
           '...RBBBBBBBBR...',
           '....RRRRRRRR....',
           '...RRRRRRRRRR...',
           '..RRRRRRRRRRR...',
           'RRRWWWWWWWWWWB..',
           'RRRWWWWWWWWWWB..',
           '.RRWWWWWWWWWWB..',
           '.RRWWWWWWWWWW...',
           '..RWWWWWWWWWW...',
           '...WW.WWWW.WW...',
           '...WW.WWWW.WW...',
           '...BBB....BBB...',
           '..BBB......BBB..',
           '..BBB......BBB..',
           '..WWW......WWW..',
           '.WWW........WWW.',
           '.WWW........WWW.']
UL_JUMP = ['.....RRRRRR.....',
           '....RRRRRRRR....',
           '...RRRRRRRRRR...',
           '...RRBBBBBBRR...',
           '...RBBBBBBBBR...',
           '...RBB.BB.BBR...',
           '...RBBBBBBBBR...',
           '...RBBBBBBBBR...',
           '....RRRRRRRR....',
           '..RRRRRRRRRRR...',
           '.RRRRRRRRRRRR...',
           'RRRWWWWWWWWWWB..',
           '.RRWWWWWWWWWWB..',
           '..RWWWWWWWWWW...',
           '...WWWWWWWWWW...',
           '...WW.WWWW.WW...',
           '....BBB..BBB....',
           '...WWW..WWW.....',
           '...WWW..WWW.....',
           '................',
           '................',
           '................',
           '................',
           '................']


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
    col = [[0x11] * 8 for _ in range(n_tiles)]
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
    out.append('; sprite: Ulisse 16x24 in 2 meta\' x 3 layer. Per frame')
    out.append('; (base 0/20/40): +0 bianco-su, +4 bianco-giu, +8 rosso-su,')
    out.append('; +12 bronzo-su, +16 bronzo-giu. Mano: 60/64.')
    out.append('ep_sprites:')
    seq = []
    for art in (UL_STAND, UL_WALK, UL_JUMP):
        assert len(art) == 24, 'frame da %d righe' % len(art)
        up = art[:16]
        dn = art[16:] + ['.' * 16] * 8
        seq += [ul_layer(up, 'W'), ul_layer(dn, 'W'),
                ul_layer(up, 'R'),
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
    img = Image.new('RGB', (3 * 20 + 4, 28), PAL[1])
    cmap = {'W': 15, 'R': 8, 'B': 10}
    for f, art in enumerate((UL_STAND, UL_WALK, UL_JUMP)):
        for y in range(24):
            for x in range(16):
                if art[y][x] in cmap:
                    img.putpixel((f * 20 + 2 + x, y + 2),
                                 PAL[cmap[art[y][x]]])
    dst = os.path.join(ROOT, 'build', 'ulisse_preview.png')
    img.resize(((3 * 20 + 4) * 8, 224), Image.NEAREST).save(dst)
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
