#!/usr/bin/env python3
"""
ODYSSEY - la pergamena del viaggio (bitmap SCREEN 2 pre-renderizzata)

Per OGNI tratta genera una mappa completa 256x192: pergamena, isole
con i nomi, e la rotta a righe colorate:
  - tratte gia' percorse: linea PIENA rosso scuro (6)
  - la tratta che sta per iniziare: linea DOPPIA rosso vivo (8)
  - tratte future: puntini d'inchiostro (1)
La nave e' disegnata sull'isola di partenza della tratta corrente.

ROM illimitata = niente patch a runtime: 6 varianti complete da 12KB
(pattern 6KB + colori 6KB) nei banchi 8..19; il kernel copia quella
della tratta e aspetta FIRE/SPACE.

Output: src/mapK_pat.bin + src/mapK_col.bin (k=0..5) e una preview.
Vincolo SC2: max 2 colori per run orizzontale di 8 pixel - l'encoder
tiene i 2 piu' frequenti e rimappa gli altri per luminanza (la grafica
e' disegnata per non farlo quasi mai accadere).
"""
import os
from gen_sky import GLYPHS, PAL

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

C_PAPER = 11    # pergamena
C_EDGE = 10     # bordo/decorazioni
C_INK = 1       # inchiostro
C_DONE = 6      # rotta percorsa (rosso scuro)
C_CURR = 8      # tratta che inizia (rosso vivo)
C_ISLE = 12     # isole

# nodi del viaggio: nome, centro (x, y)
NODES = [('TROY', 30, 42),
         ('CYCLOPS', 92, 60),
         ('CIRCE', 160, 44),
         ('AEOLIA', 214, 78),
         ('SIRENS', 168, 112),
         ('SCYLLA', 98, 132),
         ('ITHACA', 36, 156)]
N_LEGS = len(NODES) - 1

# luminanza approssimata per la rimappatura dell'encoder
LUM = {1: 0, 6: 35, 8: 50, 12: 40, 10: 60, 11: 80, 15: 100,
       4: 30, 5: 55, 7: 70, 14: 75, 2: 45, 3: 65, 9: 60, 13: 50, 0: 0}


def rnd(x, y, salt=0):
    n = (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
    n &= 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n >> 8) & 0xFFFF) / 65536.0


class Raster:
    def __init__(self):
        self.px = [[C_PAPER] * 256 for _ in range(192)]

    def put(self, x, y, c):
        if 0 <= x < 256 and 0 <= y < 192:
            self.px[y][x] = c

    def rect(self, x0, y0, x1, y1, c):
        for x in range(x0, x1 + 1):
            self.put(x, y0, c)
            self.put(x, y1, c)
        for y in range(y0, y1 + 1):
            self.put(x0, y, c)
            self.put(x1, y, c)

    def disc(self, cx, cy, r, c):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.put(x, y, c)

    def line(self, x0, y0, x1, y1, c, dotted=False):
        dx = abs(x1 - x0)
        dy = -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx + dy
        i = 0
        while True:
            if not dotted or i % 5 < 2:
                self.put(x0, y0, c)
            if x0 == x1 and y0 == y1:
                return
            i += 1
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def text(self, x, y, s, c):
        for ch in s:
            if ch != ' ':
                g = GLYPHS[ch]
                for gy in range(8):
                    for gx in range(8):
                        if g[gy][gx] == '#':
                            self.put(x + gx, y + gy, c)
            x += 8

    def text_c(self, cx, y, s, c):
        self.text(cx - len(s) * 4, y, s, c)


def draw_map(leg):
    r = Raster()
    # pergamena: puntinatura sparsa + doppio bordo
    for y in range(192):
        for x in range(256):
            if rnd(x, y, 7) < 0.02:
                r.px[y][x] = C_EDGE
    r.rect(2, 2, 253, 189, C_EDGE)
    r.rect(5, 5, 250, 186, C_EDGE)
    # titolo
    r.text_c(128, 12, 'ODYSSEY', C_INK)
    # rotte (prima delle isole, che coprono gli estremi)
    for k in range(N_LEGS):
        _, x0, y0 = NODES[k]
        _, x1, y1 = NODES[k + 1]
        if k < leg:
            r.line(x0, y0, x1, y1, C_DONE)
        elif k == leg:
            r.line(x0, y0, x1, y1, C_CURR)
            r.line(x0, y0 + 1, x1, y1 + 1, C_CURR)   # doppia: in partenza
        else:
            r.line(x0, y0, x1, y1, C_INK, dotted=True)
    # isole + nomi
    for name, x, y in NODES:
        r.disc(x, y, 6, C_ISLE)
        r.text_c(x, y + 9, name, C_INK)
    # la nave sull'isola di partenza della tratta
    sx, sy = NODES[leg][1], NODES[leg][2] - 12
    ship = ['..#..', '..#..', '.###.', '#####', '.###.']
    for gy, row in enumerate(ship):
        for gx, ch in enumerate(row):
            if ch == '#':
                r.put(sx - 2 + gx, sy + gy, C_INK)
    # invito a salpare
    r.text(196, 172, 'SAIL', C_INK)
    return r


def encode_sc2(r):
    """Bitmap -> pattern (6144) + colori (6144), 2 colori per run 8x1."""
    pat = bytearray()
    col = bytearray()
    for third in range(3):
        for trow in range(8):
            for tcol in range(32):
                for py in range(8):
                    y = third * 64 + trow * 8 + py
                    run = r.px[y][tcol * 8:tcol * 8 + 8]
                    freq = {}
                    for c in run:
                        freq[c] = freq.get(c, 0) + 1
                    order = sorted(freq, key=lambda c: -freq[c])
                    bg = order[0]
                    fg = order[1] if len(order) > 1 else C_INK
                    b = 0
                    for i, c in enumerate(run):
                        if c != bg and c != fg:
                            c = fg if abs(LUM[c] - LUM[fg]) < \
                                abs(LUM[c] - LUM[bg]) else bg
                        if c == fg:
                            b |= 0x80 >> i
                    pat.append(b)
                    col.append((fg << 4) | bg)
    # l'ordine di scrittura (terzo, riga-tile, colonna, riga-pixel)
    # coincide gia' col layout SC2: tile contigui a 8 byte
    return pat, col


def main():
    for leg in range(N_LEGS):
        r = draw_map(leg)
        pat, col = encode_sc2(r)
        with open(os.path.join(ROOT, 'src', 'map%d_pat.bin' % leg),
                  'wb') as f:
            f.write(pat)
        with open(os.path.join(ROOT, 'src', 'map%d_col.bin' % leg),
                  'wb') as f:
            f.write(col)
    print('scritte %d mappe (pattern+colori) in src/' % N_LEGS)
    preview()


def preview():
    try:
        from PIL import Image
    except ImportError:
        print('PIL non presente: salto la preview')
        return
    r = draw_map(0)
    img = Image.new('RGB', (256, 192))
    for y in range(192):
        for x in range(256):
            img.putpixel((x, y), PAL[r.px[y][x]])
    dst = os.path.join(ROOT, 'build', 'map_preview.png')
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.resize((768, 576), Image.NEAREST).save(dst)
    print('scritta preview %s' % dst)


if __name__ == '__main__':
    main()
