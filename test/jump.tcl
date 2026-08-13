# Test del SALTO VERO: GOTO1 -> spiaggia, cammina a destra fino al
# primo gradino (la parete ferma nel punto di stacco), salta
# tenendo destra e verifica l'atterraggio SUL gradino (yh=112,
# feet=136 = cima della piattaforma di riga 17).
# Esito in build/jump_result.txt.

proc report {msg} {
    set fh [open "build/jump_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/jump_result.txt"}

proc tap {row mask t} {
    after time $t "keymatrixdown $row $mask"
    after time [expr {$t + 0.4}] "keymatrixup $row $mask"
}
# GOTO1 sul titolo
tap 3 16 4.0
tap 4 16 4.8
tap 5 2  5.6
tap 4 16 6.4
tap 0 2  7.2

# cammina a destra contro il gradino, poi salta (SPACE) senza mollare
after time 11 { keymatrixdown 8 128 }
after time 13 {
    set x [debug read memory 0xC052]
    report [format "contro il gradino: x=%d (atteso ~35)" $x]
    keymatrixdown 8 1
}
after time 13.4 { keymatrixup 8 1 }
after time 13.6 { keymatrixup 8 128 }
after time 15 {
    if {[catch {
        set y [debug read memory 0xC054]
        set x [debug read memory 0xC052]
        if {$y == 112} {
            report [format "SALITO sul gradino: OK (yh=%d, x=%d)" $y $x]
        } else {
            report [format "salto FALLITO: yh=%d x=%d (atteso yh=112)" $y $x]
        }
        screenshot -raw ./build/shot_jump.png
    } err]} { report "ERRORE: $err" }
    exit
}
