all:
	riscv32-unknown-elf-gcc  init.S core_main.c ee_printf.c cmd.c led.c -T link.ld -nostdlib -o test.elf -lc -L /opt/riscv/lib/gcc/riscv32-unknown-elf/9.2.0 -lgcc -mtune=size -march=rv32i
	riscv32-unknown-elf-objdump  -D test.elf > test.elf.objdump
	riscv32-unknown-elf-objcopy  test.elf -O ihex test.elf.objcopy
	python ../../riscv-compliance-master/gen_mif.py ./test.elf.objcopy
	cp inst_data dram_data ../sim
	#E:\software\gnu-mcu-eclipse-riscv-none-gcc-8.2.0-2.2-20190521-0004-win64\bin\riscv-none-embed-gcc  init.S core_main.c ee_printf.c cmd.c led.c -T link.ld -nostdlib -o test.elf -lc -L E:\software\gnu-mcu-eclipse-riscv-none-gcc-8.2.0-2.2-20190521-0004-win64\lib\gcc\riscv-none-embed\8.2.0 -lgcc -mtune=size -march=rv32i
	#E:\software\gnu-mcu-eclipse-riscv-none-gcc-8.2.0-2.2-20190521-0004-win64\bin\riscv-none-embed-objcopy  test.elf -O ihex test.elf.objcopy
	#E:\software\gnu-mcu-eclipse-riscv-none-gcc-8.2.0-2.2-20190521-0004-win64\bin\riscv-none-embed-objdump  -D test.elf > test.elf.objdump
clean:
	rm *elf *objdump *objcopy
