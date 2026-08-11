# Test del cheat GOTO1: digitato sul titolo deve portare DRITTI
# alla caverna di Polifemo (leg 0, phase 1, episodio attivo), senza
# traversata. Matrice: G=riga3 bit4, O=riga4 bit4, T=riga5 bit1,
# cifre=riga0. Esito in build/goto_result.txt.

proc report {msg} {
    set fh [open "build/goto_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/goto_result.txt"}

proc tap {row mask t} {
    after time $t "keymatrixdown $row $mask"
    after time [expr {$t + 0.4}] "keymatrixup $row $mask"
}
# G O T O 1 sul titolo
tap 3 16 4.0
tap 4 16 4.8
tap 5 2  5.6
tap 4 16 6.4
tap 0 2  7.2

after time 10 {
    if {[catch {
        set ph [debug read memory 0xC04F]
        set lg [debug read memory 0xC040]
        set rm [debug read memory 0xC050]
        if {$ph == 1 && $lg == 0} {
            report [format "GOTO1: OK (dritti all'episodio, stanza %d)" $rm]
        } else {
            report [format "GOTO1: phase=%d leg=%d (attesi 1,0)" $ph $lg]
        }
        screenshot -raw ./build/shot_goto.png
    } err]} { report "ERRORE: $err" }
    exit
}
