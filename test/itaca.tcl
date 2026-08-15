# Test di ITACA, il finale: GOTO6 -> megaron (Proci di ronda),
# la prova dell'arco (raccolta + tiro attraverso le scuri -> la
# porta si apre), la STRAGE (l'ultimo Proco cade -> porta) e il
# VIAGGIO COMPIUTO (il giro si chiude: leg torna 0, titolo).
# Esito in build/itaca_result.txt.

proc report {msg} {
    set fh [open "build/itaca_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/itaca_result.txt"}

proc tap {row mask t} {
    after time $t "keymatrixdown $row $mask"
    after time [expr {$t + 0.4}] "keymatrixup $row $mask"
}
# G O T O 6 sul titolo
tap 3 16 4.0
tap 4 16 4.8
tap 5 2  5.6
tap 4 16 6.4
tap 0 64 7.2

# megaron: Proci di ronda; poi dritti all'uscita
after time 10 {
    if {[catch {
        set rm [debug read memory 0xC050]
        set p0 [debug read memory 0xC075]
        if {$rm == 0 && $p0 == 1} {
            report "megaron: OK (stanza 0, i Proci fanno la ronda)"
        } else {
            report [format "megaron: room=%d proci=%d (attesi 0,1)" $rm $p0]
        }
        debug write memory 0xC075 0
        debug write memory 0xC079 0
        debug write memory 0xC052 228
        debug write memory 0xC054 128
    } err]} { report "ERRORE t10: $err" }
}
# la prova: l'arco sul piedistallo (stand r14, impugnatura r12 c10)
after time 11 {
    if {[catch {
        set rm [debug read memory 0xC050]
        if {$rm == 1} {
            report "prova: OK (stanza 1, Penelope al telaio)"
        } else {
            report [format "prova: stanza %d (attesa 1)" $rm]
        }
        debug write memory 0xC052 76
        debug write memory 0xC054 88
    } err]} { report "ERRORE t11: $err" }
}
# arco in mano; a terra, da fermo, FIRE: la freccia vola
after time 12 {
    if {[catch {
        set ar [debug read memory 0xC067]
        if {$ar == 1} {
            report "arco: IN MANO"
        } else {
            report [format "arco: arco=%d (atteso 1)" $ar]
        }
        debug write memory 0xC052 40
        debug write memory 0xC054 128
    } err]} { report "ERRORE t12: $err" }
}
tap 8 1 12.5
after time 13 {
    if {[catch {
        screenshot -raw ./build/shot_itaca1.png
    } err]} { report "ERRORE t13: $err" }
}
after time 14 {
    if {[catch {
        set dr [debug read memory 0xC33D]
        if {$dr == 7} {
            report "tiro: LA PROVA E' SUPERATA (la porta si apre)"
        } else {
            report [format "tiro: porta=%d (atteso 7)" $dr]
        }
        debug write memory 0xC052 228
        debug write memory 0xC054 128
    } err]} { report "ERRORE t14: $err" }
}
# la strage: resta un solo Proco (dead forzato a 4), e cade
after time 15 {
    if {[catch {
        set rm [debug read memory 0xC050]
        set p0 [debug read memory 0xC075]
        if {$rm == 2 && $p0 == 1} {
            report "strage: OK (stanza 2, i Proci caricano)"
        } else {
            report [format "strage: room=%d proci=%d (attesi 2,1)" $rm $p0]
        }
        debug write memory 0xC075 0
        debug write memory 0xC069 4
        debug write memory 0xC052 120
        debug write memory 0xC054 128
    } err]} { report "ERRORE t15: $err" }
}
tap 8 1 15.5
tap 8 1 16.3
tap 8 1 17.1
after time 18 {
    if {[catch {
        set dd [debug read memory 0xC069]
        set dr [debug read memory 0xC33D]
        if {$dd == 5 && $dr == 7} {
            report "strage: L'ULTIMO PROCO E' CADUTO (porta aperta)"
        } else {
            report [format "strage: dead=%d porta=%d (attesi 5,7)" $dd $dr]
        }
        screenshot -raw ./build/shot_itaca2.png
        debug write memory 0xC052 228
        debug write memory 0xC054 128
    } err]} { report "ERRORE t18: $err" }
}
# il TALAMO: Penelope, Telemaco, il letto d'ulivo - e l'uscita
after time 19 {
    if {[catch {
        set rm [debug read memory 0xC050]
        if {$rm == 3} {
            report "talamo: OK (la famiglia attende)"
        } else {
            report [format "talamo: stanza %d (attesa 3)" $rm]
        }
        screenshot -raw ./build/shot_itaca3.png
        debug write memory 0xC052 220
        debug write memory 0xC054 128
    } err]} { report "ERRORE t19: $err" }
}
after time 22 {
    if {[catch {
        set lg [debug read memory 0xC040]
        set ph [debug read memory 0xC04F]
        if {$lg == 0 && $ph == 0} {
            report "ITACA: IL VIAGGIO E' COMPIUTO (il giro si chiude)"
        } else {
            report [format "finale: leg=%d phase=%d (attesi 0,0)" $lg $ph]
        }
    } err]} { report "ERRORE t22: $err" }
    exit
}
