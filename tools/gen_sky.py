#!/usr/bin/env python3
"""
ODYSSEY - generatore del cielo: scritta in stile greco + sole + foschia

Tutto STATICO: zero costo a runtime.

- Scritta "TO ITHACA" con glifi 8x8 in stile lapidario greco (la A e'
  una lambda, la C e' un sigma lunato) ma leggibili da un lettore
  inglese. Bianco marmo su cielo.
- Sole 2x2 tile in alto a destra (giallo chiaro).
- Foschia dell'orizzonte: 2 tile a dither nel terzo 1 (righe 8-9) che
  sfumano il cielo (5) verso il cyan della banda C (7).

Output src/sky_data.asm:
  sky_pat / sky_col   pattern+colori dei tile 0..15 del terzo 0
  sky_rows            name table delle righe 0-7 (256 byte)
  haze_pat / haze_col 2 tile di foschia (gli indici li decide main.asm)
Preview: build/sky_preview.png (serve PIL)
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PAL = {
    0:  (0, 0, 0), 1: (0, 0, 0), 2: (33, 200, 66), 3: (94, 220, 120),
    4:  (84, 85, 237), 5: (125, 118, 252), 6: (212, 82, 77),
    7:  (66, 235, 245), 8: (252, 85, 84), 9: (255, 121, 120),
    10: (212, 193, 84), 11: (230, 206, 128), 12: (33, 176, 59),
    13: (201, 91, 186), 14: (204, 204, 204), 15: (255, 255, 255),
}

C_SKY = 5       # azzurro del cielo
C_TEXT = 15     # bianco marmo
C_SUN = 11      # giallo chiaro
C_SEA = 7       # cyan della banda C (per la foschia)

# Le TRATTE: la scritta nel cielo e' la prossima isola del viaggio,
# NON Itaca (che e' solo l'ultima). L'ordine e' quello del DESIGN.
# Ogni nome usa al massimo 8 lettere diverse (gli slot tile liberi
# del terzo 0: 1-7 e 13); il main carica il blocco della tratta.
DESTS = ['TO CYCLOPS', 'TO CIRCE', 'TO AEOLIA',
         'TO SIRENS', 'STRAIT TO ITHACA', 'TO ITHACA']
GLYPH_SLOTS = [1, 2, 3, 4, 5, 6, 7, 13]
TEXT_ROW = 2
SUN_COL = 26    # tile 2x2 alle colonne 26-27, righe 1-2

# glifi 8x8 in stile lapidario greco: A -> lambda, C -> sigma lunato
GLYPHS = {
    'W': ['##....##',
          '##....##',
          '##....##',
          '##.##.##',
          '##.##.##',
          '##.##.##',
          '.##..##.',
          '..#..#..'],
    'M': ['##....##',
          '###..###',
          '##.##.##',
          '##.##.##',
          '##....##',
          '##....##',
          '##....##',
          '##....##'],
    'T': ['#######.',
          '#######.',
          '...#....',
          '...#....',
          '...#....',
          '...#....',
          '...#....',
          '..###...'],
    'O': ['..####..',
          '.##..##.',
          '##....##',
          '##....##',
          '##....##',
          '##....##',
          '.##..##.',
          '..####..'],
    'I': ['.#####..',
          '...#....',
          '...#....',
          '...#....',
          '...#....',
          '...#....',
          '...#....',
          '.#####..'],
    'H': ['##...##.',
          '##...##.',
          '##...##.',
          '#######.',
          '##...##.',
          '##...##.',
          '##...##.',
          '##...##.'],
    'A': ['...##...',
          '...##...',
          '..####..',
          '..#..#..',
          '.##..##.',
          '.#....#.',
          '##....##',
          '##....##'],
    'C': ['..#####.',
          '.##...#.',
          '##......',
          '##......',
          '##......',
          '##......',
          '.##...#.',
          '..#####.'],
    'E': ['#######.',     # sigma: la E del finto greco
          '.##.....',
          '..##....',
          '...#....',
          '..##....',
          '.##.....',
          '#######.',
          '........'],
    'R': ['######..',
          '##...##.',
          '##...##.',
          '######..',
          '##.##...',
          '##..##..',
          '##...##.',
          '........'],
    'S': ['.######.',
          '##......',
          '##......',
          '.#####..',
          '.....##.',
          '.....##.',
          '######..',
          '........'],
    'N': ['##...##.',
          '###..##.',
          '####.##.',
          '##.####.',
          '##..###.',
          '##...##.',
          '##...##.',
          '........'],
    'P': ['######..',
          '##...##.',
          '##...##.',
          '######..',
          '##......',
          '##......',
          '##......',
          '........'],
    'L': ['##......',
          '##......',
          '##......',
          '##......',
          '##......',
          '##......',
          '#######.',
          '........'],
    'Y': ['##...##.',     # ypsilon
          '##...##.',
          '.##.##..',
          '..###...',
          '...#....',
          '...#....',
          '...#....',
          '........'],
    'D': ['######..',
          '##...##.',
          '##...##.',
          '##...##.',
          '##...##.',
          '##...##.',
          '######..',
          '........'],
    'F': ['#######.',
          '##......',
          '##......',
          '######..',
          '##......',
          '##......',
          '##......',
          '........'],
}

SUN = ['.....######.....',
       '...##########...',
       '..############..',
       '.##############.',
       '.##############.',
       '################',
       '################',
       '################',
       '################',
       '.##############.',
       '.##############.',
       '..############..',
       '...##########...',
       '.....######.....',
       '................',
       '................']

# foschia: dither sparso, prima cyan su cielo poi cielo su cyan
HAZE0 = ['#...#...', '........', '..#...#.', '........',
         '#...#...', '........', '..#...#.', '........']
HAZE1 = ['.#...#..', '........', '...#...#', '........',
         '.#...#..', '........', '...#...#', '........']

# ---- HUD (riga 0): ciurma alle colonne 1-12, rotta alle 19-28 ----
CREW_COLS = (1, 12)     # prima colonna, numero slot
BAR_COLS = (19, 10)
T_MAN = 12              # tile: marinaio (slot ciurma pieno)
T_DOT = 14              # tile: rotta ancora da percorrere
T_FILL = 15             # tile: rotta percorsa

MAN = ['...##...',
       '...##...',
       '..####..',
       '...##...',
       '..####..',
       '..#..#..',
       '..#..#..',
       '........']
DOT = ['........',
       '........',
       '........',
       '.#..#...',
       '.#..#...',
       '........',
       '........',
       '........']
FILL = ['........',
        '........',
        '.######.',
        '########',
        '########',
        '.######.',
        '........',
        '........']

# cielo di tempesta: NERO (il massimo del dramma sul TMS9918), il
# sole scompare (fg = bg); l'orizzonte resta chiaro sotto il nero:
# la luce livida prima del fulmine
C_SKY_STORM = 1

# Itaca all'orizzonte: appare (8 tile statici, 4x2, righe 10-11 a
# destra) quando la rotta e' quasi compiuta. Verde scuro sul cyan
# dell'orizzonte (variante tempesta: sul suo azzurro livido).
C_ISLAND = 12
ISLAND = ['.' * 32,
          '.' * 32,
          '.' * 32,
          '.' * 14 + '#' * 2 + '.' * 16,
          '.' * 13 + '#' * 4 + '.' * 15,
          '.' * 12 + '#' * 6 + '.' * 14,
          '.' * 11 + '#' * 8 + '.' * 13,
          '.' * 10 + '#' * 10 + '.' * 12,
          '.' * 8 + '#' * 13 + '.' * 11,
          '.' * 7 + '#' * 15 + '.' * 10,
          '.' * 6 + '#' * 17 + '.' * 9,
          '.' * 4 + '#' * 20 + '.' * 8,
          '.' * 3 + '#' * 22 + '.' * 7,
          '.' * 2 + '#' * 24 + '.' * 6,
          '.' * 1 + '#' * 26 + '.' * 5,
          '#' * 32]


def rows_to_bytes(rows):
    out = []
    for r in rows:
        assert len(r) == 8
        b = 0
        for i, ch in enumerate(r):
            if ch == '#':
                b |= 0x80 >> i
        out.append(b)
    return out


def db_lines(data, per_line=16):
    lines = []
    for i in range(0, len(data), per_line):
        lines.append('        db  ' +
                     ','.join('0%02Xh' % b for b in data[i:i + per_line]))
    return lines


def main():
    # tile del terzo 0: 0=cielo vuoto, 1-7+13=glifi della tratta
    # (caricati a runtime dal main), 8-11 sole, 12/14/15 HUD
    pat = [[0] * 8 for _ in range(16)]
    col = [[(C_TEXT << 4) | C_SKY] * 8 for _ in range(16)]
    col_storm = [[(C_TEXT << 4) | C_SKY_STORM] * 8 for _ in range(16)]
    # sole: 2x2 tile (8-9 sopra, 10-11 sotto); in tempesta sparisce
    for half in range(2):           # 0 = righe 0-7, 1 = righe 8-15
        for side in range(2):       # 0 = colonne 0-7, 1 = 8-15
            t = 8 + half * 2 + side
            rows = [SUN[half * 8 + y][side * 8:side * 8 + 8]
                    for y in range(8)]
            pat[t] = rows_to_bytes(rows)
            col[t] = [(C_SUN << 4) | C_SKY] * 8
            col_storm[t] = [(C_SKY_STORM << 4) | C_SKY_STORM] * 8
    # HUD
    pat[T_MAN] = rows_to_bytes(MAN)
    pat[T_DOT] = rows_to_bytes(DOT)
    pat[T_FILL] = rows_to_bytes(FILL)
    col[T_FILL] = [(C_SUN << 4) | C_SKY] * 8       # rotta percorsa: oro
    col_storm[T_FILL] = [(C_SUN << 4) | C_SKY_STORM] * 8

    # name table righe 0-7 (riga 2 SENZA testo: lo mette il main
    # secondo la tratta corrente)
    rows = [[0] * 32 for _ in range(8)]
    rows[1][SUN_COL] = 8
    rows[1][SUN_COL + 1] = 9
    rows[2][SUN_COL] = 10
    rows[2][SUN_COL + 1] = 11
    # HUD iniziale: 12 marinai + rotta tutta da percorrere
    for i in range(CREW_COLS[1]):
        rows[0][CREW_COLS[0] + i] = T_MAN
    for i in range(BAR_COLS[1]):
        rows[0][BAR_COLS[0] + i] = T_DOT

    # blocchi per tratta: 64 byte di pattern (slot 1-7 poi 13) +
    # la riga 2 completa (testo centrato + i tile del sole)
    dests = []
    for text in DESTS:
        letters = []
        for ch in text:
            if ch != ' ' and ch not in letters:
                letters.append(ch)
        assert len(letters) <= len(GLYPH_SLOTS), \
            'troppi glifi in %r: %r' % (text, letters)
        slot_of = {ch: GLYPH_SLOTS[i] for i, ch in enumerate(letters)}
        dpat = []
        for slot in GLYPH_SLOTS:
            ch = None
            for c2, s2 in slot_of.items():
                if s2 == slot:
                    ch = c2
            if ch is None:
                dpat.extend([0] * 8)
            else:
                dpat.extend(rows_to_bytes(GLYPHS[ch]))
        drow = [0] * 32
        start = (32 - len(text)) // 2
        for i, ch in enumerate(text):
            if ch != ' ':
                drow[start + i] = slot_of[ch]
        drow[SUN_COL] = 10
        drow[SUN_COL + 1] = 11
        dests.append((dpat, drow, slot_of))

    out = []
    out.append('; GENERATO da tools/gen_sky.py - NON MODIFICARE A MANO')
    out.append('; cielo + sole + foschia + HUD + tratte: %s' %
               ', '.join('"%s"' % t for t in DESTS))
    out.append('N_DESTS equ %d' % len(DESTS))
    out.append('sky_pat:')
    for t in range(16):
        out.extend(db_lines(pat[t]))
    out.append('sky_col:')
    for t in range(16):
        out.extend(db_lines(col[t]))
    out.append('; variante tempesta: cielo scuro, sole nascosto')
    out.append('sky_col_storm:')
    for t in range(16):
        out.extend(db_lines(col_storm[t]))
    out.append('sky_rows:')
    for r in rows:
        out.extend(db_lines(r))
    out.append('haze_pat:')
    out.extend(db_lines(rows_to_bytes(HAZE0)))
    out.extend(db_lines(rows_to_bytes(HAZE1)))
    out.append('haze_col:')
    out.extend(db_lines([(C_SEA << 4) | C_SKY] * 8))    # cyan su cielo
    out.extend(db_lines([(C_SKY << 4) | C_SEA] * 8))    # cielo su cyan
    out.append('haze_col_storm:')
    out.extend(db_lines([(C_SKY << 4) | C_SKY_STORM] * 8))
    out.extend(db_lines([(C_SKY_STORM << 4) | C_SKY] * 8))
    # isola: 8 tile (4x2), pattern + colori nelle due varianti meteo
    for row in ISLAND:
        assert len(row) == 32, 'riga isola da %d colonne' % len(row)
    out.append('island_pat:')
    for half in range(2):
        for side in range(4):
            block = [ISLAND[half * 8 + y][side * 8:side * 8 + 8]
                     for y in range(8)]
            out.extend(db_lines(rows_to_bytes(block)))
    out.append('island_col:')
    out.extend(db_lines([(C_ISLAND << 4) | C_SEA] * 64))
    out.append('island_col_storm:')
    out.extend(db_lines([(C_ISLAND << 4) | C_SKY] * 64))
    # tratte: tabella + blocchi
    out.append('dest_tab:')
    for k in range(len(DESTS)):
        out.append('        dw  dest%d_pat, dest%d_row' % (k, k))
    for k, (dpat, drow, _) in enumerate(dests):
        out.append('; "%s"' % DESTS[k])
        out.append('dest%d_pat:' % k)
        out.extend(db_lines(dpat))
        out.append('dest%d_row:' % k)
        out.extend(db_lines(drow))
    out.append('')

    dst = os.path.join(ROOT, 'src', 'sky_data.asm')
    with open(dst, 'w', newline='\n') as f:
        f.write('\n'.join(out))
    print('scritto %s' % dst)

    # preview con la prima tratta montata
    pv_pat = [list(p) for p in pat]
    dpat0, drow0, slot_of0 = dests[0]
    for ch, slot in slot_of0.items():
        pv_pat[slot] = rows_to_bytes(GLYPHS[ch])
    pv_rows = [list(r) for r in rows]
    pv_rows[TEXT_ROW] = list(drow0)
    preview(pv_pat, col, pv_rows)


def preview(pat, col, rows):
    try:
        from PIL import Image
    except ImportError:
        print('PIL non presente: salto la preview')
        return
    img = Image.new('RGB', (256, 96), PAL[C_SKY])
    for r in range(8):
        for c in range(32):
            t = rows[r][c]
            for y in range(8):
                byte = pat[t][y]
                fg = col[t][y] >> 4
                bg = col[t][y] & 15
                for bit in range(8):
                    on = byte & (0x80 >> bit)
                    img.putpixel((c * 8 + bit, r * 8 + y),
                                 PAL[fg] if on else PAL[bg])
    # righe 8-9: foschia
    haze = [rows_to_bytes(HAZE0), rows_to_bytes(HAZE1)]
    hcol = [((C_SEA << 4) | C_SKY), ((C_SKY << 4) | C_SEA)]
    for hr in range(2):
        for c in range(32):
            for y in range(8):
                byte = haze[hr][y]
                fg, bg = hcol[hr] >> 4, hcol[hr] & 15
                for bit in range(8):
                    on = byte & (0x80 >> bit)
                    img.putpixel((c * 8 + bit, 64 + hr * 8 + y),
                                 PAL[fg] if on else PAL[bg])
    dst = os.path.join(ROOT, 'build', 'sky_preview.png')
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.resize((768, 288), Image.NEAREST).save(dst)
    print('scritta preview %s' % dst)


if __name__ == '__main__':
    main()
