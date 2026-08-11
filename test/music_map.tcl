# Cattura ~15s del tema della pergamena in build/map_theme.wav
proc report {msg} {
    set fh [open "build/music_result.txt" a]
    puts $fh $msg
    close $fh
}
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 {
    if {[catch {record start build/map_theme -audioonly} err]} {
        report "ERRORE record: $err"
        exit
    }
    after time 15 {
        catch {record stop}
        report "tema pergamena registrato: build/map_theme.wav"
        exit
    }
}
