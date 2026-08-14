# Test delle tratte SENZA episodio: si forza la tratta 2 (verso
# Eolia, niente sbarco); l'arrivo deve far ripartire il viaggio
# verso le Sirene (leg 3, phase 0). Gli arrivi CON episodio sono
# coperti da episode.tcl (leg 0) e circe.tcl (leg 1).
# Esito in build/legs_result.txt.

proc report {msg} {
    set fh [open "build/legs_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/legs_result.txt"}
# la tratta si forza a titolo visibile (leg e' letto vivo all'arrivo)
after time 3 { debug write memory 0xC040 2 }
# FIRE sul titolo, poi si salpa dalla pergamena (SPACE)
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }
# ... e dalla pergamena della tratta successiva
after time 17 { keymatrixdown 8 1 }
after time 18 { keymatrixup 8 1 }

after time 8 {
    if {[catch {
        set l0 [debug read memory 0xC040]
        if {$l0 == 2} {
            report "tratta forzata: OK (leg=2, verso Eolia)"
        } else {
            report [format "tratta forzata: leg=%d (atteso 2)" $l0]
        }
        debug write memory 0xC02F 60
        report "arrivo forzato: approdo e sequenza di vittoria..."
    } err]} { report "ERRORE: $err"; exit }
    after time 12 {
        if {[catch {
            set l1 [debug read memory 0xC040]
            set md [debug read memory 0xC020]
            set ph [debug read memory 0xC04F]
            if {$l1 == 3 && $md == 0 && $ph == 0} {
                report "tratta successiva: OK (leg=3, verso le Sirene)"
            } else {
                report [format "tratta successiva: leg=%d mode=%d phase=%d (attesi 3,0,0)" \
                    $l1 $md $ph]
            }
            screenshot -raw ./build/shot_leg1.png
        } err]} { report "ERRORE: $err" }
        exit
    }
}
