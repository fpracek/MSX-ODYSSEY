# Test dell'episodio di Polifemo: sbarco (arrivo con episodio ->
# phase=1 -> caverna), camminata, cambio stanza via uscita, e il
# ciclope che si sveglia col rumore (stato + mano).
# Esito in build/episode_result.txt.

proc report {msg} {
    set fh [open "build/episode_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/episode_result.txt"}
# FIRE sul titolo, poi si salpa dalla pergamena
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }
# arrivo forzato: approdo -> sbarco
after time 8 { debug write memory 0xC02F 24 }

after time 18 {
    if {[catch {
        set ph [debug read memory 0xC04F]
        set rm [debug read memory 0xC050]
        if {$ph == 1 && $rm == 0} {
            report "sbarco: OK (phase=1, spiaggia)"
        } else {
            report [format "sbarco: phase=%d room=%d (attesi 1,0)" $ph $rm]
        }
        screenshot -raw ./build/shot_beach.png
        set ::wx1 [debug read memory 0xC052]
        keymatrixdown 8 128
    } err]} { report "ERRORE: $err"; exit }
    after time 2 {
        if {[catch {
            keymatrixup 8 128
            set wx2 [debug read memory 0xC052]
            if {$wx2 > $::wx1} {
                report [format "camminata: OK (x %d -> %d)" $::wx1 $wx2]
            } else {
                report [format "camminata: FALLITA (x %d -> %d)" $::wx1 $wx2]
            }
            # teletrasporto sull'uscita della spiaggia (E a riga 6,
            # colonna 29: centro corpo = xh+8, yh+12)
            debug write memory 0xC052 228
            debug write memory 0xC054 40
        } err]} { report "ERRORE: $err"; exit }
        after time 1 {
            if {[catch {
                set rm [debug read memory 0xC050]
                set cy [debug read memory 0xC066]
                if {$rm == 1 && $cy == 1} {
                    report "caverna: OK (stanza 1, ciclope presente)"
                } else {
                    report [format "caverna: room=%d ciclope=%d (attesi 1,1)" $rm $cy]
                }
                # il RUMORE sveglia Polifemo
                debug write memory 0xC058 50
            } err]} { report "ERRORE: $err"; exit }
            after time 2 {
                if {[catch {
                    set st [debug read memory 0xC059]
                    set hx [debug read memory 0xC05B]
                    set cr [debug read memory 0xC02B]
                    if {$st == 2} {
                        report [format "ciclope: ATTACCO (mano a x=%d, ciurma %d)" $hx $cr]
                    } else {
                        report [format "ciclope: stato=%d (atteso 2)" $st]
                    }
                    screenshot -raw ./build/shot_cave.png
                    report "screenshot: build/shot_beach.png / shot_cave.png"
                } err]} { report "ERRORE: $err" }
                exit
            }
        }
    }
}
