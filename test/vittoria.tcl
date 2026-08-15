# Regressione della TRANSIZIONE vittoria episodio -> pergamena ->
# mare: l'hook di frame dell'episodio vive in un banco commutabile
# e l'init DEVE neutralizzarlo (RET a HTIMI) prima di rimappare la
# pagina 8000h per le pergamene - altrimenti la bitmap viene
# eseguita come codice e il gioco si pianta a schermo nero (il bug
# del 14/08). Percorre l'antro di Polifemo fino alla vittoria e
# verifica pergamena viva + salpata. Esito in build/vittoria_result.txt.

proc report {msg} {
    set fh [open "build/vittoria_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/vittoria_result.txt"}

proc tap {row mask t} {
    after time $t "keymatrixdown $row $mask"
    after time [expr {$t + 0.4}] "keymatrixup $row $mask"
}
# GOTO1 e attraversamento rapido delle 3 stanze (come third.tcl)
tap 3 16 4.0
tap 4 16 4.8
tap 5 2  5.6
tap 4 16 6.4
tap 0 2  7.2
after time 10 {
    debug write memory 0xC052 196
    debug write memory 0xC054 40
}
after time 11 {
    debug write memory 0xC052 228
    debug write memory 0xC054 40
}
after time 12 {
    debug write memory 0xC06E 0
    debug write memory 0xC072 0
}
after time 12.5 {
    debug write memory 0xC058 0
    debug write memory 0xC059 0
    debug write memory 0xC052 136
    debug write memory 0xC054 88
}
after time 14 {
    debug write memory 0xC058 0
    debug write memory 0xC059 0
    debug write memory 0xC055 0
    debug write memory 0xC056 0
    debug write memory 0xC052 48
    debug write memory 0xC054 40
}
# il colpo va SFERRATO: freccia in basso
tap 8 64 14.3
after time 15.5 {
    debug write memory 0xC05E 200
    debug write memory 0xC052 228
    debug write memory 0xC054 128
}
# vittoria ~t16, lampeggio 2.4s, init, pergamena
after time 21 {
    if {[catch {
        set ph [debug read memory 0xC04F]
        set lg [debug read memory 0xC040]
        set pc [reg PC]
        if {$ph == 0 && $lg == 1 && $pc >= 0x4000 && $pc < 0x6000} {
            report [format "pergamena: OK (leg 1, PC nel kernel a %04X)" $pc]
        } else {
            report [format "pergamena: phase=%d leg=%d PC=%04X (attesi 0,1,4xxx)" $ph $lg $pc]
        }
        screenshot -raw ./build/shot_vittoria.png
    } err]} { report "ERRORE t21: $err" }
}
# FIRE: si salpa; il mare installa il suo hook (frame_cnt vivo)
tap 8 1 23
after time 26 {
    if {[catch { set ::f1 [debug read memory 0xC001] } err]} {
        report "ERRORE t26: $err"
    }
}
after time 27 {
    if {[catch {
        set f2 [debug read memory 0xC001]
        set md [debug read memory 0xC020]
        if {$f2 != $::f1 && $md == 0} {
            report "salpata: OK (verso Circe, hook di frame vivo)"
        } else {
            report [format "salpata: frame %d->%d mode=%d (atteso vivo,0)" $::f1 $f2 $md]
        }
    } err]} { report "ERRORE t27: $err" }
    exit
}
