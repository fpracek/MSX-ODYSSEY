; GENERATO da tools/gen_waves.py - NON MODIFICARE A MANO
; colori statici + 8 preshift per banda: a runtime si
; riscrivono SOLO i pattern (vedi commento nel generatore)

WAVES_A_W equ 16
wavesA_rowcol:
        db  0F4h,074h,054h,074h,0F4h,054h,074h,074h
wavesA_pst:
        dw  wavesA_ps+0
        dw  wavesA_ps+128
        dw  wavesA_ps+256
        dw  wavesA_ps+384
        dw  wavesA_ps+512
        dw  wavesA_ps+640
        dw  wavesA_ps+768
        dw  wavesA_ps+896
wavesA_ps:
; preshift 0
        db  000h,040h,0F0h,01Fh,000h,00Fh,0FAh,044h,000h,000h,000h,0FCh,07Fh,080h,022h,044h
        db  000h,004h,040h,01Fh,0FEh,003h,022h,044h,020h,000h,007h,0FCh,000h,0E0h,03Fh,044h
        db  001h,09Fh,0F8h,000h,000h,00Fh,0FAh,0C4h,00Fh,0FCh,000h,000h,07Fh,080h,022h,044h
        db  0F8h,01Fh,080h,000h,0FEh,003h,022h,044h,000h,0FCh,007h,000h,000h,0F0h,03Fh,046h
        db  009h,000h,0F0h,01Fh,000h,00Fh,0FAh,044h,040h,000h,040h,0FCh,07Fh,080h,022h,044h
        db  000h,000h,000h,01Fh,0FEh,083h,022h,044h,000h,000h,007h,0FCh,002h,0E0h,03Fh,044h
        db  040h,09Fh,0F0h,004h,000h,00Fh,0FEh,044h,00Fh,0FDh,000h,000h,07Fh,080h,022h,044h
        db  0F8h,01Fh,000h,000h,0FEh,003h,022h,044h,001h,0FCh,007h,000h,000h,0E0h,03Fh,044h
; preshift 1
        db  000h,080h,0E0h,03Fh,000h,01Fh,0F4h,088h,000h,000h,000h,0F8h,0FFh,000h,044h,088h
        db  000h,008h,080h,03Fh,0FCh,007h,044h,088h,040h,001h,00Fh,0F8h,000h,0C0h,07Fh,089h
        db  002h,03Fh,0F0h,000h,000h,01Fh,0F4h,088h,01Fh,0F8h,001h,000h,0FFh,000h,044h,088h
        db  0F0h,03Fh,000h,000h,0FCh,007h,044h,088h,000h,0F8h,00Fh,000h,000h,0E0h,07Fh,08Ch
        db  012h,000h,0E0h,03Fh,000h,01Fh,0F4h,088h,080h,000h,080h,0F8h,0FFh,001h,044h,088h
        db  000h,000h,000h,03Fh,0FCh,007h,044h,088h,000h,001h,00Fh,0F8h,004h,0C0h,07Fh,088h
        db  080h,03Fh,0E0h,008h,000h,01Fh,0FCh,088h,01Fh,0FAh,000h,000h,0FFh,000h,044h,088h
        db  0F0h,03Fh,000h,000h,0FCh,007h,044h,088h,002h,0F8h,00Fh,000h,000h,0C0h,07Fh,088h
; preshift 2
        db  000h,000h,0C0h,07Fh,001h,03Eh,0E8h,011h,000h,000h,001h,0F0h,0FFh,000h,088h,011h
        db  000h,010h,000h,07Fh,0F8h,00Fh,088h,011h,080h,002h,01Fh,0F0h,000h,080h,0FFh,013h
        db  004h,07Fh,0E0h,000h,001h,03Eh,0E8h,011h,03Fh,0F0h,002h,000h,0FFh,000h,088h,011h
        db  0E0h,07Fh,000h,000h,0F8h,00Fh,088h,011h,000h,0F0h,01Fh,000h,000h,0C0h,0FFh,019h
        db  025h,000h,0C1h,07Fh,001h,03Eh,0E8h,011h,000h,000h,000h,0F0h,0FFh,002h,088h,011h
        db  000h,000h,000h,07Fh,0F8h,00Fh,088h,011h,001h,002h,01Fh,0F0h,008h,080h,0FFh,011h
        db  000h,07Fh,0C0h,010h,001h,03Eh,0F8h,011h,03Fh,0F4h,000h,000h,0FFh,000h,088h,011h
        db  0E0h,07Fh,000h,000h,0F8h,00Fh,088h,011h,004h,0F1h,01Fh,000h,000h,080h,0FFh,011h
; preshift 3
        db  000h,000h,080h,0FFh,003h,07Ch,0D1h,022h,000h,000h,002h,0E0h,0FFh,000h,011h,022h
        db  001h,020h,000h,0FFh,0F0h,01Fh,011h,022h,000h,004h,03Fh,0E0h,000h,000h,0FFh,026h
        db  008h,0FFh,0C0h,000h,003h,07Ch,0D1h,022h,07Fh,0E0h,004h,000h,0FFh,000h,011h,022h
        db  0C0h,0FFh,000h,000h,0F0h,01Fh,011h,022h,000h,0E0h,03Fh,000h,000h,080h,0FFh,032h
        db  04Ah,000h,082h,0FFh,003h,07Ch,0D1h,022h,000h,000h,000h,0E0h,0FFh,004h,011h,022h
        db  000h,000h,000h,0FFh,0F0h,01Fh,011h,022h,002h,004h,03Fh,0E0h,010h,000h,0FFh,022h
        db  000h,0FFh,080h,020h,003h,07Ch,0F1h,022h,07Fh,0E8h,000h,000h,0FFh,000h,011h,022h
        db  0C0h,0FFh,000h,000h,0F0h,01Fh,011h,022h,008h,0E2h,03Fh,000h,000h,000h,0FFh,022h
; preshift 4
        db  000h,000h,000h,0FFh,007h,0F8h,0A2h,044h,000h,000h,004h,0C1h,0FFh,000h,022h,044h
        db  002h,040h,000h,0FFh,0E0h,03Eh,023h,044h,000h,009h,07Fh,0C0h,000h,000h,0FFh,04Ch
        db  010h,0FFh,080h,000h,007h,0F8h,0A2h,044h,0FFh,0C1h,008h,000h,0FFh,000h,022h,044h
        db  080h,0FFh,000h,000h,0E0h,03Fh,023h,044h,000h,0C0h,07Fh,001h,000h,000h,0FFh,064h
        db  094h,000h,004h,0FFh,007h,0F8h,0A2h,044h,000h,000h,000h,0C1h,0FFh,008h,022h,044h
        db  000h,000h,000h,0FFh,0E0h,03Eh,023h,044h,004h,009h,07Fh,0C0h,020h,000h,0FFh,044h
        db  000h,0FFh,000h,040h,007h,0F8h,0E2h,044h,0FFh,0D1h,000h,000h,0FFh,000h,022h,044h
        db  080h,0FFh,000h,000h,0E0h,03Eh,023h,044h,010h,0C4h,07Fh,001h,000h,000h,0FFh,044h
; preshift 5
        db  000h,000h,000h,0FFh,00Fh,0F0h,044h,088h,000h,000h,008h,083h,0FFh,000h,044h,088h
        db  004h,080h,000h,0FFh,0C0h,07Ch,047h,088h,000h,013h,0FFh,080h,000h,001h,0FFh,098h
        db  021h,0FFh,000h,000h,00Fh,0F0h,044h,088h,0FFh,083h,010h,000h,0FFh,000h,044h,088h
        db  000h,0FFh,000h,000h,0C0h,07Eh,047h,088h,001h,080h,0FEh,003h,000h,001h,0FFh,0C8h
        db  028h,000h,008h,0FFh,00Fh,0F0h,044h,088h,000h,000h,000h,083h,0FFh,010h,044h,088h
        db  000h,000h,000h,0FFh,0C0h,07Ch,047h,088h,008h,013h,0FEh,080h,040h,001h,0FFh,088h
        db  001h,0FFh,000h,080h,00Fh,0F0h,0C4h,088h,0FFh,0A3h,000h,000h,0FFh,000h,044h,088h
        db  000h,0FFh,000h,000h,0C0h,07Ch,047h,088h,020h,088h,0FEh,003h,000h,001h,0FFh,088h
; preshift 6
        db  000h,000h,000h,0FFh,01Fh,0E0h,088h,011h,000h,001h,010h,007h,0FFh,000h,088h,011h
        db  008h,000h,001h,0FFh,080h,0F8h,08Fh,011h,000h,027h,0FEh,000h,000h,003h,0FEh,031h
        db  043h,0FFh,000h,000h,01Fh,0E0h,088h,011h,0FEh,007h,020h,000h,0FFh,000h,088h,011h
        db  000h,0FFh,001h,000h,080h,0FCh,08Fh,011h,002h,000h,0FCh,007h,000h,003h,0FEh,091h
        db  050h,000h,010h,0FFh,01Fh,0E0h,088h,011h,000h,000h,000h,007h,0FFh,020h,088h,011h
        db  000h,000h,001h,0FFh,080h,0F8h,08Fh,011h,010h,027h,0FCh,001h,080h,003h,0FFh,011h
        db  003h,0FFh,000h,000h,01Fh,0E0h,088h,011h,0FEh,047h,000h,000h,0FFh,000h,088h,011h
        db  000h,0FFh,001h,000h,080h,0F8h,08Fh,011h,040h,010h,0FCh,007h,000h,003h,0FEh,011h
; preshift 7
        db  000h,000h,000h,0FEh,03Fh,0C0h,011h,022h,000h,002h,020h,00Fh,0FFh,001h,011h,022h
        db  010h,000h,003h,0FEh,000h,0F0h,01Fh,022h,000h,04Fh,0FCh,000h,000h,007h,0FDh,062h
        db  087h,0FEh,000h,000h,03Fh,0C0h,011h,022h,0FCh,00Fh,040h,000h,0FFh,001h,011h,022h
        db  000h,0FEh,003h,000h,000h,0F8h,01Fh,023h,004h,000h,0F8h,00Fh,000h,007h,0FDh,022h
        db  0A0h,000h,020h,0FEh,03Fh,0C0h,011h,022h,000h,000h,000h,00Fh,0FFh,041h,011h,022h
        db  000h,000h,003h,0FEh,001h,0F0h,01Fh,022h,020h,04Fh,0F8h,002h,000h,007h,0FFh,022h
        db  007h,0FEh,000h,000h,03Fh,0C0h,011h,022h,0FCh,08Fh,000h,000h,0FFh,001h,011h,022h
        db  000h,0FEh,003h,000h,000h,0F0h,01Fh,022h,080h,020h,0F8h,00Fh,000h,007h,0FDh,022h

WAVES_A2_W equ 16
wavesA2_rowcol:
        db  0F4h,0F4h,074h,074h,0F4h,054h,074h,0F4h
wavesA2_pst:
        dw  wavesA2_ps+0
        dw  wavesA2_ps+128
        dw  wavesA2_ps+256
        dw  wavesA2_ps+384
        dw  wavesA2_ps+512
        dw  wavesA2_ps+640
        dw  wavesA2_ps+768
        dw  wavesA2_ps+896
wavesA2_ps:
; preshift 0
        db  001h,000h,0F8h,0FFh,00Fh,07Eh,0F6h,049h,000h,000h,010h,0FFh,0FFh,000h,049h,024h
        db  001h,000h,000h,01Fh,0FFh,01Fh,025h,092h,000h,000h,00Fh,0FFh,0F0h,080h,0FFh,0D9h
        db  000h,03Fh,0FFh,084h,007h,07Eh,0E9h,024h,0FFh,0FFh,000h,07Fh,0FFh,000h,024h,092h
        db  0FFh,0FFh,000h,000h,0F8h,01Fh,093h,049h,080h,0FEh,07Fh,000h,000h,090h,0FFh,034h
        db  000h,040h,0F8h,0FFh,007h,07Eh,0E4h,09Ah,000h,000h,000h,0FFh,0FFh,000h,092h,049h
        db  000h,000h,004h,01Fh,0FFh,01Fh,049h,024h,000h,000h,00Fh,0FFh,0E0h,080h,0FFh,0F2h
        db  008h,03Fh,0FFh,0A2h,007h,07Eh,0F2h,069h,0FFh,0FFh,00Ch,03Fh,0FFh,000h,049h,024h
        db  0FFh,0FFh,000h,000h,0F8h,01Fh,025h,092h,084h,0FEh,07Fh,000h,001h,080h,0FFh,049h
; preshift 1
        db  002h,000h,0F0h,0FFh,01Fh,0FCh,0ECh,092h,000h,000h,020h,0FEh,0FFh,000h,092h,049h
        db  002h,000h,000h,03Fh,0FFh,03Fh,04Bh,025h,000h,000h,01Fh,0FFh,0E0h,000h,0FFh,0B2h
        db  001h,07Fh,0FEh,008h,00Fh,0FCh,0D2h,049h,0FFh,0FFh,000h,0FEh,0FFh,000h,049h,024h
        db  0FFh,0FFh,000h,000h,0F0h,03Fh,027h,092h,000h,0FCh,0FFh,001h,000h,020h,0FFh,069h
        db  000h,080h,0F0h,0FFh,00Fh,0FCh,0C9h,034h,000h,000h,000h,0FEh,0FFh,000h,024h,092h
        db  000h,000h,008h,03Fh,0FFh,03Fh,093h,049h,000h,000h,01Fh,0FFh,0C0h,000h,0FFh,0E4h
        db  011h,07Fh,0FEh,044h,00Fh,0FCh,0E4h,0D2h,0FFh,0FFh,018h,07Eh,0FFh,000h,092h,049h
        db  0FFh,0FFh,000h,000h,0F0h,03Fh,04Bh,024h,008h,0FCh,0FFh,001h,002h,000h,0FFh,092h
; preshift 2
        db  004h,000h,0E0h,0FFh,03Fh,0F8h,0D9h,024h,000h,000h,040h,0FCh,0FFh,000h,024h,092h
        db  004h,000h,000h,07Fh,0FFh,07Eh,097h,04Bh,000h,000h,03Fh,0FEh,0C0h,001h,0FFh,064h
        db  003h,0FFh,0FCh,011h,01Fh,0F8h,0A4h,092h,0FFh,0FFh,000h,0FCh,0FFh,000h,092h,049h
        db  0FEh,0FFh,001h,000h,0E0h,07Eh,04Fh,024h,000h,0F9h,0FFh,003h,000h,041h,0FFh,0D2h
        db  000h,000h,0E0h,0FFh,01Fh,0F8h,092h,069h,000h,000h,000h,0FCh,0FFh,000h,049h,024h
        db  000h,000h,010h,07Fh,0FFh,07Eh,027h,093h,000h,000h,03Fh,0FEh,080h,001h,0FFh,0C9h
        db  023h,0FFh,0FCh,088h,01Fh,0F8h,0C9h,0A4h,0FFh,0FFh,030h,0FCh,0FFh,000h,024h,092h
        db  0FEh,0FFh,001h,000h,0E0h,07Eh,097h,049h,010h,0F8h,0FFh,003h,004h,001h,0FFh,025h
; preshift 3
        db  008h,000h,0C0h,0FFh,07Fh,0F0h,0B2h,049h,000h,000h,080h,0F8h,0FFh,000h,049h,024h
        db  008h,000h,000h,0FFh,0FFh,0FCh,02Fh,096h,000h,001h,07Fh,0FCh,080h,003h,0FFh,0C9h
        db  007h,0FFh,0F8h,023h,03Fh,0F0h,049h,024h,0FFh,0FFh,000h,0F8h,0FFh,000h,024h,092h
        db  0FCh,0FFh,003h,000h,0C0h,0FCh,09Fh,049h,000h,0F2h,0FFh,007h,000h,083h,0FFh,0A4h
        db  000h,000h,0C0h,0FFh,03Fh,0F0h,024h,0D2h,000h,000h,000h,0F8h,0FFh,000h,092h,049h
        db  000h,000h,020h,0FFh,0FFh,0FCh,04Fh,027h,000h,001h,07Fh,0FDh,000h,003h,0FFh,093h
        db  047h,0FFh,0F8h,011h,03Fh,0F0h,092h,049h,0FFh,0FFh,060h,0F8h,0FFh,000h,049h,024h
        db  0FCh,0FFh,003h,000h,0C0h,0FCh,02Fh,092h,020h,0F0h,0FFh,007h,008h,003h,0FFh,04Ah
; preshift 4
        db  010h,000h,081h,0FFh,0FFh,0E0h,064h,092h,000h,000h,000h,0F1h,0FFh,001h,092h,049h
        db  010h,000h,000h,0FFh,0FFh,0F8h,05Fh,02Dh,000h,003h,0FFh,0F8h,000h,007h,0FEh,092h
        db  00Fh,0FFh,0F0h,047h,07Fh,0E0h,092h,049h,0FFh,0FFh,000h,0F0h,0FFh,001h,049h,024h
        db  0F8h,0FFh,007h,000h,080h,0F9h,03Fh,093h,000h,0E4h,0FFh,00Fh,000h,007h,0FEh,049h
        db  000h,000h,080h,0FFh,07Fh,0E0h,049h,0A4h,000h,000h,000h,0F1h,0FFh,001h,024h,092h
        db  000h,000h,040h,0FFh,0FEh,0F8h,09Fh,04Fh,000h,003h,0FFh,0FAh,000h,007h,0FFh,026h
        db  08Fh,0FFh,0F0h,023h,07Fh,0E0h,024h,092h,0FFh,0FFh,0C0h,0F0h,0FFh,001h,092h,049h
        db  0F8h,0FFh,007h,000h,080h,0F8h,05Fh,024h,040h,0E0h,0FFh,00Fh,010h,007h,0FFh,094h
; preshift 5
        db  020h,000h,002h,0FFh,0FFh,0C0h,0C9h,024h,000h,000h,000h,0E3h,0FFh,003h,024h,092h
        db  020h,000h,001h,0FFh,0FEh,0F0h,0BFh,05Bh,000h,007h,0FFh,0F0h,000h,00Fh,0FDh,024h
        db  01Fh,0FFh,0E0h,08Fh,0FFh,0C0h,024h,092h,0FFh,0FFh,000h,0E0h,0FFh,003h,092h,049h
        db  0F0h,0FFh,00Fh,000h,000h,0F2h,07Fh,026h,000h,0C8h,0FFh,01Fh,000h,00Fh,0FCh,093h
        db  000h,000h,000h,0FFh,0FFh,0C0h,092h,049h,000h,000h,000h,0E3h,0FFh,003h,049h,024h
        db  000h,000h,081h,0FFh,0FCh,0F0h,03Fh,09Eh,001h,007h,0FFh,0F4h,000h,00Fh,0FEh,04Dh
        db  01Fh,0FFh,0E1h,047h,0FFh,0C0h,049h,024h,0FFh,0FFh,080h,0E0h,0FFh,003h,024h,092h
        db  0F0h,0FFh,00Fh,000h,000h,0F0h,0BFh,049h,080h,0C0h,0FFh,01Fh,021h,00Fh,0FEh,029h
; preshift 6
        db  040h,000h,004h,0FFh,0FFh,080h,092h,049h,000h,000h,000h,0C7h,0FFh,007h,049h,024h
        db  040h,000h,003h,0FFh,0FCh,0E0h,07Fh,0B6h,000h,00Fh,0FFh,0E1h,001h,01Fh,0FAh,049h
        db  03Fh,0FFh,0C0h,01Fh,0FFh,080h,049h,024h,0FFh,0FFh,000h,0C0h,0FEh,007h,024h,092h
        db  0E0h,0FFh,01Fh,000h,000h,0E4h,0FFh,04Dh,000h,090h,0FEh,03Fh,001h,01Fh,0F9h,026h
        db  000h,000h,000h,0FFh,0FFh,080h,024h,092h,000h,000h,001h,0C7h,0FFh,007h,092h,049h
        db  000h,000h,003h,0FFh,0F8h,0E0h,07Fh,03Ch,002h,00Fh,0FFh,0E8h,001h,01Fh,0FCh,09Ah
        db  03Fh,0FFh,0C3h,08Fh,0FFh,080h,092h,049h,0FFh,0FFh,000h,0C0h,0FEh,007h,049h,024h
        db  0E1h,0FFh,01Fh,000h,000h,0E0h,07Fh,092h,000h,080h,0FEh,03Fh,043h,01Fh,0FDh,052h
; preshift 7
        db  080h,000h,008h,0FFh,0FFh,000h,024h,092h,000h,000h,000h,08Fh,0FFh,00Fh,092h,049h
        db  080h,000h,007h,0FFh,0F8h,0C0h,0FFh,06Ch,000h,01Fh,0FFh,0C2h,003h,03Fh,0F4h,092h
        db  07Fh,0FFh,080h,03Fh,0FFh,000h,092h,049h,0FFh,0FFh,000h,080h,0FCh,00Fh,049h,024h
        db  0C0h,0FFh,03Fh,000h,000h,0C8h,0FFh,09Ah,000h,020h,0FCh,07Fh,003h,03Fh,0F2h,04Dh
        db  000h,000h,000h,0FFh,0FFh,000h,049h,024h,000h,000h,002h,08Fh,0FFh,00Fh,024h,092h
        db  000h,000h,007h,0FFh,0F0h,0C0h,0FFh,079h,004h,01Fh,0FFh,0D1h,003h,03Fh,0F9h,034h
        db  07Fh,0FFh,086h,01Fh,0FFh,000h,024h,092h,0FFh,0FFh,000h,080h,0FCh,00Fh,092h,049h
        db  0C2h,0FFh,03Fh,000h,000h,0C0h,0FFh,024h,000h,000h,0FCh,07Fh,087h,03Fh,0FBh,0A4h

WAVES_B_W equ 8
wavesB_rowcol:
        db  0F4h,0F4h,074h,054h,074h,054h,074h,054h
wavesB_pst:
        dw  wavesB_ps+0
        dw  wavesB_ps+64
        dw  wavesB_ps+128
        dw  wavesB_ps+192
        dw  wavesB_ps+256
        dw  wavesB_ps+320
        dw  wavesB_ps+384
        dw  wavesB_ps+448
wavesB_ps:
; preshift 0
        db  000h,000h,000h,000h,0C1h,03Eh,000h,022h,000h,000h,000h,000h,0E0h,03Ch,003h,022h
        db  000h,000h,000h,000h,000h,007h,0F8h,022h,000h,000h,001h,000h,0FFh,022h,001h,022h
        db  008h,000h,003h,00Eh,0F0h,022h,000h,022h,010h,07Eh,083h,022h,000h,022h,000h,022h
        db  000h,000h,0FFh,022h,000h,022h,000h,022h,000h,000h,0F8h,026h,001h,022h,000h,022h
; preshift 1
        db  000h,000h,000h,000h,083h,07Ch,000h,044h,000h,000h,000h,000h,0C0h,078h,007h,044h
        db  000h,000h,000h,000h,001h,00Eh,0F0h,044h,000h,000h,002h,000h,0FFh,044h,002h,044h
        db  010h,000h,007h,01Ch,0E0h,044h,000h,044h,020h,0FCh,007h,044h,000h,044h,000h,044h
        db  000h,000h,0FFh,044h,000h,044h,000h,044h,000h,000h,0F0h,04Ch,003h,044h,000h,044h
; preshift 2
        db  000h,000h,000h,000h,007h,0F8h,000h,088h,000h,000h,000h,000h,080h,0F0h,00Fh,088h
        db  000h,000h,000h,000h,003h,01Ch,0E0h,088h,000h,000h,004h,000h,0FFh,088h,004h,088h
        db  020h,001h,00Eh,038h,0C0h,088h,000h,088h,040h,0F8h,00Fh,088h,000h,088h,000h,088h
        db  000h,000h,0FFh,088h,000h,088h,000h,088h,000h,000h,0E0h,098h,007h,088h,000h,088h
; preshift 3
        db  000h,000h,000h,000h,00Fh,0F1h,000h,011h,000h,000h,000h,000h,000h,0E0h,01Fh,011h
        db  000h,000h,000h,000h,007h,039h,0C0h,011h,000h,000h,008h,000h,0FFh,011h,008h,011h
        db  040h,003h,01Ch,071h,080h,011h,000h,011h,080h,0F0h,01Fh,011h,000h,011h,000h,011h
        db  000h,000h,0FFh,011h,000h,011h,000h,011h,000h,000h,0C0h,030h,00Eh,011h,000h,011h
; preshift 4
        db  000h,000h,000h,000h,01Eh,0E3h,000h,022h,000h,000h,000h,000h,000h,0C0h,03Fh,022h
        db  000h,000h,000h,000h,00Fh,072h,080h,022h,000h,000h,010h,000h,0FFh,022h,010h,022h
        db  081h,007h,038h,0E2h,000h,022h,000h,022h,000h,0E0h,03Fh,022h,000h,022h,000h,022h
        db  000h,000h,0FFh,022h,000h,022h,000h,022h,000h,000h,080h,060h,01Ch,023h,000h,022h
; preshift 5
        db  000h,000h,000h,000h,03Ch,0C7h,000h,044h,000h,000h,000h,000h,000h,080h,07Fh,044h
        db  000h,000h,000h,000h,01Fh,0E4h,000h,044h,001h,000h,020h,001h,0FEh,044h,020h,044h
        db  002h,00Fh,070h,0C4h,000h,044h,000h,044h,000h,0C0h,07Fh,044h,000h,044h,000h,044h
        db  000h,000h,0FFh,044h,000h,044h,000h,044h,000h,000h,000h,0C0h,038h,047h,000h,044h
; preshift 6
        db  000h,000h,000h,000h,078h,08Fh,000h,088h,000h,000h,000h,000h,000h,001h,0FEh,088h
        db  000h,000h,000h,000h,03Fh,0C8h,000h,088h,002h,000h,040h,003h,0FCh,088h,040h,088h
        db  004h,01Fh,0E0h,088h,000h,088h,000h,088h,000h,080h,0FFh,088h,000h,088h,000h,088h
        db  000h,000h,0FEh,089h,000h,088h,000h,088h,000h,000h,000h,080h,070h,08Fh,000h,088h
; preshift 7
        db  000h,000h,000h,000h,0F0h,01Eh,001h,011h,000h,000h,000h,000h,000h,003h,0FCh,011h
        db  000h,000h,000h,000h,07Fh,091h,000h,011h,004h,000h,081h,007h,0F8h,011h,080h,011h
        db  008h,03Fh,0C1h,011h,000h,011h,000h,011h,000h,000h,0FFh,011h,000h,011h,000h,011h
        db  000h,000h,0FCh,013h,000h,011h,000h,011h,000h,000h,000h,000h,0E0h,01Fh,000h,011h

WAVES_C_W equ 4
wavesC_rowcol:
        db  0F7h,0F7h,0F7h,057h,0F7h,057h,057h,057h
wavesC_pst:
        dw  wavesC_ps+0
        dw  wavesC_ps+32
        dw  wavesC_ps+64
        dw  wavesC_ps+96
        dw  wavesC_ps+128
        dw  wavesC_ps+160
        dw  wavesC_ps+192
        dw  wavesC_ps+224
wavesC_ps:
; preshift 0
        db  000h,000h,03Eh,03Eh,000h,000h,000h,000h,000h,000h,000h,000h,03Eh,03Eh,000h,000h
        db  000h,000h,03Eh,03Eh,000h,000h,000h,000h,000h,000h,000h,000h,03Eh,03Eh,000h,000h
; preshift 1
        db  000h,000h,07Ch,07Ch,000h,000h,000h,000h,000h,000h,000h,000h,07Ch,07Ch,000h,000h
        db  000h,000h,07Ch,07Ch,000h,000h,000h,000h,000h,000h,000h,000h,07Ch,07Ch,000h,000h
; preshift 2
        db  000h,000h,0F8h,0F8h,000h,000h,000h,000h,000h,000h,000h,000h,0F8h,0F8h,000h,000h
        db  000h,000h,0F8h,0F8h,000h,000h,000h,000h,000h,000h,000h,000h,0F8h,0F8h,000h,000h
; preshift 3
        db  000h,000h,0F0h,0F0h,001h,001h,000h,000h,000h,000h,001h,001h,0F0h,0F0h,000h,000h
        db  000h,000h,0F0h,0F0h,001h,001h,000h,000h,000h,000h,001h,001h,0F0h,0F0h,000h,000h
; preshift 4
        db  000h,000h,0E0h,0E0h,003h,003h,000h,000h,000h,000h,003h,003h,0E0h,0E0h,000h,000h
        db  000h,000h,0E0h,0E0h,003h,003h,000h,000h,000h,000h,003h,003h,0E0h,0E0h,000h,000h
; preshift 5
        db  000h,000h,0C0h,0C0h,007h,007h,000h,000h,000h,000h,007h,007h,0C0h,0C0h,000h,000h
        db  000h,000h,0C0h,0C0h,007h,007h,000h,000h,000h,000h,007h,007h,0C0h,0C0h,000h,000h
; preshift 6
        db  000h,000h,080h,080h,00Fh,00Fh,000h,000h,000h,000h,00Fh,00Fh,080h,080h,000h,000h
        db  000h,000h,080h,080h,00Fh,00Fh,000h,000h,000h,000h,00Fh,00Fh,080h,080h,000h,000h
; preshift 7
        db  000h,000h,000h,000h,01Fh,01Fh,000h,000h,000h,000h,01Fh,01Fh,000h,000h,000h,000h
        db  000h,000h,000h,000h,01Fh,01Fh,000h,000h,000h,000h,01Fh,01Fh,000h,000h,000h,000h

; colori banda C espansi (recolor meteo, 4 tile)
wavesC_colx:
        db  0F7h,0F7h,0F7h,057h,0F7h,057h,057h,057h,0F7h,0F7h,0F7h,057h,0F7h,057h,057h,057h
        db  0F7h,0F7h,0F7h,057h,0F7h,057h,057h,057h,0F7h,0F7h,0F7h,057h,0F7h,057h,057h,057h
wavesC_colx_storm:
        db  0F5h,0F5h,0F5h,045h,0F5h,045h,045h,045h,0F5h,0F5h,0F5h,045h,0F5h,045h,045h,045h
        db  0F5h,0F5h,0F5h,045h,0F5h,045h,045h,045h,0F5h,0F5h,0F5h,045h,0F5h,045h,045h,045h

; totale dati pattern: 2816 byte
