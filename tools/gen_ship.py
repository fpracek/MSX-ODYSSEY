#!/usr/bin/env python3
"""
ODYSSEY - generatore della nave (triremi, 32x16, 2 layer di sprite)

Layer: scafo+albero (legno, colore 10) e vela+pennone (bianco, 15).
Ogni layer sono 2 sprite 16x16 affiancati -> 4 sprite sulle stesse
linee: ESATTAMENTE il limite di 4 sprite/linea del TMS9918. Finche'
la nave e' da sola sulle sue linee va bene; quando arriveranno nemici
navali bisognera' passare al multiplexing (rotazione slot di Sam.Pr).

Output: src/ship_data.asm
  - ship_patterns: 4 pattern 16x16 (32 byte l'uno), ordine:
    scafo sx, scafo dx, vela sx, vela dx (scafo prima = sopra,
    cosi' l'albero passa davanti alla vela)
  - SHIP_C_HULL / SHIP_C_SAIL: colori dei layer
  - ship_bob: 16 offset di beccheggio (sinusoide, ampiezza 2px)
Preview: build/ship_preview.png (serve PIL)
"""
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PAL = {
    0:  (0, 0, 0), 1: (0, 0, 0), 2: (33, 200, 66), 3: (94, 220, 120),
    4:  (84, 85, 237), 5: (125, 118, 252), 6: (212, 82, 77),
    7:  (66, 235, 245), 8: (252, 85, 84), 9: (255, 121, 120),
    10: (212, 193, 84), 11: (230, 206, 128), 12: (33, 176, 59),
    13: (201, 91, 186), 14: (204, 204, 204), 15: (255, 255, 255),
}

C_HULL = 10     # legno (dark yellow)
C_SAIL = 15     # vela (bianco)

# 32x16: '.'=trasparente, H=scafo, M=albero (layer scafo), S=vela
ART = [
    '.' * 15 + 'M' + '.' + 'SSS' + '.' * 12,          # pennone in testa
    '.' * 5 + 'S' * 10 + 'M' + 'S' * 9 + '.' * 7,
    '.' * 4 + 'S' * 11 + 'M' + 'S' * 10 + '.' * 6,
    '.' * 4 + 'S' * 11 + 'M' + 'S' * 10 + '.' * 6,
    '.' * 4 + 'S' * 11 + 'M' + 'S' * 10 + '.' * 6,
    '.' * 4 + 'S' * 11 + 'M' + 'S' * 10 + '.' * 6,
    '.' * 4 + 'S' * 11 + 'M' + 'S' * 10 + '.' * 6,
    '.' * 5 + 'S' * 10 + 'M' + 'S' * 9 + '.' * 7,
    '.' * 15 + 'M' + '.' * 16,
    '.HH' + '.' * 12 + 'M' + '.' * 16,                # poppa ricurva
    '.HHH' + '.' * 11 + 'M' + '.' * 11 + 'HH' + '...',  # prua che sale
    '..' + 'H' * 27 + '...',                          # ponte
    '...' + 'H' * 28 + '.',                           # fiancata + ariete
    '....' + 'H' * 24 + '....',
    '......' + 'H' * 20 + '......',
    '.' * 32,
]

LAYERS = [('hull', set('HM'), C_HULL), ('sail', set('S'), C_SAIL)]

# fulmine 16x16: zigzag che entra dall'alto al centro ed esce in basso
BOLT = ['......##........',
        '.....##.........',
        '......##........',
        '.......##.......',
        '......##........',
        '.....##.........',
        '....##..........',
        '.....###........',
        '.......##.......',
        '........##......',
        '.......##.......',
        '......##........',
        '.....##.........',
        '......##........',
        '.......##.......',
        '........##......']

# schiuma d'avviso: il mare ribolle dove sta per emergere lo scoglio
FOAM = ['................',
        '................',
        '................',
        '................',
        '................',
        '................',
        '................',
        '................',
        '....#....#......',
        '..#...##...#....',
        '.#.#.#..#.#.#...',
        '#..#..##..#..#..',
        '.##.#....#.##...',
        '..#..####..#....',
        '.#.##....##.#...',
        '..#..#..#..#....']

# il collo del mostro marino che emerge (base, con l'acqua smossa)
SERP_BODY = ['.....######.....',
             '....########....',
             '....###..###....',
             '....########....',
             '.....######.....',
             '.....######.....',
             '....########....',
             '....########....',
             '...##########...',
             '...##########...',
             '..############..',
             '.#..########..#.',
             '#....######....#',
             '.#..########..#.',
             '..############..',
             '.#.##########.#.']

# la testa del serpente di mare, due frame d'ondeggio
SERP_HEAD1 = ['......####......',
              '....########....',
              '...##########...',
              '..####.##.####..',
              '..############..',
              '...###....###...',
              '....##.##.##....',
              '.....######.....',
              '......####......',
              '......####......',
              '.....######.....',
              '.....######.....',
              '......####......',
              '......####......',
              '.....######.....',
              '.....######.....']
SERP_HEAD2 = ['........####....',
              '......########..',
              '.....##########.',
              '....####.##.####',
              '....############',
              '.....###....###.',
              '......##.##.##..',
              '.......######...',
              '......####......',
              '.....####.......',
              '.....######.....',
              '.....######.....',
              '......####......',
              '......####......',
              '.....######.....',
              '.....######.....']

# la PIOVRA delle acque aperte (il mostro delle tratte normali:
# Scilla, nello stretto, e' un'altra cosa - tre teste)
OCTO_H1 = ['.....######.....',
           '...##########...',
           '..############..',
           '.##############.',
           '.##..######..##.',
           '.##..######..##.',
           '################',
           '################',
           '.##############.',
           '..#####..#####..',
           '...###....###...',
           '................',
           '................',
           '................',
           '................',
           '................']
OCTO_H2 = ['................',
           '.....######.....',
           '...##########...',
           '..############..',
           '.##..######..##.',
           '.##..######..##.',
           '.##############.',
           '################',
           '.##############.',
           '..####.##.####..',
           '....##....##....',
           '................',
           '................',
           '................',
           '................',
           '................']
OCTO_BODY = ['..############..',
             '.#.##.##.##.##..',
             '.#..#..#..#..#..',
             '#..##.##..##..#.',
             '#..#...#..#...#.',
             '.#.#..#..#..#.#.',
             '.#..#.#..#..#...',
             '#..#..#..##..##.',
             '#..#..#...#...#.',
             '.#..#..#..#..#..',
             '.#..#..#..#..#..',
             '#..#..#..#..#...',
             '.#..#..#..#..#..',
             '#..#..#..#...#..',
             '.#...#..#..#....',
             '..#..#....#..#..']

# gabbiano, 2 frame di battito d'ali
GULL1 = ['................',
         '................',
         '................',
         '..##......##....',
         '.#..#....#..#...',
         '#....#..#....#..',
         '......##........',
         '.......#........',
         '................',
         '................',
         '................',
         '................',
         '................',
         '................',
         '................',
         '................']
GULL2 = ['................',
         '................',
         '................',
         '................',
         '......##........',
         '..####..####....',
         '.#..........#...',
         '................',
         '................',
         '................',
         '................',
         '................',
         '................',
         '................',
         '................',
         '................']

# la nave vista da lontano (approdo): sagoma minuscola
SHIP_FAR = ['................',
            '................',
            '................',
            '......#.........',
            '......##........',
            '.....####.......',
            '......##........',
            '......#.........',
            '..##########....',
            '...########.....',
            '................',
            '................',
            '................',
            '................',
            '................',
            '................']


def sprite16(art, chars, col0, row0):
    """32 byte di un pattern 16x16: colonna sx (16 righe) poi dx."""
    out = []
    for half in (0, 8):
        for y in range(16):
            b = 0
            for bit in range(8):
                if art[row0 + y][col0 + half + bit] in chars:
                    b |= 0x80 >> bit
            out.append(b)
    return out


def main():
    for r in ART:
        assert len(r) == 32, 'riga art da %d colonne: %r' % (len(r), r)

    out = []
    out.append('; GENERATO da tools/gen_ship.py - NON MODIFICARE A MANO')
    out.append('SHIP_C_HULL equ %d' % C_HULL)
    out.append('SHIP_C_SAIL equ %d' % C_SAIL)
    out.append('ship_patterns:')
    for name, chars, _ in LAYERS:
        for col0 in (0, 16):
            data = sprite16(ART, chars, col0, 0)
            out.append('; %s %s' % (name, 'sx' if col0 == 0 else 'dx'))
            for i in range(0, 32, 16):
                out.append('        db  ' +
                           ','.join('0%02Xh' % b for b in data[i:i + 16]))
    # pattern extra: fulmine (16), schiuma (20), scoglio (24),
    # gabbiano su/giu' (28/32) - contigui dopo la nave
    for name, art in [('fulmine (pattern 16)', BOLT),
                      ('schiuma (pattern 20)', FOAM),
                      ('mostro marino, collo (pattern 24)', SERP_BODY),
                      ('gabbiano ali su (pattern 28)', GULL1),
                      ('gabbiano ali giu (pattern 32)', GULL2),
                      ('nave lontana (pattern 36)', SHIP_FAR),
                      ('mostro marino, testa A (pattern 40)', SERP_HEAD1),
                      ('mostro marino, testa B (pattern 44)', SERP_HEAD2),
                      ('piovra, testa A (pattern 48)', OCTO_H1),
                      ('piovra, testa B (pattern 52)', OCTO_H2),
                      ('piovra, tentacoli (pattern 56)', OCTO_BODY)]:
        out.append('; ' + name)
        data = sprite16(art, set('#'), 0, 0)
        for i in range(0, 32, 16):
            out.append('        db  ' +
                       ','.join('0%02Xh' % b for b in data[i:i + 16]))
    # beccheggio: sinusoide a 16 passi, ampiezza 2px (valori 0..4)
    bob = [round(2 + 2 * math.sin(2 * math.pi * i / 16)) for i in range(16)]
    out.append('ship_bob:')
    out.append('        db  ' + ','.join('%d' % v for v in bob))
    out.append('')

    dst = os.path.join(ROOT, 'src', 'ship_data.asm')
    with open(dst, 'w', newline='\n') as f:
        f.write('\n'.join(out))
    print('scritto %s' % dst)

    preview()


def preview():
    try:
        from PIL import Image
    except ImportError:
        print('PIL non presente: salto la preview')
        return
    img = Image.new('RGB', (32, 16), PAL[4])          # mare dietro
    for y, row in enumerate(ART):
        for x, ch in enumerate(row):
            for _, chars, col in LAYERS:
                if ch in chars:
                    img.putpixel((x, y), PAL[col])
    dst = os.path.join(ROOT, 'build', 'ship_preview.png')
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.resize((320, 160), Image.NEAREST).save(dst)
    print('scritta preview %s' % dst)


if __name__ == '__main__':
    main()
