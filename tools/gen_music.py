#!/usr/bin/env python3
"""
ODYSSEY - musica del titolo (PSG, 3 canali)

Tema originale in MI frigio dominante (E F G# A B C D): la scala
"egea" con la seconda aumentata. Canale A = melodia, B = basso
ostinato in ottave (l'incalzare dei remi), C = bordone di quinte.

Formato stream: coppie (indice nota, durata in frame); indice 0 =
pausa; 0FFh seguito da dw = riavvolgi. I tre stream durano lo
stesso numero di frame: niente derive di fase.

Output: src/music_data.asm (tabella periodi + 3 stream).
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CLK = 3579545
EIGHTH = 12     # frame per croma (~150bpm a 60Hz, ~125 a 50Hz)

SEMI = {'C': -9, 'C#': -8, 'D': -7, 'D#': -6, 'E': -5, 'F': -4,
        'F#': -3, 'G': -2, 'G#': -1, 'A': 0, 'A#': 1, 'B': 2}


def period(name):
    """'E4' -> periodo PSG a 12 bit."""
    octv = int(name[-1])
    semi = SEMI[name[:-1]] + (octv - 4) * 12
    freq = 440.0 * (2.0 ** (semi / 12.0))
    p = int(round(CLK / (16.0 * freq)))
    assert 1 <= p <= 4095, '%s fuori range: %d' % (name, p)
    return p


# ------------------------------------------------------------------
# tema del TITOLO: 10 battute da 8 crome. (nota, crome)
# ------------------------------------------------------------------
MELODY = [
    ('E4', 4), ('F4', 2), ('G#4', 2),
    ('A4', 6), ('G#4', 2),
    ('F4', 2), ('E4', 2), ('F4', 2), ('G#4', 2),
    ('E4', 8),
    ('A4', 4), ('B4', 2), ('C5', 2),
    ('B4', 4), ('A4', 4),
    ('G#4', 2), ('A4', 2), ('B4', 2), ('G#4', 2),
    ('A4', 4), ('G#4', 2), ('F4', 2),
    ('E4', 2), ('F4', 2), ('D4', 2), ('F4', 2),
    ('E4', 8),
]

# fondamentale di ogni battuta (basso e bordone la seguono)
ROOTS = ['E', 'A', 'F', 'E', 'A', 'E', 'E', 'F', 'D', 'E']
FIFTH = {'E': 'B2', 'A': 'E3', 'F': 'C3', 'D': 'A2'}


# ------------------------------------------------------------------
# tema della PERGAMENA: arpeggi di lira, TEMPO DOPPIO (meta'
# velocita'), melodia che parte da SOL - inconfondibile rispetto
# al titolo (che parte da MI, incalzante, in frigio)
# ------------------------------------------------------------------
MAP_SLOW = 2            # moltiplicatore delle durate
MAP_MELODY = [
    ('G4', 4), ('A4', 2), ('B4', 2),
    ('A4', 4), ('G4', 2), ('E4', 2),
    ('D4', 4), ('E4', 2), ('G4', 2),
    ('E4', 8),
    ('B4', 4), ('A4', 2), ('G4', 2),
    ('A4', 4), ('B4', 2), ('D5', 2),
    ('B4', 4), ('A4', 2), ('G4', 2),
    ('E4', 8),
]
MAP_ROOTS = ['G', 'C', 'G', 'E', 'E', 'G', 'C', 'E']
TRIAD = {'E': ('E3', 'G3', 'B3'),
         'C': ('C3', 'E3', 'G3'),
         'G': ('G3', 'B3', 'D4')}


def build_streams():
    mel = [(n, d * EIGHTH) for n, d in MELODY]
    bass = []
    drone = []
    for r in ROOTS:
        for _ in range(4):          # crome alternate sulle ottave
            bass.append((r + '2', EIGHTH))
            bass.append((r + '3', EIGHTH))
        drone.append((FIFTH[r], 8 * EIGHTH))
    for s in (mel, bass, drone):
        assert sum(d for _, d in s) == len(ROOTS) * 8 * EIGHTH
    return mel, bass, drone


def build_map_streams():
    e = EIGHTH * MAP_SLOW
    mel = [(n, d * e) for n, d in MAP_MELODY]
    harp = []
    bass = []
    for r in MAP_ROOTS:
        t = TRIAD[r]
        for _ in range(2):          # arpeggio di lira: r,3a,5a,3a
            harp.append((t[0], e))
            harp.append((t[1], e))
            harp.append((t[2], e))
            harp.append((t[1], e))
        bass.append((r + '2', 8 * e))
    for s in (mel, harp, bass):
        assert sum(d for _, d in s) == len(MAP_ROOTS) * 8 * e
    return mel, harp, bass


def main():
    title = build_streams()
    mappa = build_map_streams()
    # tabella note condivisa fra i due brani
    names = []
    for song in (title, mappa):
        for s in song:
            for n, _ in s:
                if n not in names:
                    names.append(n)
    idx = {n: i + 1 for i, n in enumerate(names)}

    out = []
    out.append('; GENERATO da tools/gen_music.py - NON MODIFICARE A MANO')
    out.append('; titolo: MI frigio dominante; pergamena: lira in MI minore')
    out.append('mus_notes:')
    for n in names:
        out.append('        dw  %d              ; %s' % (period(n), n))
    streams = [('mus_chA', title[0]), ('mus_chB', title[1]),
               ('mus_chC', title[2]), ('map_chA', mappa[0]),
               ('map_chB', mappa[1]), ('map_chC', mappa[2])]
    for label, stream in streams:
        out.append('%s:' % label)
        line = []
        for n, d in stream:
            line.append('%d,%d' % (idx[n], d))
            if len(line) == 8:
                out.append('        db  ' + ','.join(line))
                line = []
        if line:
            out.append('        db  ' + ','.join(line))
        out.append('        db  0FFh')
        out.append('        dw  %s' % label)
    out.append('song_title:')
    out.append('        dw  mus_chA, mus_chB, mus_chC')
    out.append('song_map:')
    out.append('        dw  map_chA, map_chB, map_chC')
    out.append('')

    dst = os.path.join(ROOT, 'src', 'music_data.asm')
    with open(dst, 'w', newline='\n') as f:
        f.write('\n'.join(out))
    t1 = sum(d for _, d in title[0])
    t2 = sum(d for _, d in mappa[0])
    print('scritto %s (titolo %d frame ~%.0fs, pergamena %d frame ~%.0fs)'
          % (dst, t1, t1 / 60.0, t2, t2 / 60.0))


if __name__ == '__main__':
    main()
