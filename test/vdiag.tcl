# Diagnostica VRAM episodio: il tile 3 (pattern+colori) deve essere
# uguale nei 3 terzi dopo il caricamento del tileset della caverna.
proc report {msg} {
    set fh [open "build/vdiag_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/vdiag_result.txt"}
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }
after time 8 { debug write memory 0xC02F 24 }

after time 18 {
    foreach {name base} {pat0 0x0018 pat1 0x0818 pat2 0x1018 \
                         col0 0x2018 col1 0x2818 col2 0x3018} {
        set bytes {}
        for {set i 0} {$i < 8} {incr i} {
            lappend bytes [format %02X [debug read VRAM [expr {$base + $i}]]]
        }
        report "$name: $bytes"
    }
    exit
}
