BUILD_DIR:=build/

all: $(BUILD_DIR)pluto.frm

pluto.frm:
	$(error "Go download the latest release or try make dl0.35")

deps:
	sudo apt-get install device-tree-compiler u-boot-tools coreutils wget

dl0.35:
	wget https://github.com/analogdevicesinc/plutosdr-fw/releases/download/v0.35/plutosdr-fw-v0.35.zip && \
	unzip plutosdr-fw-v0.35.zip

$(BUILD_DIR)FPGA $(BUILD_DIR)Ramdisk $(BUILD_DIR)Linux $(BUILD_DIR)zynq-pluto-sdr $(BUILD_DIR)zynq-pluto-sdr-revb $(BUILD_DIR)zynq-pluto-sdr-revc: pluto.frm
	mkdir -p $(BUILD_DIR) && \
	cd $(BUILD_DIR) && \
	dtc -O dts ../pluto.frm | python3 ../extract_data_dts.py /dev/stdin

$(BUILD_DIR)%.dtb: $(BUILD_DIR)%
	mv $< $@

$(BUILD_DIR)system_top.bit: $(BUILD_DIR)FPGA
	mv $< $@

$(BUILD_DIR)zImage: $(BUILD_DIR)Linux
	mv $< $@

$(BUILD_DIR)rootfs.cpio.gz: $(BUILD_DIR)Ramdisk	
	mv $< $@

extract: $(BUILD_DIR)system_top.bit $(BUILD_DIR)rootfs.cpio.gz $(BUILD_DIR)zImage $(BUILD_DIR)zynq-pluto-sdr.dtb $(BUILD_DIR)zynq-pluto-sdr-revb.dtb $(BUILD_DIR)zynq-pluto-sdr-revc.dtb 

pluto.its:
	wget https://raw.githubusercontent.com/analogdevicesinc/plutosdr-fw/master/scripts/pluto.its

$(BUILD_DIR)pluto.its: pluto.its
	cp $< $@

$(BUILD_DIR)pluto.itb: $(BUILD_DIR)system_top.bit $(BUILD_DIR)pluto.its $(BUILD_DIR)zynq-pluto-sdr.dtb $(BUILD_DIR)zynq-pluto-sdr-revb.dtb $(BUILD_DIR)zynq-pluto-sdr-revc.dtb $(BUILD_DIR)zImage $(BUILD_DIR)rootfs.cpio.gz
	cd $(BUILD_DIR) && \
	mkimage -f pluto.its pluto.itb

$(BUILD_DIR)pluto.frm.md5: $(BUILD_DIR)pluto.itb
	cd $(BUILD_DIR) && \
	md5sum pluto.itb | cut -d ' ' -f 1 > pluto.frm.md5

$(BUILD_DIR)pluto.frm: $(BUILD_DIR)pluto.itb $(BUILD_DIR)pluto.frm.md5
	cat $^ > $@

$(BUILD_DIR)pluto.dfu: $(BUILD_DIR)pluto.itb $(BUILD_DIR)pluto.frm
	cd $(BUILD_DIR) && \
	cp pluto.itb pluto.dfu && \
	dfu-suffix -a pluto.dfu -v 0x0456 -p 0xb673

$(BUILD_DIR)rootfs.cpio: $(BUILD_DIR)rootfs.cpio.gz
	gzip -d $<

# $(BUILD_DIR)rootfs: $(BUILD_DIR)rootfs.cpio
# 	mkdir -p $@ && \
# 	cd $@ && \
# 	cpio -id < ../rootfs.cpio

.PHONY: dl0.35 extract-dtc extract

clean:
	rm -f pluto.dfu uboot-env.dfu boot.dfu boot.frm

deepclean: clean
	rm -f pluto.frm