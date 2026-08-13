# La pupilla che balla: GOTO1, si passa alla caverna, si fa
# rumore quanto basta per l'ALLERTA (occhio aperto, niente mano)
# e si campiona 3 volte la VRAM del tile centrale dell'occhio
# (tile 193, pattern a 0x608): se l'iride scruta, i byte cambiano.
# Esito in build/pupil_result.txt.

proc report {msg} {
    set fh [open "build/pupil_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/pupil_result.txt"}

proc tap {row mask t} {
    after time $t "keymatrixdown $row $mask"
    after time [expr {$t + 0.4}] "keymatrixup $row $mask"
}
tap 3 16 4.0
tap 4 16 4.8
tap 5 2  5.6
tap 4 16 6.4
tap 0 2  7.2

proc eyepat {} {
    set out {}
    for {set i 0} {$i < 8} {incr i} {
        lappend out [debug read VRAM [expr {0x608 + $i}]]
    }
    return $out
}

after time 10 {
    debug write memory 0xC052 196
    debug write memory 0xC054 40
}
after time 11 {
    debug write memory 0xC06E 0
    debug write memory 0xC072 0
    debug write memory 0xC058 30
}
after time 12 {
    if {[catch { set ::s1 [eyepat] } err]} { report "ERRORE t12: $err" }
}
after time 12.4 {
    catch { set ::s2 [eyepat] }
}
after time 12.8 {
    if {[catch {
        set s3 [eyepat]
        set cy [debug read memory 0xC059]
        if {$cy < 1} {
            report [format "pupilla: ciclope non all'erta (stato %d)" $cy]
        } elseif {$::s1 ne $::s2 || $::s2 ne $s3} {
            report "pupilla: BALLA (la VRAM dell'occhio cambia nel tempo)"
            report [format "  t12.0: %s" $::s1]
            report [format "  t12.4: %s" $::s2]
            report [format "  t12.8: %s" $s3]
        } else {
            report [format "pupilla: FERMA (%s in tutti i campioni)" $::s1]
        }
        screenshot -raw ./build/shot_pupil.png
    } err]} { report "ERRORE t12.8: $err" }
    exit
}
