#!/usr/bin/env python3
"""
ODYSSEY - tabelle di dissolvenza (fade) per gli schermi bitmap

Sul TMS9918 non c'e' palette: il fade si fa riscrivendo la color
table rimappando ogni byte (fg<<4|bg) verso il nero a gradini.
Catene di oscuramento sulla palette fissa (una applicazione = un
gradino): 15->14->4->1, 11->10->6->1, 7->5->4->1, ecc.

Emette 4 LUT da 256 byte (allineate) in src/fade_data.asm:
  fade_lut0 = identita' (colori pieni)
  fade_lut1..3 = sempre piu' scuro (la 3 e' praticamente nero)
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# un gradino di oscuramento per ogni colore TMS9918
DARK = {0: 0, 1: 1, 2: 12, 3: 2, 4: 1, 5: 4, 6: 1, 7: 5,
        8: 6, 9: 8, 10: 6, 11: 10, 12: 1, 13: 4, 14: 4, 15: 14}


def level(c, n):
    for _ in range(n):
        c = DARK[c]
    return c


def main():
    out = []
    out.append('; GENERATO da tools/gen_fade.py - NON MODIFICARE A MANO')
    out.append('; LUT di dissolvenza: byte colore -> byte oscurato')
    out.append('        ALIGN 256')
    for lv in range(4):
        out.append('fade_lut%d:' % lv)
        for base in range(0, 256, 16):
            row = []
            for lo in range(16):
                b = base + lo
                fg = level(b >> 4, lv)
                bg = level(b & 15, lv)
                row.append('0%02Xh' % ((fg << 4) | bg))
            out.append('        db  ' + ','.join(row))
    out.append('')

    dst = os.path.join(ROOT, 'src', 'fade_data.asm')
    with open(dst, 'w', newline='\n') as f:
        f.write('\n'.join(out))
    print('scritto %s (4 LUT da 256 byte)' % dst)


if __name__ == '__main__':
    main()
