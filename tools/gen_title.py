#!/usr/bin/env python3
"""
ODYSSEY - il title screen (bitmap SC2 pre-renderizzata)

Stile silhouette, il piu' d'effetto possibile sul TMS9918:
  - cielo al tramonto a bande sfumate con dither (nero -> rosso
    scuro -> rosso -> rosa -> oro all'orizzonte)
  - un SOLE enorme semi-immerso, bordo oro e cuore bianco
  - la triremi NERA in controluce sul disco del sole, con Ulisse
    in piedi a prua, lancia in pugno; remi immersi, sartie
  - la scia dorata del sole sul mare scuro, onde a trattini
  - "THE ODYSSEY" in oro con fregio a meandro, "PRESS FIRE"
Output: src/title_pat.bin + src/title_col.bin (banchi 20-21).
"""
import os
from gen_map import Raster, encode_sc2, rnd
from gen_sky import GLYPHS, PAL

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

HORIZON = 112


def sky_color(x, y):
    """Gradiente del tramonto con transizioni a dither."""
    bands = [(48, 1), (66, 6), (86, 8), (100, 9), (108, 10), (HORIZON, 11)]
    prev_end = 0
    prev_c = 1
    for end, c in bands:
        if y < end:
            # dither negli ultimi 8px della banda verso la successiva
            depth = end - y
            if depth <= 8 and rnd(x, y, 21) < (8 - depth) / 10.0:
                idx = bands.index((end, c))
                if idx + 1 < len(bands):
                    return bands[idx + 1][1]
            return c
        prev_end, prev_c = end, c
    return 11


def text2x(r, cx, y, s, c):
    """Testo coi glifi di gioco raddoppiati (16x16 per lettera)."""
    x = cx - len(s) * 8
    for ch in s:
        if ch != ' ':
            g = GLYPHS[ch]
            for gy in range(8):
                for gx in range(8):
                    if g[gy][gx] == '#':
                        for dy in range(2):
                            for dx in range(2):
                                r.put(x + gx * 2 + dx, y + gy * 2 + dy, c)
        x += 16


def meander(r, x0, x1, y, c):
    """Fregio greco semplificato: doppia linea con chiavi."""
    for x in range(x0, x1):
        r.put(x, y, c)
        r.put(x, y + 5, c)
    for x in range(x0, x1 - 6, 8):
        for dy in range(1, 5):
            r.put(x, y + dy, c)
        r.put(x + 1, y + 2, c)
        r.put(x + 2, y + 2, c)
        r.put(x + 2, y + 3, c)


def draw_title():
    r = Raster()
    # cielo
    for y in range(HORIZON):
        for x in range(256):
            r.px[y][x] = sky_color(x, y)
    # sole: disco oro con cuore bianco, semi-immerso
    for y in range(HORIZON - 46, HORIZON):
        for x in range(256):
            dx, dy = x - 128, y - HORIZON
            if dx * dx + dy * dy <= 46 * 46:
                r.px[y][x] = 11
            if dx * dx + dy * dy <= 30 * 30:
                r.px[y][x] = 15
    # mare: scuro, trattini d'onda, scia dorata sotto il sole
    for y in range(HORIZON, 172):
        for x in range(256):
            c = 1
            glit = 4 + (y - HORIZON) * 0.5
            if abs(x - 128) < glit and rnd(x, y, 22) < 0.4:
                c = 11 if rnd(x, y, 23) < 0.6 else 10
            elif rnd(x, y, 24) < 0.12 - (y - HORIZON) * 0.001:
                c = 8 if y < HORIZON + 20 else 6
            r.px[y][x] = c
    for y in range(172, 192):
        for x in range(256):
            r.px[y][x] = 1
    # la triremi in silhouette sul sole
    for dx in range(-50, 51):
        x = 128 + dx
        top = int(108 - max(0, abs(dx) - 40) * 1.5)
        bot = int(121 - max(0, abs(dx) - 34) * 0.9)
        for y in range(top, max(bot, top) + 1):
            r.put(x, y, 1)
    for y in range(64, 110):            # albero
        r.put(126, y, 1)
        r.put(127, y, 1)
    for x in range(94, 161):            # pennone
        r.put(x, 68, 1)
        r.put(x, 69, 1)
    for y in range(70, 103):            # vela quadra, appena svasata
        half = int(22 + (y - 70) * 0.12)
        for x in range(127 - half, 127 + half):
            r.put(x, y, 1)
    r.line(100, 69, 84, 109, 1)         # sartie
    r.line(154, 69, 170, 109, 1)
    for i in range(8):                  # remi
        x0 = 86 + i * 11
        r.line(x0, 120, x0 - 6, 130, 1)
    # Ulisse a prua, lancia in pugno (piu' grande e leggibile)
    r.disc(168, 95, 3, 1)               # capo
    for dx in range(-1, 2):             # corpo
        r.line(168 + dx, 99, 168 + dx, 112, 1)
    r.line(168, 112, 164, 119, 1)       # gambe
    r.line(168, 112, 172, 119, 1)
    r.line(175, 82, 175, 118, 1)        # lancia
    r.line(176, 82, 176, 118, 1)
    r.line(168, 103, 175, 99, 1)        # braccio
    # gabbiani in controluce
    for gx, gy in ((58, 66), (76, 58), (196, 62)):
        r.line(gx - 4, gy + 2, gx, gy, 1)
        r.line(gx, gy, gx + 4, gy + 2, 1)
    # titolo e fregio
    text2x(r, 128, 14, 'THE ODYSSEY', 11)
    meander(r, 40, 216, 36, 6)
    # invito
    r.text_c(128, 178, 'PRESS FIRE', 15)
    return r


def main():
    r = draw_title()
    pat, col = encode_sc2(r)
    with open(os.path.join(ROOT, 'src', 'title_pat.bin'), 'wb') as f:
        f.write(pat)
    with open(os.path.join(ROOT, 'src', 'title_col.bin'), 'wb') as f:
        f.write(col)
    print('scritto title screen (pattern+colori) in src/')
    try:
        from PIL import Image
    except ImportError:
        print('PIL non presente: salto la preview')
        return
    img = Image.new('RGB', (256, 192))
    for y in range(192):
        for x in range(256):
            img.putpixel((x, y), PAL[r.px[y][x]])
    dst = os.path.join(ROOT, 'build', 'title_preview.png')
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.resize((768, 576), Image.NEAREST).save(dst)
    print('scritta preview %s' % dst)


if __name__ == '__main__':
    main()
