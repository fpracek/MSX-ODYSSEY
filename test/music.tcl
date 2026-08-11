# Cattura ~20s del tema del titolo in build/title_theme.wav
proc report {msg} {
    set fh [open "build/music_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/music_result.txt"}

after time 4 {
    if {[catch {record start build/title_theme -audioonly} err]} {
        report "ERRORE record: $err"
        exit
    }
    report "registrazione avviata"
    after time 20 {
        catch {record stop}
        report "registrazione chiusa: build/title_theme.wav"
        exit
    }
}
