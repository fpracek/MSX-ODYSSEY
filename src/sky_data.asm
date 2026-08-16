; GENERATO da tools/gen_sky.py - NON MODIFICARE A MANO
; cielo + sole + foschia + HUD + tratte: "TO CYCLOPS", "TO CIRCE", "TO AEOLIA", "TO SIRENS", "TO ITHACA", "SCYLLA AND CHARYBDIS"
N_DESTS equ 6
sky_pat:
        db  000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h
        db  007h,01Fh,03Fh,07Fh,07Fh,0FFh,0FFh,0FFh
        db  0E0h,0F8h,0FCh,0FEh,0FEh,0FFh,0FFh,0FFh
        db  0FFh,07Fh,07Fh,03Fh,01Fh,007h,000h,000h
        db  0FFh,0FEh,0FEh,0FCh,0F8h,0E0h,000h,000h
        db  018h,018h,03Ch,018h,03Ch,024h,024h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,048h,048h,000h,000h,000h
        db  000h,000h,07Eh,0FFh,0FFh,07Eh,000h,000h
sky_col:
        db  0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h
        db  0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h
        db  0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h
        db  0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h
        db  0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h
        db  0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h
        db  0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h
        db  0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h
        db  0B5h,0B5h,0B5h,0B5h,0B5h,0B5h,0B5h,0B5h
        db  0B5h,0B5h,0B5h,0B5h,0B5h,0B5h,0B5h,0B5h
        db  0B5h,0B5h,0B5h,0B5h,0B5h,0B5h,0B5h,0B5h
        db  0B5h,0B5h,0B5h,0B5h,0B5h,0B5h,0B5h,0B5h
        db  0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h
        db  0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h
        db  0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h,0F5h
        db  0B5h,0B5h,0B5h,0B5h,0B5h,0B5h,0B5h,0B5h
; variante tempesta: cielo scuro, sole nascosto
sky_col_storm:
        db  0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h
        db  0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h
        db  0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h
        db  0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h
        db  0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h
        db  0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h
        db  0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h
        db  0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h
        db  011h,011h,011h,011h,011h,011h,011h,011h
        db  011h,011h,011h,011h,011h,011h,011h,011h
        db  011h,011h,011h,011h,011h,011h,011h,011h
        db  011h,011h,011h,011h,011h,011h,011h,011h
        db  0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h
        db  0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h
        db  0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h,0F1h
        db  0B1h,0B1h,0B1h,0B1h,0B1h,0B1h,0B1h,0B1h
sky_rows:
        db  000h,00Ch,00Ch,00Ch,00Ch,00Ch,00Ch,00Ch,00Ch,00Ch,00Ch,00Ch,00Ch,000h,000h,000h
        db  000h,000h,000h,00Eh,00Eh,00Eh,00Eh,00Eh,00Eh,00Eh,00Eh,00Eh,00Eh,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,008h,009h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,00Ah,00Bh,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
haze_pat:
        db  088h,000h,022h,000h,088h,000h,022h,000h
        db  044h,000h,011h,000h,044h,000h,011h,000h
haze_col:
        db  075h,075h,075h,075h,075h,075h,075h,075h
        db  057h,057h,057h,057h,057h,057h,057h,057h
haze_col_storm:
        db  051h,051h,051h,051h,051h,051h,051h,051h
        db  015h,015h,015h,015h,015h,015h,015h,015h
island_pat:
        db  000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,003h,007h,00Fh,01Fh,03Fh
        db  000h,000h,000h,000h,080h,0C0h,0E0h,0F0h
        db  000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,001h,003h,00Fh,01Fh,03Fh,07Fh,0FFh
        db  0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
        db  0F8h,0FCh,0FEh,0FFh,0FFh,0FFh,0FFh,0FFh
        db  000h,000h,000h,000h,080h,0C0h,0E0h,0FFh
island_col:
        db  0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h
        db  0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h
        db  0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h
        db  0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h,0C7h
island_col_storm:
        db  0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h
        db  0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h
        db  0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h
        db  0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h,0C5h
dest_tab:
        dw  dest0_pat, dest0_row
        dw  dest1_pat, dest1_row
        dw  dest2_pat, dest2_row
        dw  dest3_pat, dest3_row
        dw  dest4_pat, dest4_row
        dw  dest5_pat, dest5_row
; "TO CYCLOPS"
dest0_pat:
        db  0FEh,0FEh,010h,010h,010h,010h,010h,038h,03Ch,066h,0C3h,0C3h,0C3h,0C3h,066h,03Ch
        db  03Eh,062h,0C0h,0C0h,0C0h,0C0h,062h,03Eh,0C6h,0C6h,06Ch,038h,010h,010h,010h,000h
        db  0C0h,0C0h,0C0h,0C0h,0C0h,0C0h,0FEh,000h,0FCh,0C6h,0C6h,0FCh,0C0h,0C0h,0C0h,000h
        db  07Eh,0C0h,0C0h,07Ch,006h,006h,0FCh,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h
dest0_row:
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,002h,000h,003h,004h
        db  003h,005h,002h,006h,007h,000h,000h,000h,000h,000h,00Ah,00Bh,000h,000h,000h,000h
; "TO CIRCE"
dest1_pat:
        db  0FEh,0FEh,010h,010h,010h,010h,010h,038h,03Ch,066h,0C3h,0C3h,0C3h,0C3h,066h,03Ch
        db  03Eh,062h,0C0h,0C0h,0C0h,0C0h,062h,03Eh,07Ch,010h,010h,010h,010h,010h,010h,07Ch
        db  0FCh,0C6h,0C6h,0FCh,0D8h,0CCh,0C6h,000h,0FEh,060h,030h,010h,030h,060h,0FEh,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h
dest1_row:
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,002h,000h,003h
        db  004h,005h,003h,006h,000h,000h,000h,000h,000h,000h,00Ah,00Bh,000h,000h,000h,000h
; "TO AEOLIA"
dest2_pat:
        db  0FEh,0FEh,010h,010h,010h,010h,010h,038h,03Ch,066h,0C3h,0C3h,0C3h,0C3h,066h,03Ch
        db  018h,018h,03Ch,024h,066h,042h,0C3h,0C3h,0FEh,060h,030h,010h,030h,060h,0FEh,000h
        db  0C0h,0C0h,0C0h,0C0h,0C0h,0C0h,0FEh,000h,07Ch,010h,010h,010h,010h,010h,010h,07Ch
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h
dest2_row:
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,002h,000h,003h,004h
        db  002h,005h,006h,003h,000h,000h,000h,000h,000h,000h,00Ah,00Bh,000h,000h,000h,000h
; "TO SIRENS"
dest3_pat:
        db  0FEh,0FEh,010h,010h,010h,010h,010h,038h,03Ch,066h,0C3h,0C3h,0C3h,0C3h,066h,03Ch
        db  07Eh,0C0h,0C0h,07Ch,006h,006h,0FCh,000h,07Ch,010h,010h,010h,010h,010h,010h,07Ch
        db  0FCh,0C6h,0C6h,0FCh,0D8h,0CCh,0C6h,000h,0FEh,060h,030h,010h,030h,060h,0FEh,000h
        db  0C6h,0E6h,0F6h,0DEh,0CEh,0C6h,0C6h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h
dest3_row:
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,002h,000h,003h,004h
        db  005h,006h,007h,003h,000h,000h,000h,000h,000h,000h,00Ah,00Bh,000h,000h,000h,000h
; "TO ITHACA"
dest4_pat:
        db  0FEh,0FEh,010h,010h,010h,010h,010h,038h,03Ch,066h,0C3h,0C3h,0C3h,0C3h,066h,03Ch
        db  07Ch,010h,010h,010h,010h,010h,010h,07Ch,0C6h,0C6h,0C6h,0FEh,0C6h,0C6h,0C6h,0C6h
        db  018h,018h,03Ch,024h,066h,042h,0C3h,0C3h,03Eh,062h,0C0h,0C0h,0C0h,0C0h,062h,03Eh
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
        db  000h,000h,000h,000h,000h,000h,000h,000h
dest4_row:
        db  000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,002h,000h,003h,001h
        db  004h,005h,006h,005h,000h,000h,000h,000h,000h,000h,00Ah,00Bh,000h,000h,000h,000h
; "SCYLLA AND CHARYBDIS"
dest5_pat:
        db  07Eh,0C0h,0C0h,07Ch,006h,006h,0FCh,000h,03Eh,062h,0C0h,0C0h,0C0h,0C0h,062h,03Eh
        db  0C6h,0C6h,06Ch,038h,010h,010h,010h,000h,0C0h,0C0h,0C0h,0C0h,0C0h,0C0h,0FEh,000h
        db  018h,018h,03Ch,024h,066h,042h,0C3h,0C3h,0C6h,0E6h,0F6h,0DEh,0CEh,0C6h,0C6h,000h
        db  0FCh,0C6h,0C6h,0C6h,0C6h,0C6h,0FCh,000h,0C6h,0C6h,0C6h,0FEh,0C6h,0C6h,0C6h,0C6h
        db  0FCh,0C6h,0C6h,0FCh,0D8h,0CCh,0C6h,000h,0FCh,0C6h,0C6h,0FCh,0C6h,0C6h,0FCh,000h
        db  07Ch,010h,010h,010h,010h,010h,010h,07Ch
dest5_row:
        db  000h,000h,000h,000h,000h,000h,001h,002h,003h,004h,004h,005h,000h,005h,006h,007h
        db  000h,002h,00Dh,005h,010h,003h,011h,007h,012h,001h,00Ah,00Bh,000h,000h,000h,000h
