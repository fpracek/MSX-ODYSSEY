# Cheat RENZO: digitato sul titolo attiva l'immortalita' della
# ciurma (god_flag 0xC440 = 0xA5, jingle di conferma). Il test:
# verifica flag spento al boot, digita RENZO, verifica il flag,
# poi GOTO1 e si FA MORDERE dal pipistrello sul gradino r14 della
# spiaggia: lo spintone (x cambia) prova il morso, la ciurma deve
# restare 12. Esito in build/renzo_result.txt.

proc report {msg} {
    set fh [open "build/renzo_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/renzo_result.txt"}

proc tap {row mask t} {
    after time $t "keymatrixdown $row $mask"
    after time [expr {$t + 0.4}] "keymatrixup $row $mask"
}

after time 3.5 {
    if {[catch {
        set g [debug read memory 0xC440]
        if {$g != 165} {
            report "boot: OK (protezione spenta)"
        } else {
            report "boot: god_flag gia' attivo?!"
        }
    } err]} { report "ERRORE t3.5: $err" }
}
# R E N Z O sul titolo
tap 4 128 4.0
tap 3 4   4.8
tap 4 8   5.6
tap 5 128 6.4
tap 4 16  7.2

after time 8.5 {
    if {[catch {
        set g [debug read memory 0xC440]
        if {$g == 165} {
            report "RENZO: ATTIVO (god_flag = A5)"
        } else {
            report [format "RENZO: god_flag=%02X (atteso A5)" $g]
        }
    } err]} { report "ERRORE t8.5: $err" }
}
# G O T O 1: dritti alla spiaggia
tap 3 16 9.0
tap 4 16 9.8
tap 5 2  10.6
tap 4 16 11.4
tap 0 2  12.2

# sul gradino r14 (quota del pipistrello basso): il morso arriva
after time 15 {
    debug write memory 0xC052 104
    debug write memory 0xC054 88
}
after time 19 {
    if {[catch {
        set cr [debug read memory 0xC02B]
        set x  [debug read memory 0xC052]
        if {$cr == 12 && $x != 104} {
            report [format "morso: SUBITO E GRATIS (spintone a x=%d, ciurma 12)" $x]
        } elseif {$cr == 12} {
            report "morso: mai arrivato (x fermo), ciurma 12 - inconcludente"
        } else {
            report [format "morso: ciurma %d (attesa 12!) x=%d" $cr $x]
        }
    } err]} { report "ERRORE t19: $err" }
    exit
}
