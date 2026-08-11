ROM = build/odyssey.rom

all: $(ROM)

$(ROM): src/main.asm src/episode.asm src/waves_data.asm src/ship_data.asm \
        src/sky_data.asm src/map0_pat.bin src/title_pat.bin \
        src/music_data.asm src/fade_data.asm src/cave_data.asm
	@mkdir -p build
	sjasmplus --msg=err --sym=build/odyssey.sym src/main.asm

src/waves_data.asm: tools/gen_waves.py
	python3 tools/gen_waves.py

src/ship_data.asm: tools/gen_ship.py
	python3 tools/gen_ship.py

src/sky_data.asm: tools/gen_sky.py
	python3 tools/gen_sky.py

src/map0_pat.bin: tools/gen_map.py tools/gen_sky.py
	python3 tools/gen_map.py

src/title_pat.bin: tools/gen_title.py tools/gen_map.py tools/gen_sky.py
	python3 tools/gen_title.py

src/music_data.asm: tools/gen_music.py
	python3 tools/gen_music.py

src/fade_data.asm: tools/gen_fade.py
	python3 tools/gen_fade.py

src/cave_data.asm: tools/gen_cave.py tools/gen_sky.py
	python3 tools/gen_cave.py

waves:
	python3 tools/gen_waves.py

ship:
	python3 tools/gen_ship.py

sky:
	python3 tools/gen_sky.py

# nota: niente SDL_VIDEODRIVER=dummy - la build Windows di openMSX
# esce subito col driver dummy; la finestra si chiude da sola all'exit
# dello script. Esiti in build/boot_result.txt e build/measure_result.txt
OPENMSX = E:/Dropbox/FAUSTO/SVILUPPI/MSX/EMULATORI/openMSX/openmsx.exe

test: $(ROM)
	"$(OPENMSX)" -machine C-BIOS_MSX1_EU \
	  -carta $(ROM) -romtype ascii8 -script test/boot.tcl

measure: $(ROM)
	"$(OPENMSX)" -machine C-BIOS_MSX1_EU \
	  -carta $(ROM) -romtype ascii8 -script test/measure.tcl

.PHONY: all waves ship sky test measure
