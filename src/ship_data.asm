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
; scoglio (pattern 24)
        db  003h,007h,00Fh,00Fh,01Fh,01Fh,03Fh,03Fh,07Fh,07Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
        db  000h,080h,0C0h,0E0h,0F0h,0F8h,0F8h,0FCh,0FCh,0FEh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
; gabbiano ali su (pattern 28)
        db  000h,000h,000h,030h,048h,084h,003h,001h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,030h,048h,084h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
; gabbiano ali giu (pattern 32)
        db  000h,000h,000h,000h,003h,03Ch,040h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,0F0h,008h,000h,000h,000h,000h,000h,000h,000h,000h,000h
; nave lontana (pattern 36)
        db  000h,000h,000h,002h,003h,007h,003h,002h,03Fh,01Fh,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,080h,000h,000h,0F0h,0E0h,000h,000h,000h,000h,000h,000h
ship_bob:
        db  2,3,3,4,4,4,3,3,2,1,1,0,0,0,1,1
