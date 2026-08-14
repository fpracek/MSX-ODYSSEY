# Test dell'episodio di CIRCE: GOTO2 -> bosco di Eea, raccolta
# del MOLY sul sentiero, sala del palazzo, la stella magica cade
# sulla verticale del giocatore fermo -> MAIALE (col moly), fuga
# nel cunicolo basso -> VITTORIA (leg 1 -> 2, rotta per Eolia).
# Esito in build/circe_result.txt.

proc report {msg} {
    set fh [open "build/circe_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/circe_result.txt"}

proc tap {row mask t} {
    after time $t "keymatrixdown $row $mask"
    after time [expr {$t + 0.4}] "keymatrixup $row $mask"
}
# G O T O 2 sul titolo
tap 3 16 4.0
tap 4 16 4.8
tap 5 2  5.6
tap 4 16 6.4
tap 0 4  7.2

# bosco: dritti sul moly (r17 c20)
after time 10 {
    if {[catch {
        set rm [debug read memory 0xC050]
        set l0 [debug read memory 0xC075]
        set l1 [debug read memory 0xC079]
        if {$rm == 0 && $l0 == 1 && $l1 == 1} {
            report "bosco: OK (stanza 0, due leoni di ronda)"
        } else {
            report [format "bosco: room=%d leoni=%d,%d (attesi 0,1,1)" $rm $l0 $l1]
        }
        debug write memory 0xC052 156
        debug write memory 0xC054 128
    } err]} { report "ERRORE t10: $err" }
}
# moly in mano? poi all'uscita (r17 c29)
after time 11 {
    if {[catch {
        set my [debug read memory 0xC067]
        if {$my == 1} {
            report "moly: RACCOLTO"
        } else {
            report [format "moly: ci_moly=%d (atteso 1)" $my]
        }
        debug write memory 0xC052 228
        debug write memory 0xC054 128
    } err]} { report "ERRORE t11: $err" }
}
# la sala: Circe presente; i leoni si spengono (il test aspetta
# fermo la stella: i morsi con iframes maschererebbero il colpo)
after time 12 {
    if {[catch {
        set rm [debug read memory 0xC050]
        set ch [debug read memory 0xC065]
        set l1 [debug read memory 0xC079]
        if {$rm == 1 && $ch == 1 && $l1 == 1} {
            report "sala: OK (stanza 1, Circe canta, 2 leoni)"
        } else {
            report [format "sala: room=%d circe=%d leone2=%d (attesi 1,1,1)" $rm $ch $l1]
        }
        debug write memory 0xC075 0
        debug write memory 0xC079 0
    } err]} { report "ERRORE t12: $err" }
}
after time 13 {
    if {[catch {
        set bs [debug read memory 0xC059]
        if {$bs > 0} {
            report [format "magia: LANCIATA (stato %d)" $bs]
        } else {
            report "magia: nessun incantesimo in volo"
        }
    } err]} { report "ERRORE t13: $err" }
}
# la trasformazione
after time 16 {
    if {[catch {
        set pg [debug read memory 0xC058]
        set hh [debug read memory 0xC068]
        if {$pg > 0 && $hh == 16} {
            report [format "MAIALE: trasformato (timer %d, corpo 16px)" $pg]
        } else {
            report [format "maiale: pig=%d hh=%d (attesi >0,16)" $pg $hh]
        }
        screenshot -raw ./build/shot_circe.png
    } err]} { report "ERRORE t16: $err" }
}
# da maiale, nella porta bassa (r18 c27) -> il PORCILE (stanza 2)
after time 16.5 {
    debug write memory 0xC052 212
    debug write memory 0xC054 136
}
after time 17.5 {
    if {[catch {
        set rm [debug read memory 0xC050]
        set ch [debug read memory 0xC065]
        if {$rm == 2 && $ch == 1} {
            report "porcile: OK (stanza 2, le stelle piovono)"
        } else {
            report [format "porcile: room=%d circe=%d (attesi 2,1)" $rm $ch]
        }
        debug write memory 0xC075 0
    } err]} { report "ERRORE t17.5: $err" }
}
# la stella colpisce il fermo allo spawn: seconda trasformazione
after time 20 {
    if {[catch {
        set pg [debug read memory 0xC058]
        if {$pg > 0} {
            report [format "porcile: di nuovo MAIALE (timer %d)" $pg]
        } else {
            report [format "porcile: pig=%d (atteso >0)" $pg]
        }
        screenshot -raw ./build/shot_cellar.png
    } err]} { report "ERRORE t20: $err" }
}
# dritti all'uscita in cima (E r5 c15, centro-maiale a riga 5)
after time 20.5 {
    debug write memory 0xC052 116
    debug write memory 0xC054 36
}
after time 23 {
    if {[catch {
        set ph [debug read memory 0xC04F]
        set lg [debug read memory 0xC040]
        if {$ph == 0 && $lg == 2} {
            report "fuga: VITTORIA (rotta per Eolia: leg 2)"
        } else {
            report [format "fuga: phase=%d leg=%d (attesi 0,2)" $ph $lg]
        }
    } err]} { report "ERRORE t23: $err" }
    exit
}
