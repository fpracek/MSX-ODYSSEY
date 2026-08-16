# Test dell'approdo della ROTTA FINALE: la tratta 4 (l'unica
# senza sosta intermedia) all'arrivo deve sbarcare DIRITTA
# nell'episodio di Itaca (phase 5), senza tratte fantasma.
# Gli arrivi delle altre isole sono coperti da
# episode/circe/eolo/sirene.tcl (leg 0-3).
# Esito in build/legs_result.txt.

proc report {msg} {
    set fh [open "build/legs_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/legs_result.txt"}
# la tratta si forza a titolo visibile (leg e' letto vivo all'arrivo)
after time 3 { debug write memory 0xC040 4 }
# FIRE sul titolo, poi si salpa dalla pergamena (SPACE)
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }

after time 8 {
    if {[catch {
        set l0 [debug read memory 0xC040]
        if {$l0 == 4} {
            report "tratta forzata: OK (leg=4, la rotta finale)"
        } else {
            report [format "tratta forzata: leg=%d (atteso 4)" $l0]
        }
        debug write memory 0xC02F 60
        report "arrivo forzato: approdo e sbarco a Itaca..."
    } err]} { report "ERRORE: $err"; exit }
    after time 12 {
        if {[catch {
            set l1 [debug read memory 0xC040]
            set ph [debug read memory 0xC04F]
            set rm [debug read memory 0xC050]
            if {$l1 == 4 && $ph == 5 && $rm == 0} {
                report "sbarco: OK (dritti a Itaca, megaron)"
            } else {
                report [format "sbarco: leg=%d phase=%d room=%d (attesi 4,5,0)" \
                    $l1 $ph $rm]
            }
            screenshot -raw ./build/shot_leg1.png
        } err]} { report "ERRORE: $err" }
        exit
    }
}
