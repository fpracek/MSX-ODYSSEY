# Test dell'episodio delle SIRENE: GOTO4 -> spiaggia delle ossa.
# Si forza il CANTO e si verifica che TRASCINI verso la sirena;
# poi che l'ormeggio TENGA (fermo nel raggio del palo). Scogli,
# nido: cera -> porta accesa -> VITTORIA (leg 3 -> 4).
# Esito in build/sirene_result.txt.

proc report {msg} {
    set fh [open "build/sirene_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/sirene_result.txt"}

proc tap {row mask t} {
    after time $t "keymatrixdown $row $mask"
    after time [expr {$t + 0.4}] "keymatrixup $row $mask"
}
# G O T O 4 sul titolo
tap 3 16 4.0
tap 4 16 4.8
tap 5 2  5.6
tap 4 16 6.4
tap 0 16 7.2

# spiaggia: canto forzato, fermo e SCOPERTO a x=100 (sirena a 208)
after time 10 {
    if {[catch {
        set rm [debug read memory 0xC050]
        if {$rm == 0} {
            report "spiaggia: OK (stanza 0)"
        } else {
            report [format "spiaggia: stanza %d (attesa 0)" $rm]
        }
        debug write memory 0xC052 100
        debug write memory 0xC054 128
        debug write memory 0xC058 2
        debug write memory 0xC059 250
    } err]} { report "ERRORE t10: $err" }
}
after time 11 {
    if {[catch {
        set x [debug read memory 0xC052]
        if {$x > 112} {
            report [format "canto: TRASCINA (x 100 -> %d, verso la sirena)" $x]
        } else {
            report [format "canto: x=%d (atteso >112)" $x]
        }
        screenshot -raw ./build/shot_sirene1.png
        # ora LEGATO al palo (zona 72-95, centro 88) col canto vivo
        debug write memory 0xC052 80
        debug write memory 0xC058 2
        debug write memory 0xC059 250
    } err]} { report "ERRORE t11: $err" }
}
after time 12 {
    if {[catch {
        set x [debug read memory 0xC052]
        if {$x >= 78 && $x <= 82} {
            report [format "ormeggio: TIENE (fermo a x=%d nel canto)" $x]
        } else {
            report [format "ormeggio: x=%d (atteso ~80)" $x]
        }
        debug write memory 0xC052 228
        debug write memory 0xC054 128
    } err]} { report "ERRORE t12: $err" }
}
# scogli: dritti all'uscita in cima (E r6 c14)
after time 13 {
    if {[catch {
        set rm [debug read memory 0xC050]
        if {$rm == 1} {
            report "scogli: OK (stanza 1)"
        } else {
            report [format "scogli: stanza %d (attesa 1)" $rm]
        }
        debug write memory 0xC052 108
        debug write memory 0xC054 40
    } err]} { report "ERRORE t13: $err" }
}
# il nido: la cera sul piedistallo (stand r11, corolla r9 c16)
after time 14 {
    if {[catch {
        set rm [debug read memory 0xC050]
        if {$rm == 2} {
            report "nido: OK (stanza 2)"
        } else {
            report [format "nido: stanza %d (attesa 2)" $rm]
        }
        debug write memory 0xC052 124
        debug write memory 0xC054 64
    } err]} { report "ERRORE t14: $err" }
}
after time 15 {
    if {[catch {
        set ce [debug read memory 0xC067]
        set dr [debug read memory 0xC33D]
        if {$ce == 1 && $dr == 7} {
            report "cera: NELLE ORECCHIE (la porta s'illumina)"
        } else {
            report [format "cera: cera=%d porta=%d (attesi 1,7)" $ce $dr]
        }
        screenshot -raw ./build/shot_sirene2.png
        debug write memory 0xC052 228
        debug write memory 0xC054 128
    } err]} { report "ERRORE t15: $err" }
}
after time 18 {
    if {[catch {
        set ph [debug read memory 0xC04F]
        set lg [debug read memory 0xC040]
        if {$ph == 0 && $lg == 4} {
            report "fuga: VITTORIA (rotta per Scilla: leg 4)"
        } else {
            report [format "fuga: phase=%d leg=%d (attesi 0,4)" $ph $lg]
        }
    } err]} { report "ERRORE t18: $err" }
    exit
}
