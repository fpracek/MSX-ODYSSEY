# Test dell'episodio di EOLO: GOTO3 -> pendici, camino (raffica
# forzata -> la corrente SOLLEVA: vy negativa e quota che sale),
# sala del re (otre -> porta accesa) -> VITTORIA (leg 2 -> 3).
# Esito in build/eolo_result.txt.

proc report {msg} {
    set fh [open "build/eolo_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/eolo_result.txt"}

proc tap {row mask t} {
    after time $t "keymatrixdown $row $mask"
    after time [expr {$t + 0.4}] "keymatrixup $row $mask"
}
# G O T O 3 sul titolo
tap 3 16 4.0
tap 4 16 4.8
tap 5 2  5.6
tap 4 16 6.4
tap 0 8  7.2

# pendici: verifica e via all'uscita (E r6 c26)
after time 10 {
    if {[catch {
        set rm [debug read memory 0xC050]
        if {$rm == 0} {
            report "pendici: OK (stanza 0)"
        } else {
            report [format "pendici: stanza %d (attesa 0)" $rm]
        }
        debug write memory 0xC075 0
        debug write memory 0xC079 0
        debug write memory 0xC052 204
        debug write memory 0xC054 40
    } err]} { report "ERRORE t10: $err" }
}
# camino: nel canale delle piume, raffica forzata
after time 11 {
    if {[catch {
        set rm [debug read memory 0xC050]
        if {$rm == 1} {
            report "camino: OK (stanza 1)"
        } else {
            report [format "camino: stanza %d (attesa 1)" $rm]
        }
        debug write memory 0xC075 0
        debug write memory 0xC079 0
        debug write memory 0xC052 68
        debug write memory 0xC054 128
        debug write memory 0xC058 2
        debug write memory 0xC059 250
    } err]} { report "ERRORE t11: $err" }
}
after time 11.4 {
    if {[catch {
        set vh [debug read memory 0xC056]
        set yh [debug read memory 0xC054]
        if {$vh >= 128 && $yh < 128} {
            report [format "corrente: SOLLEVA (vy=%02X, quota %d)" $vh $yh]
        } else {
            report [format "corrente: vy=%02X quota=%d (attesi neg,<128)" $vh $yh]
        }
        screenshot -raw ./build/shot_eolo1.png
    } err]} { report "ERRORE t11.4: $err" }
}
# via all'uscita in cima (E r2 c13)
after time 12.5 {
    debug write memory 0xC052 100
    debug write memory 0xC054 8
}
# la sala: l'otre sta SUL banco di nuvole (orlo sinistro, c12)
after time 13.5 {
    if {[catch {
        set rm [debug read memory 0xC050]
        set ch [debug read memory 0xC065]
        if {$rm == 2 && $ch == 1} {
            report "sala: OK (stanza 2, i corni di bronzo)"
        } else {
            report [format "sala: room=%d eolo=%d (attesi 2,1)" $rm $ch]
        }
        debug write memory 0xC075 0
        debug write memory 0xC079 0
        debug write memory 0xC052 92
        debug write memory 0xC054 48
    } err]} { report "ERRORE t13.5: $err" }
}
after time 14.5 {
    if {[catch {
        set ot [debug read memory 0xC067]
        set dr [debug read memory 0xC322]
        if {$ot == 1 && $dr == 7} {
            report "otre: RACCOLTO (la porta s'illumina)"
        } else {
            report [format "otre: otre=%d porta=%d (attesi 1,7)" $ot $dr]
        }
        screenshot -raw ./build/shot_eolo2.png
        debug write memory 0xC02B 5
        debug write memory 0xC052 12
        debug write memory 0xC054 128
    } err]} { report "ERRORE t14.5: $err" }
}
after time 17.5 {
    if {[catch {
        set ph [debug read memory 0xC04F]
        set lg [debug read memory 0xC040]
        set ck [debug read memory 0xC042]
        if {$ph == 0 && $lg == 3 && $ck == 6} {
            report "partenza: VITTORIA + compagno ritrovato (5 -> 6)"
        } else {
            report [format "partenza: phase=%d leg=%d crew_keep=%d (attesi 0,3,6)" $ph $lg $ck]
        }
    } err]} { report "ERRORE t17.5: $err" }
    exit
}
