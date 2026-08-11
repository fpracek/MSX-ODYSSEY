# Misura la durata del blast nel vblank: tempo tra le label gauge_on e
# gauge_off (breakpoint sugli indirizzi presi da build/odyssey.sym).
# Uso:  openmsx -machine <macchina> -carta build/nessuno.rom \
#               -romtype ascii8 -script test/measure.tcl
# Riferimenti: vblank utile ~4.4ms @60Hz (NTSC), ~7.7ms @50Hz (PAL).

# l'esito va anche in build/measure_result.txt (lo stdout di
# openmsx.exe su Windows non raggiunge la console)
proc report {msg} {
    puts $msg
    set fh [open "build/measure_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/measure_result.txt"}
# FIRE sul titolo, poi si salpa dalla pergamena (SPACE)
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }


proc load_syms {path} {
    if {[catch {open $path r} fh]} {
        report "ERRORE: impossibile aprire $path (build con --sym?)"
        exit
    }
    set data [read $fh]
    close $fh
    foreach line [split $data "\n"] {
        if {[regexp {^([A-Za-z_][A-Za-z0-9_.]*):?\s+(?:EQU|equ)\s+0[xX]([0-9A-Fa-f]+)} \
                $line -> n v]} {
            set ::S($n) [expr 0x$v]
        }
    }
}

load_syms "build/odyssey.sym"
if {![info exists ::S(gauge_on)] || ![info exists ::S(gauge_off)]} {
    report "ERRORE: label gauge_on/gauge_off non trovate nel .sym"
    exit
}

if {[catch {machine_info time} now]} {
    report "ERRORE: machine_info time non disponibile in questa openMSX."
    report "Usa il gauge visivo: bordo bianco = blast in corso."
    exit
}

set ::t0 -1
set ::n 0
set ::min 999999.0
set ::max 0.0
set ::sum 0.0

debug set_bp $::S(gauge_on) {} {
    set ::t0 [machine_info time]
}
debug set_bp $::S(gauge_off) {} {
    if {$::t0 >= 0} {
        set dt [expr {([machine_info time] - $::t0) * 1000.0}]
        if {$dt < $::min} { set ::min $dt }
        if {$dt > $::max} { set ::max $dt }
        set ::sum [expr {$::sum + $dt}]
        incr ::n
        set ::t0 -1
        if {$::n >= 300} {
            report [format "blast vblank su %d frame: min %.3f ms  media %.3f ms  max %.3f ms" \
                $::n $::min [expr {$::sum / $::n}] $::max]
            report "limite utile: ~4.4 ms @60Hz (NTSC), ~7.7 ms @50Hz (PAL)"
            if {$::max < 4.4} {
                report "VERDETTO: dentro il budget anche a 60Hz"
            } elseif {$::max < 7.7} {
                report "VERDETTO: ok solo a 50Hz, fuori budget a 60Hz"
            } else {
                report "VERDETTO: FUORI BUDGET"
            }
            exit
        }
    }
}

after time 30 {
    report "timeout: nessun campione (il gioco e' partito?)"
    exit
}
