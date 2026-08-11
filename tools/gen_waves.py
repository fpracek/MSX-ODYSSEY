#!/usr/bin/env python3
"""
ODYSSEY - generatore delle bande del mare (v2: 4 bande)

Genera src/waves_data.asm: per ogni banda (A2=vicinissima, A=vicina,
B=media, C=orizzonte)
  - WAVES_x_W        equ  larghezza in tile (potenza di 2)
  - wavesX_rowcol    8 byte colore (fg<<4|bg) per riga-pixel, STATICI
  - wavesX_pst       tabella di 8 puntatori ai preshift
  - wavesX_ps        8 preshift x W tile x 8 byte di pattern

REGOLA FONDAMENTALE (e' cio' che rende lo scroll "gratis" sul TMS9918):
la color table NON viene mai riscritta a runtime. Per ogni riga-pixel di
una banda c'e' UNA sola coppia fg/bg valida su tutta la larghezza, cosi'
lo scroll richiede solo gli 8 byte di pattern per tile.

Meccanica runtime (vedi main.asm): offset o = k*8+s con s=subpixel,
k=tile. Il tile t mostra preshift_s[(t+k) mod W]: il blast e' due run
OUTI contigue (da k a W-1, poi da 0 a k-1) sulla stessa destinazione
VRAM sequenziale.

Layout schermo: C righe 10-11, B 12-15, A 16-19, A2 20-23.
A e A2 vanno alla stessa velocita' (stessa "distanza") ma con texture
diverse: varieta' verticale senza costo di parallasse.

Output extra: build/waves_preview.png (mock dello schermo, serve PIL).
"""
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# palette TMS9918 (indice -> RGB), stessa di gen_gfx.py di Sam.Pr
PAL = {
    0:  (0, 0, 0),
    1:  (0, 0, 0),
    2:  (33, 200, 66),
    3:  (94, 220, 120),
    4:  (84, 85, 237),
    5:  (125, 118, 252),
    6:  (212, 82, 77),
    7:  (66, 235, 245),
    8:  (252, 85, 84),
    9:  (255, 121, 120),
    10: (212, 193, 84),
    11: (230, 206, 128),
    12: (33, 176, 59),
    13: (201, 91, 186),
    14: (204, 204, 204),
    15: (255, 255, 255),
}


def rnd(x, y, salt=0):
    """Pseudo-random deterministico per pixel: periodico in x per
    costruzione (x e' gia' ridotto mod larghezza dal chiamante)."""
    n = (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
    n &= 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n >> 8) & 0xFFFF) / 65536.0


# ------------------------------------------------------------------
# texture: f(x, y, width_px) -> True se il pixel e' fg
# le lambda delle sinusoidi devono dividere width_px (seamless wrap)
# ------------------------------------------------------------------

def tex_a2(x, y, w):
    """Vicinissima: onde grosse, creste spesse 2px, molta schiuma."""
    h1 = 2.2 + 1.8 * math.sin(2 * math.pi * x / (w / 2))
    h2 = 4.8 + 1.3 * math.sin(2 * math.pi * x / (w / 4) + 2.3)
    if abs(y - h1) < 0.95:                # cresta spessa
        return True
    if abs(y - h2) < 0.75:
        return True
    if y >= 6 and (x + 2 * y) % 3 == 0:   # schiuma in basso, non fitta
        return True
    if rnd(x, y, 4) < 0.04:
        return True
    return False


def tex_a(x, y, w):
    """Vicina: due creste sottili sfasate + scintillii."""
    h1 = 2.0 + 1.6 * math.sin(2 * math.pi * x / (w / 2))
    h2 = 4.8 + 1.2 * math.sin(2 * math.pi * x / (w / 4) + 1.7)
    if abs(y - h1) < 0.55:
        return True
    if abs(y - h2) < 0.55:
        return True
    if y >= 6 and (x + y) % 4 == 0:       # dither di schiuma leggero
        return True
    if rnd(x, y, 1) < 0.03:
        return True
    return False


def tex_b(x, y, w):
    """Media: cresta morbida con armonica + gocce sotto la cresta."""
    h = 3.5 + 2.0 * math.sin(2 * math.pi * x / w) \
            + 0.7 * math.sin(2 * math.pi * x / (w / 4) + 0.9)
    if abs(y - h) < 0.5:
        return True
    if y > h and x % 4 == 2 and y % 2 == 1:
        return True
    if rnd(x, y, 2) < 0.015:
        return True
    return False


def tex_c(x, y, w):
    """Orizzonte: trattini di luce sfalsati sul cyan."""
    v1 = math.sin(2 * math.pi * x / (w / 2))
    v2 = math.sin(2 * math.pi * x / (w / 2) + math.pi)
    if y in (2, 3) and v1 > 0.55:
        return True
    if y in (4, 5) and v2 > 0.65:
        return True
    if y == 1 and rnd(x, y, 3) < 0.05:
        return True
    return False


# colors: 8 coppie (fg, bg), una per riga-pixel - STATICHE per contratto
BANDS = [
    dict(name='A', tiles=16, tex=tex_a,
         colors=[(15, 4), (7, 4), (5, 4), (7, 4),
                 (15, 4), (5, 4), (7, 4), (7, 4)]),
    dict(name='A2', tiles=16, tex=tex_a2,
         colors=[(15, 4), (15, 4), (7, 4), (7, 4),
                 (15, 4), (5, 4), (7, 4), (15, 4)]),
    dict(name='B', tiles=8, tex=tex_b,
         colors=[(15, 4), (15, 4), (7, 4), (5, 4),
                 (7, 4), (5, 4), (7, 4), (5, 4)]),
    dict(name='C', tiles=4, tex=tex_c,
         colors=[(15, 7), (15, 7), (15, 7), (5, 7),
                 (15, 7), (5, 7), (5, 7), (5, 7)]),
]


def preshift_bytes(tex, w_px, tiles, s):
    """Pattern di tutti i tile della banda, texture spostata di s pixel."""
    out = []
    for j in range(tiles):
        for y in range(8):
            b = 0
            for bit in range(8):
                x = (j * 8 + bit + s) % w_px
                if tex(x, y, w_px):
                    b |= 0x80 >> bit
            out.append(b)
    return out


def db_lines(data, per_line=16):
    lines = []
    for i in range(0, len(data), per_line):
        chunk = data[i:i + per_line]
        lines.append('        db  ' + ','.join('0%02Xh' % b for b in chunk))
    return lines


def main():
    # override da CLI: --tiles A,A2,B,C (potenze di 2, max 32)
    for arg in sys.argv[1:]:
        if arg.startswith('--tiles='):
            vals = [int(v) for v in arg.split('=')[1].split(',')]
            for band, v in zip(BANDS, vals):
                band['tiles'] = v

    out = []
    out.append('; GENERATO da tools/gen_waves.py - NON MODIFICARE A MANO')
    out.append('; colori statici + 8 preshift per banda: a runtime si')
    out.append('; riscrivono SOLO i pattern (vedi commento nel generatore)')
    total = 0
    for band in BANDS:
        n = band['name']
        w = band['tiles']
        assert w & (w - 1) == 0, 'W deve essere potenza di 2: %s=%d' % (n, w)
        assert 2 <= w <= 32, 'W fuori range: %s=%d' % (n, w)
        assert len(band['colors']) == 8
        w_px = w * 8
        out.append('')
        out.append('WAVES_%s_W equ %d' % (n, w))
        rowcol = [(fg << 4) | bg for fg, bg in band['colors']]
        out.append('waves%s_rowcol:' % n)
        out.extend(db_lines(rowcol))
        out.append('waves%s_pst:' % n)
        for s in range(8):
            out.append('        dw  waves%s_ps+%d' % (n, s * w_px))
        out.append('waves%s_ps:' % n)
        for s in range(8):
            data = preshift_bytes(band['tex'], w_px, w, s)
            out.append('; preshift %d' % s)
            out.extend(db_lines(data))
            total += len(data)
    # blocchi colore ESPANSI della banda C per il recolor del meteo:
    # unica eccezione alla regola "colori mai riscritti" - un evento
    # raro (cambio sereno/tempesta), non un costo per frame
    bandC = [b for b in BANDS if b['name'] == 'C'][0]
    storm_c = [(15, 5), (15, 5), (15, 5), (4, 5),
               (15, 5), (4, 5), (4, 5), (4, 5)]
    out.append('')
    out.append('; colori banda C espansi (recolor meteo, %d tile)'
               % bandC['tiles'])
    out.append('wavesC_colx:')
    rc = [(fg << 4) | bg for fg, bg in bandC['colors']] * bandC['tiles']
    out.extend(db_lines(rc))
    out.append('wavesC_colx_storm:')
    rc = [(fg << 4) | bg for fg, bg in storm_c] * bandC['tiles']
    out.extend(db_lines(rc))
    out.append('')
    out.append('; totale dati pattern: %d byte' % total)
    out.append('')

    dst = os.path.join(ROOT, 'src', 'waves_data.asm')
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    with open(dst, 'w', newline='\n') as f:
        f.write('\n'.join(out))
    print('scritto %s (%d byte di pattern)' % (dst, total))

    preview()


def preview():
    """Mock dello schermo in build/waves_preview.png (opzionale)."""
    try:
        from PIL import Image
    except ImportError:
        print('PIL non presente: salto la preview')
        return
    img = Image.new('RGB', (256, 192), PAL[5])          # cielo
    rows = {'C': (10, 2), 'B': (12, 4), 'A': (16, 4), 'A2': (20, 4)}
    for band in BANDS:
        n = band['name']
        w_px = band['tiles'] * 8
        row0, nrows = rows[n]
        for r in range(nrows):
            for y in range(8):
                fg, bg = band['colors'][y]
                for x in range(256):
                    on = band['tex'](x % w_px, y, w_px)
                    img.putpixel((x, row0 * 8 + r * 8 + y),
                                 PAL[fg] if on else PAL[bg])
    dst = os.path.join(ROOT, 'build', 'waves_preview.png')
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.resize((768, 576), Image.NEAREST).save(dst)
    print('scritta preview %s' % dst)


if __name__ == '__main__':
    main()
