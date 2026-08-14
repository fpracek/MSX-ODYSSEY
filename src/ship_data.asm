; GENERATO da tools/gen_ship.py - NON MODIFICARE A MANO
SHIP_C_HULL equ 10
SHIP_C_SAIL equ 15
ship_patterns:
; hull sx
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,060h,070h,03Fh,01Fh,00Fh,003h,000h
        db  001h,001h,001h,001h,001h,001h,001h,001h,001h,001h,001h,0FFh,0FFh,0FFh,0FFh,000h
; hull dx
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0FFh,0FFh,0FFh,0FFh,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,018h,0F8h,0FEh,0F0h,0C0h,000h
; sail sx
        db  000h,007h,00Fh,00Fh,00Fh,00Fh,00Fh,007h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,0FEh,0FEh,0FEh,0FEh,0FEh,0FEh,0FEh,000h,000h,000h,000h,000h,000h,000h,000h
; sail dx
        db  070h,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,080h,0C0h,0C0h,0C0h,0C0h,0C0h,080h,000h,000h,000h,000h,000h,000h,000h,000h
; fulmine (pattern 16)
        db  003h,006h,003h,001h,003h,006h,00Ch,007h,001h,000h,001h,003h,006h,003h,001h,000h
        db  000h,000h,000h,080h,000h,000h,000h,000h,080h,0C0h,080h,000h,000h,000h,080h,0C0h
; schiuma (pattern 20)
        db  000h,000h,000h,000h,000h,000h,000h,000h,008h,023h,054h,093h,068h,027h,058h,024h
        db  000h,000h,000h,000h,000h,000h,000h,000h,040h,010h,0A8h,024h,058h,090h,068h,090h
; mostro marino, collo (pattern 24)
        db  007h,00Fh,00Eh,00Fh,007h,007h,00Fh,00Fh,01Fh,01Fh,03Fh,04Fh,087h,04Fh,03Fh,05Fh
        db  0E0h,0F0h,070h,0F0h,0E0h,0E0h,0F0h,0F0h,0F8h,0F8h,0FCh,0F2h,0E1h,0F2h,0FCh,0FAh
; gabbiano ali su (pattern 28)
        db  000h,000h,000h,030h,048h,084h,003h,001h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,030h,048h,084h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
; gabbiano ali giu (pattern 32)
        db  000h,000h,000h,000h,003h,03Ch,040h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,0F0h,008h,000h,000h,000h,000h,000h,000h,000h,000h,000h
; nave lontana (pattern 36)
        db  000h,000h,000h,002h,003h,007h,003h,002h,03Fh,01Fh,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,080h,000h,000h,0F0h,0E0h,000h,000h,000h,000h,000h,000h
; mostro marino, testa A (pattern 40)
        db  003h,00Fh,01Fh,03Dh,03Fh,01Ch,00Dh,007h,003h,003h,007h,007h,003h,003h,007h,007h
        db  0C0h,0F0h,0F8h,0BCh,0FCh,038h,0B0h,0E0h,0C0h,0C0h,0E0h,0E0h,0C0h,0C0h,0E0h,0E0h
; mostro marino, testa B (pattern 44)
        db  000h,003h,007h,00Fh,00Fh,007h,003h,001h,003h,007h,007h,007h,003h,003h,007h,007h
        db  0F0h,0FCh,0FEh,06Fh,0FFh,00Eh,06Ch,0F8h,0C0h,080h,0E0h,0E0h,0C0h,0C0h,0E0h,0E0h
; piovra, testa A (pattern 48)
        db  007h,01Fh,03Fh,07Fh,067h,067h,0FFh,0FFh,07Fh,03Eh,01Ch,000h,000h,000h,000h,000h
        db  0E0h,0F8h,0FCh,0FEh,0E6h,0E6h,0FFh,0FFh,0FEh,07Ch,038h,000h,000h,000h,000h,000h
; piovra, testa B (pattern 52)
        db  000h,007h,01Fh,03Fh,067h,067h,07Fh,0FFh,07Fh,03Dh,00Ch,000h,000h,000h,000h,000h
        db  000h,0E0h,0F8h,0FCh,0E6h,0E6h,0FEh,0FFh,0FEh,0BCh,030h,000h,000h,000h,000h,000h
; piovra, tentacoli (pattern 56)
        db  03Fh,05Bh,049h,09Bh,091h,052h,04Ah,092h,092h,049h,049h,092h,049h,092h,044h,024h
        db  0FCh,06Ch,024h,032h,022h,04Ah,048h,066h,022h,024h,024h,048h,024h,044h,090h,024h
ship_bob:
        db  2,3,3,4,4,4,3,3,2,1,1,0,0,0,1,1
