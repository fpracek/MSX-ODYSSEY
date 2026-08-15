# Registra l'URLO dell'accecamento: stesso percorso di third.tcl
# (GOTO1 + teletrasporti), ma con la registrazione audio accesa a
# cavallo della stoccata. Esito in build/urlo_result.txt, audio in
# build/urlo.wav.

proc report {msg} {
    set fh [open "build/urlo_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/urlo_result.txt"}

proc tap {row mask t} {
    after time $t "keymatrixdown $row $mask"
    after time [expr {$t + 0.4}] "keymatrixup $row $mask"
}
tap 3 16 4.0
tap 4 16 4.8
tap 5 2  5.6
tap 4 16 6.4
tap 0 2  7.2

after time 10 {
    debug write memory 0xC052 196
    debug write memory 0xC054 40
}
after time 11 {
    debug write memory 0xC052 228
    debug write memory 0xC054 40
}
after time 12 {
    debug write memory 0xC06E 0
}
after time 12.5 {
    debug write memory 0xC058 0
    debug write memory 0xC059 0
    debug write memory 0xC052 136
    debug write memory 0xC054 88
}
after time 13.5 {
    if {[catch {record start build/urlo -audioonly} err]} {
        report "ERRORE record: $err"
    }
}
after time 14 {
    debug write memory 0xC058 0
    debug write memory 0xC059 0
    debug write memory 0xC055 0
    debug write memory 0xC056 0
    debug write memory 0xC052 48
    debug write memory 0xC054 40
}
# il colpo va SFERRATO: freccia in basso
tap 8 64 14.3
after time 15 {
    if {[catch {
        set bl [debug read memory 0xC077]
        set ty [debug read memory 0xC060]
        if {$bl == 1 && $ty == 5} {
            report "urlo: PARTITO (accecato, effetto tipo 5)"
        } else {
            report [format "urlo: blind=%d sfx_ty=%d (attesi 1,5)" $bl $ty]
        }
    } err]} { report "ERRORE t15: $err" }
}
after time 18.5 {
    catch {record stop}
    report "audio in build/urlo.wav (stoccata + primo lamento)"
    exit
}
