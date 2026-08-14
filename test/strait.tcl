# Test dello STRETTO (tratta 4, Scilla e Cariddi): si forza la
# tratta, si salpa, e si verifica: (1) Scilla erutta MIRANDO alla
# nave; (2) il risucchio di Cariddi trascina la nave al gorgo e il
# gorgo costa un compagno con sputo; (3) l'arrivo porta a leg 5.
# Esito in build/strait_result.txt.

proc report {msg} {
    set fh [open "build/strait_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/strait_result.txt"}

after time 3 { debug write memory 0xC040 4 }
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }

# la prima quiete dura 120f: Scilla erutta a ~2.4s dalla salpata
after time 11 {
    if {[catch {
        set st [debug read memory 0xC090]
        set rt [debug read memory 0xC034]
        set rx [debug read memory 0xC036]
        set sx [debug read memory 0xC01D]
        if {$st == 1 && $rt > 0} {
            report [format "Scilla: ERUTTA mirata (mostro a x=%d, nave a x=%d)" $rx $sx]
        } else {
            report [format "Scilla: st=%d rock_t=%d (attesi 1,>0)" $st $rt]
        }
    } err]} { report "ERRORE t11: $err" }
}
# CARIDDI forzata: gorgo a sinistra, risucchio lungo
after time 12 {
    if {[catch {
        debug write memory 0xC034 0
        debug write memory 0xC092 40
        debug write memory 0xC090 3
        debug write memory 0xC091 250
        set ::x0 [debug read memory 0xC01D]
    } err]} { report "ERRORE t12: $err" }
}
after time 13 {
    if {[catch {
        set x1 [debug read memory 0xC01D]
        if {$x1 < $::x0 - 20} {
            report [format "Cariddi: RISUCCHIA (nave x %d -> %d)" $::x0 $x1]
        } else {
            report [format "Cariddi: x %d -> %d (atteso -20+)" $::x0 $x1]
        }
        screenshot -raw ./build/shot_strait.png
    } err]} { report "ERRORE t13: $err" }
}
# il gorgo ha morso e sputato: si chiude il risucchio e si conta
after time 14 {
    debug write memory 0xC090 0
    debug write memory 0xC091 200
}
after time 14.6 {
    if {[catch {
        set cr [debug read memory 0xC02B]
        set x2 [debug read memory 0xC01D]
        if {$cr < 12 && $x2 > 64} {
            report [format "gorgo: MORDE E SPUTA (ciurma %d, a x=%d)" $cr $x2]
        } else {
            report [format "gorgo: ciurma=%d x=%d (attesi <12, >64)" $cr $x2]
        }
        debug write memory 0xC02F 60
    } err]} { report "ERRORE t14.6: $err" }
}
# l'approdo e' una cinematica lenta: la pergamena arriva dopo
after time 24 { keymatrixdown 8 1 }
after time 25 { keymatrixup 8 1 }
after time 27 {
    if {[catch {
        set lg [debug read memory 0xC040]
        set ph [debug read memory 0xC04F]
        if {$lg == 5 && $ph == 0} {
            report "stretto: SUPERATO (rotta per Itaca: leg 5)"
        } else {
            report [format "stretto: leg=%d phase=%d (attesi 5,0)" $lg $ph]
        }
    } err]} { report "ERRORE t27: $err" }
    exit
}
