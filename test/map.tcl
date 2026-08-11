# Test title + pergamena: al boot deve esserci il TITLE SCREEN
# (screenshot + musica PSG in moto), col FIRE si passa alla
# pergamena (screenshot), con un altro FIRE si salpa (hook attivo).
# Esito in build/map_result.txt.

proc report {msg} {
    set fh [open "build/map_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/map_result.txt"}

proc load_syms {path} {
    set fh [open $path r]
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

after time 5 {
    if {[catch {
        screenshot -raw ./build/shot_title.png
        report "screenshot titolo: build/shot_title.png"
        # il basso alterna le ottave ogni croma: R2 deve muoversi
        set p1 [debug read "PSG regs" 2]
        after time 1 {
            set p2 [debug read "PSG regs" 2]
            set v [debug read "PSG regs" 8]
            if {($p2 != $p1 || $p1 != 0) && $v > 0} {
                report [format "musica del titolo: ATTIVA (vol=%d, basso %d->%d)" $v $p1 $p2]
            } else {
                report [format "musica del titolo: FERMA (vol=%d)" $v]
            }
            keymatrixdown 8 1
            after time 1 {
                keymatrixup 8 1
                after time 2 {
                    screenshot -raw ./build/shot_map.png
                    report "screenshot pergamena: build/shot_map.png"
                    set vm [debug read "PSG regs" 8]
                    if {$vm > 0} {
                        report [format "musica pergamena: ATTIVA (vol=%d)" $vm]
                    } else {
                        report "musica pergamena: FERMA (vol=0)"
                    }
                    # QUALE brano? il puntatore dello stream A deve
                    # stare dentro map_chA..song_title (tema lira)
                    set p [expr {[debug read memory 0xC043] | \
                                 ([debug read memory 0xC044] << 8)}]
                    if {$p >= $::S(map_chA) && $p < $::S(song_title)} {
                        report [format "brano: LIRA della pergamena (ptr %04X)" $p]
                    } else {
                        report [format "brano: SBAGLIATO, e' il titolo (ptr %04X, map_chA=%04X)" \
                            $p $::S(map_chA)]
                    }
                    set ::f1 [debug read memory 0xC001]
                    keymatrixdown 8 1
                    after time 1 {
                        keymatrixup 8 1
                        after time 2 {
                            set f2 [debug read memory 0xC001]
                            if {$f2 != $::f1} {
                                report "salpati: OK (hook attivo dopo il 2o FIRE)"
                            } else {
                                report "salpati: FALLITO (hook fermo)"
                            }
                            exit
                        }
                    }
                }
            }
        }
    } err]} { report "ERRORE: $err"; exit }
}
