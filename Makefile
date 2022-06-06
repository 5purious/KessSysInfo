BUILDDIR = in
PROGRAMNAME = KessSysInfo
OVMFDIR = OVMFbin

all:
	cd efi; make; mv main.efi ../
	dd if=/dev/zero of=$(BUILDDIR)/$(PROGRAMNAME).img bs=512 count=93750
	mformat -i $(BUILDDIR)/$(PROGRAMNAME).img
	mmd -i $(BUILDDIR)/$(PROGRAMNAME).img ::/EFI
	mmd -i $(BUILDDIR)/$(PROGRAMNAME).img ::/EFI/BOOT
	mcopy -i $(BUILDDIR)/$(PROGRAMNAME).img main.efi ::/EFI/BOOT
	mcopy -i $(BUILDDIR)/$(PROGRAMNAME).img $(BUILDDIR)/startup.nsh ::

run:
	qemu-system-x86_64 -drive file=$(BUILDDIR)/$(PROGRAMNAME).img -m 256M -cpu qemu64 -drive if=pflash,format=raw,unit=0,file="$(OVMFDIR)/OVMF_CODE-pure-efi.fd",readonly=on -drive if=pflash,format=raw,unit=1,file="$(OVMFDIR)/OVMF_VARS-pure-efi.fd" -net none -monitor stdio -d int -no-reboot -D logfile.txt -M smm=off -soundhw pcspk
