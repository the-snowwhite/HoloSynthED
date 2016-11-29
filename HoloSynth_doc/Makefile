help:
	@echo -e "Select operation to perform. Type 'make' followed by the name of the operation."
	@echo
#	@echo -e "Available operations:"
#	@echo -e "doxygen             - run the doxygen tool on the aoOCS project."
#	@echo -e "                      Doxverilog version required."
#	@echo -e "control_osd         - generate ./rtl/control_osd.mif"
#	@echo -e "sd_disk             - generate SD disk image containing ROMs and ADFs."
#	@echo -e "                      The disk image should be written to a SD card starting at offset 0."
#	@echo -e "spec_extract        - generate the specification.odt file from the Doxygen HTML docs."
#	@echo -e "vga_to_png          - extract VGA dump file to a set of PNG frame images."
	@echo -e "de2_115_ltm	- synthesise the Holosynth project for the Terasic DE2-115 board with LTM."
	@echo -e "veek		- synthesise the Holosynth project for the Terasic tPad/VEEK board."
	@echo -e "clean               - clean all."
	@echo
	@exit 0

#doxygen: ./doc/doxygen/doxygen.cfg
#ifndef DOXVERILOG
#	@echo "DOXVERILOG environment variable not set. Set it to a Doxverilog executable."
#	@exit 1
#endif
#	$(DOXVERILOG) ./doc/doxygen/doxygen.cfg


de2_115_ltm:
	mkdir -p ./tmp/de2_115_ltm
	cp ./rtl/verilog/Altera/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/board/terasic/common/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/board/terasic/common/*.sv ./tmp/de2_115_ltm
	cp ./rtl/verilog/board/terasic/de2_115/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/board/terasic/de2_115/*.qsys ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/display/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/display/*.hex ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/midi/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/midi/*.sv ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/synth/*.v ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/synth/*.sv ./tmp/de2_115_ltm
	cp ./rtl/verilog/common/synth/*.mif ./tmp/de2_115_ltm
	cp ./syn/Altera/terasic/de2_115_ltm/*.qpf ./tmp/de2_115_ltm
	cp ./syn/Altera/terasic/de2_115_ltm/*.qsf ./tmp/de2_115_ltm
	cp ./syn/Altera/terasic/de2_115_ltm/*.sdc ./tmp/de2_115_ltm
	cd ./tmp/de2_115_ltm && quartus_sh --flow compile Holosynth

veek:
	mkdir -p ./tmp/veek
	cp ./rtl/verilog/Altera/*.v ./tmp/veek
	cp ./rtl/verilog/board/terasic/common/*.v ./tmp/veek
	cp ./rtl/verilog/board/terasic/common/*.sv ./tmp/veek
	cp ./rtl/verilog/board/terasic/veek/*.v ./tmp/veek
	cp ./rtl/verilog/board/terasic/veek/*.qsys ./tmp/veek
	cp ./rtl/verilog/common/*.v ./tmp/veek
	cp ./rtl/verilog/common/display/*.v ./tmp/veek
	cp ./rtl/verilog/common/display/*.hex ./tmp/veek
	cp ./rtl/verilog/common/midi/*.v ./tmp/veek
	cp ./rtl/verilog/common/midi/*.sv ./tmp/veek
	cp ./rtl/verilog/common/synth/*.v ./tmp/veek
	cp ./rtl/verilog/common/synth/*.sv ./tmp/veek
	cp ./rtl/verilog/common/synth/*.mif ./tmp/veek
	cp ./syn/Altera/terasic/veek/*.qpf ./tmp/veek
	cp ./syn/Altera/terasic/veek/*.qsf ./tmp/veek
	cp ./syn/Altera/terasic/veek/*.sdc ./tmp/veek
	cd ./tmp/veek && quartus_sh --flow compile VEEKsynth

clean:
	rm -R -f ./tmp/*
