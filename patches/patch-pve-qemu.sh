#! /bin/bash

if [ -z "$1" ]; then
  echo "No submodule argument supplied"
  exit 1
fi
MODULE=$1

if [ -z "$2" ]; then
  CPU_VENDOR_ID=$(lscpu | grep "Vendor ID" | awk '{print $3}' | head -n 1)
else
  CPU_VENDOR_ID=$2
fi

# Clean up previous patches
cd $MODULE/qemu

export QUILT_PATCHES=../debian/patches
export QUILT_REFRESH_ARGS="-p ab --no-timestamps --no-index" 
PATCH_PRESENT=$(quilt series | grep "-evasion.patch")
if [ -n "$PATCH_PRESENT" ]; then
  quilt delete -r $PATCH_PRESENT
fi

# Load previous patches
quilt push -a

if [[ ! "$CPU_VENDOR_ID" =~ .*AuthenticAMD.* ]] && [[ ! "$CPU_VENDOR_ID" =~ .*GenuineIntel.* ]]; then
  echo "Unknown CPU vendor"
  exit 1
fi

if [[ "$CPU_VENDOR_ID" =~ .*AuthenticAMD.* ]]; then
  echo "AMD CPU detected, applying AMD patches"
  PATCH_FILE="amd-evasion.patch"
  quilt new $PATCH_FILE

  quilt add hw/arm/virt.c
  sed -i 's/QEMU " MACHINE_VER_STR(__VA_ARGS__) " ARM Virtual Machine"/AMD  " MACHINE_VER_STR(__VA_ARGS__) " ARM Machine"/' hw/arm/virt.c
  sed -i 's/QEMU Virtual Machine/AMD Machine/' hw/arm/virt.c
  sed -i 's/KVM Virtual Machine/AMD Machine/' hw/arm/virt.c

  quilt add hw/i386/pc_q35.c
  sed -i 's/m->desc = "Standard PC (Q35 + ICH9, 2009)";/m->desc = "AMD Ryzen 7 7700X 8-Core Processor";/' hw/i386/pc_q35.c
  
  quilt add hw/m68k/virt.c
  sed -i 's/"QEMU M68K Virtual Machine"/"AMD M68K Machine"/' hw/m68k/virt.c
  sed -i 's/"QEMU " MACHINE_VER_STR(__VA_ARGS__) " M68K Virtual Machine"/"AMD  " MACHINE_VER_STR(__VA_ARGS__) " M68K Machine"/' hw/m68k/virt.c

  quilt add hw/loongarch/virt.c
  sed -i 's/"QEMU Virtual Machine"/"AMD Machine"/' hw/loongarch/virt.c

  # dont need?
  # quilt add hw/ppc/spapr_pci.c
  # sed -i 's/const char \*devtype = "qemu";/const char \*devtype = "amd";/' hw/ppc/spapr_pci.c

  quilt add include/hw/acpi/aml-build.h
  sed -i 's/"BOCHS "/"ALASKA"/g' include/hw/acpi/aml-build.h
  sed -i 's/"BXPC    "/"A M I "/g' include/hw/acpi/aml-build.h

  quilt add target/i386/cpu.c
  sed -i 's/"QEMU Virtual CPU version "/"AMD CPU version "/g' target/i386/cpu.c
  sed -i 's/"Common KVM processor"/"Common AMD processor"/g' target/i386/cpu.c
  sed -i 's/"Common 32-bit KVM processor"/"Common 32-bit AMD processor"/g' target/i386/cpu.c
  sed -i 's/"Microsoft Hv"/"AuthenticAMD"/g' target/i386/cpu.c

  quilt add target/s390x/tcg/misc_helper.c
  sed -i 's/"QEMU            "/"AMD             "/g' target/s390x/tcg/misc_helper.c
  sed -i 's/"QEMU"/"AMD "/g' target/s390x/tcg/misc_helper.c
  sed -i 's/"QEMUQEMUQEMUQEMU"/"AMDAMDAMDAMDAMDA"/g' target/s390x/tcg/misc_helper.c
  sed -i 's/"QEMU    "/"AMD     "/g' target/s390x/tcg/misc_helper.c
  sed -i 's/"KVM\/Linux       "/"AMDAMDAMD       "/g' target/s390x/tcg/misc_helper.c

  quilt add target/i386/kvm/kvm.c
  sed -i 's/memcpy(signature, "Microsoft VS", 12);/memcpy(signature, "AuthenticAMD", 12);/' target/i386/kvm/kvm.c
  sed -i 's/memcpy(signature, "VS#1\\0\\0\\0\\0\\0\\0\\0\\0", 12);/memcpy(signature, "AuthenticAMD", 12);/' target/i386/kvm/kvm.c
  sed -i 's/memcpy(signature, "XenVMMXenVMM", 12);/memcpy(signature, "AuthenticAMD", 12);/' target/i386/kvm/kvm.c
  sed -i 's/memcpy(signature, "KVMKVMKVM\\0\\0\\0", 12);/memcpy(signature, "AuthenticAMD", 12);/' target/i386/kvm/kvm.c
fi

if [[ "$CPU_VENDOR_ID" =~ .*GenuineIntel.* ]]; then
  echo "Intel CPU detected, applying Intel patches"
  PATCH_FILE="intel-evasion.patch"
  quilt new $PATCH_FILE

  quilt add hw/arm/virt.c
  sed -i 's/QEMU " MACHINE_VER_STR(__VA_ARGS__) " ARM Virtual Machine"/Intel" MACHINE_VER_STR(__VA_ARGS__) " ARM Machine"/' hw/arm/virt.c
  sed -i 's/QEMU Virtual Machine/Intel Machine/' hw/arm/virt.c
  sed -i 's/KVM Virtual Machine/Intel Machine/' hw/arm/virt.c

  quilt add hw/i386/pc_q35.c
  sed -i 's/m->desc = "Standard PC (Q35 + ICH9, 2009)";/m->desc = "Intel Core i7-13700K 8-Core Processor";/' hw/i386/pc_q35.c

  quilt add hw/m68k/virt.c
  sed -i 's/"QEMU M68K Virtual Machine"/"Intel M68K Machine"/' hw/m68k/virt.c
  sed -i 's/"QEMU " MACHINE_VER_STR(__VA_ARGS__) " M68K Virtual Machine"/"Intel  " MACHINE_VER_STR(__VA_ARGS__) " M68K Machine"/' hw/m68k/virt.c

  quilt add hw/loongarch/virt.c
  sed -i 's/"QEMU Virtual Machine"/"Intel Machine"/' hw/loongarch/virt.c

  # dont need?
  # quilt add hw/ppc/spapr_pci.c
  # sed -i 's/const char \*devtype = "qemu";/const char \*devtype = "intel";/' hw/ppc/spapr_pci.c

  quilt add include/hw/acpi/aml-build.h
  sed -i 's/"BOCHS "/"INTEL "/g' include/hw/acpi/aml-build.h
  sed -i 's/"BXPC    "/"U Rvp   "/g' include/hw/acpi/aml-build.h

  quilt add target/i386/cpu.c
  sed -i 's/"QEMU Virtual CPU version "/"Intel CPU version "/g' target/i386/cpu.c
  sed -i 's/"Common KVM processor"/"Common Intel processor"/g' target/i386/cpu.c
  sed -i 's/"Common 32-bit KVM processor"/"Common 32-bit Intel processor"/g' target/i386/cpu.c
  sed -i 's/"Microsoft Hv"/"GenuineIntel"/g' target/i386/cpu.c

  quilt add target/s390x/tcg/misc_helper.c
  sed -i 's/"QEMU            "/"Intel           "/g' target/s390x/tcg/misc_helper.c
  sed -i 's/"QEMU"/"INTL"/g' target/s390x/tcg/misc_helper.c
  sed -i 's/"QEMUQEMUQEMUQEMU"/"INTELINTELINTELI"/g' target/s390x/tcg/misc_helper.c
  sed -i 's/"QEMU    "/"Intel   "/g' target/s390x/tcg/misc_helper.c
  sed -i 's/"KVM\/Linux       "/"IntelIntel      "/g' target/s390x/tcg/misc_helper.c

  quilt add target/i386/kvm/kvm.c
  sed -i 's/memcpy(signature, "Microsoft VS", 12);/memcpy(signature, "GenuineIntel", 12);/' target/i386/kvm/kvm.c
  sed -i 's/memcpy(signature, "VS#1\\0\\0\\0\\0\\0\\0\\0\\0", 12);/memcpy(signature, "GenuineIntel", 12);/' target/i386/kvm/kvm.c
  sed -i 's/memcpy(signature, "XenVMMXenVMM", 12);/memcpy(signature, "GenuineIntel", 12);/' target/i386/kvm/kvm.c
  sed -i 's/memcpy(signature, "KVMKVMKVM\\0\\0\\0", 12);/memcpy(signature, "GenuineIntel", 12);/' target/i386/kvm/kvm.c
fi

###################################################

quilt add block/vhdx.c
sed -i 's/"QEMU v" QEMU_VERSION/"Microsoft v" QEMU_VERSION/g' block/vhdx.c

quilt add block/vvfat.c
sed -i 's/"QEMU VVFAT", 10/"ASUS VVFAT", 10/g' block/vvfat.c

quilt add chardev/msmouse.c
sed -i 's/"QEMU Microsoft Mouse"/"Microsoft Mouse"/g' chardev/msmouse.c

quilt add chardev/wctablet.c
sed -i 's/"QEMU Wacom Pen Tablet"/"Wacom Pen Tablet"/g' chardev/wctablet.c

quilt add contrib/vhost-user-gpu/vhost-user-gpu.c
sed -i 's/"QEMU vhost-user-gpu"/"vhost-user-gpu"/g' contrib/vhost-user-gpu/vhost-user-gpu.c

quilt add hw/acpi/aml-build.c
sed -i 's/build_append_padded_str(array, desc->oem_id, 6, /build_append_padded_str(array, ACPI_BUILD_APPNAME6, 6, /g' hw/acpi/aml-build.c
sed -i 's/build_append_padded_str(array, desc->oem_table_id, 8, /build_append_padded_str(array, ACPI_BUILD_APPNAME8, 8, /g' hw/acpi/aml-build.c
sed -i 's/g_array_append_vals(array, ACPI_BUILD_APPNAME8, 4);/g_array_append_vals(array, "PTL ", 4);/g' hw/acpi/aml-build.c
sed -i 's/build_append_padded_str(tbl, "QEMU", 8, /build_append_padded_str(tbl, "", 8, /g' hw/acpi/aml-build.c

# grep "do this once" hw/acpi/vmgenid.c >/dev/null
# if [ $? -eq 0 ]; then
# 	echo "hw/acpi/vmgenid.c 文件只能处理一次！以前已经处理，本次不执行！"
# else
# 	sed -i 's/    Aml \*ssdt/       \/\/FUCK YOU~~~\n       return;\/\/do this once\n    Aml \*ssdt/g' hw/acpi/vmgenid.c
# 	echo "hw/acpi/vmgenid.c 文件处理完成（第一次处理，只处理一次）"
# fi

# dont need? (wasnt in qemu 9.2.0 patch)
# quilt add hw/arm/nseries.c
# sed -i 's/QEMU N800/Nokia N800/g' hw/arm/nseries.c
# sed -i 's/QEMU LCD panel/LG LCD panel/g' hw/arm/nseries.c
# sed -i 's/strcpy((void \*) w, "QEMU ")/strcpy((void \*) w, "MSI  ")/g' hw/arm/nseries.c
# sed -i 's/"1.1.10-qemu" : "1.1.6-qemu"/"1.1.10" : "1.1.6"/g' hw/arm/nseries.c

quilt add hw/arm/sbsa-ref.c
sed -i "s/QEMU 'SBSA Reference' ARM Virtual Machine/Qualcomm 'Reference' ARM SoC/g" hw/arm/sbsa-ref.c

# already added
sed -i 's/smbios_set_defaults("QEMU"/smbios_set_defaults("Unknown"/' hw/arm/virt.c

quilt add hw/char/escc.c
sed -i 's/QEMU Sun Mouse/Sun Mouse/g' hw/char/escc.c

quilt add hw/display/edid-generate.c
sed -i 's/uint32_t dpi = 100;/uint32_t dpi = 82;/g' hw/display/edid-generate.c
sed -i 's/info->vendor = "RHT"/info->vendor = "MSI"/g' hw/display/edid-generate.c
sed -i 's/QEMU Monitor/G27C4X/g' hw/display/edid-generate.c
sed -i 's/info->prefx = 1280;/info->prefx = 1280;/g' hw/display/edid-generate.c
sed -i 's/info->prefy = 800;/info->prefy = 720;/g' hw/display/edid-generate.c
sed -i 's/uint16_t model_nr = 0x1234;/uint16_t model_nr = 0x10ad;/g' hw/display/edid-generate.c
sed -i 's/edid\[16\] = 42;/edid\[16\] = 8;/g' hw/display/edid-generate.c
sed -i 's/edid\[17\] = 2014 - 1990;/edid\[17\] = 2020 - 2024;/g' hw/display/edid-generate.c

# grep "do this once" hw/i386/acpi-build.c >/dev/null
# if [ $? -eq 0 ]; then
# 	echo "hw/i386/acpi-build.c 文件只能处理一次！以前已经处理，本次不执行！"
# else
# 	sed -i '/static void build_dbg_aml(Aml \*table)/,/ /s/{/{\n     return;\/\/do this once/g' hw/i386/acpi-build.c
# 	sed -i '/create fw_cfg node/,/}/s/}/}*\//g' hw/i386/acpi-build.c
# 	sed -i '/create fw_cfg node/,/}/s/{/\/*{/g' hw/i386/acpi-build.c
# 	echo "hw/i386/acpi-build.c 文件处理完成（第一次处理，只处理一次）"
# fi

quilt add hw/i386/fw_cfg.c
sed -i 's/smbios_set_defaults("QEMU"/smbios_set_defaults("Unknown"/' hw/i386/fw_cfg.c
sed -i 's/aml_string("QEMU0002")/aml_string("UEFI0002")/' hw/i386/fw_cfg.c

# quilt add hw/i386/multiboot.c
# sed -i 's/const char \*bootloader_name = "qemu";/const char \*bootloader_name = "Windows Boot Manager";/' hw/i386/multiboot.c

quilt add hw/i386/pc.c
sed -i 's/"QEMU Virtual CPU version " v/"CPU version " v/g' hw/i386/pc.c

# is this needed?
# sed -i 's/Standard PC (i440FX + PIIX, 1996)/ASUS M4A88TD-Mi440fx/g' hw/i386/pc_piix.c

# already added
sed -i 's/m->family = "pc_q35";/m->family = "pc_x570";/' hw/i386/pc_q35.c

quilt add hw/ide/atapi.c
sed -i 's/"QEMU"/"Samsung"/g' hw/ide/atapi.c
sed -i 's/"QEMU /"/g' hw/ide/atapi.c

quilt add hw/ide/core.c
sed -i 's/"QEMU DVD-ROM"/"HL-DT-ST BD-RE WH16NS60"/g' hw/ide/core.c
sed -i 's/"QEMU MICRODRIVE"/"MicroSD J45S9"/g' hw/ide/core.c
sed -i 's/"QEMU HARDDISK"/"Samsung SSD 980 500GB"/g' hw/ide/core.c
sed -i 's/QM%05d/IH9GSSLW0FFNFYB%05d/g' hw/ide/core.c

quilt add hw/input/adb-kbd.c
sed -i 's/"QEMU /"/g' hw/input/adb-kbd.c

quilt add hw/input/adb-mouse.c
sed -i 's/"QEMU /"/g' hw/input/adb-mouse.c

# dont need?
# quilt add hw/input/ads7846.c
# sed -i 's/"QEMU /"/g' hw/input/ads7846.c

quilt add hw/input/hid.c
sed -i 's/"QEMU /"/g' hw/input/hid.c

quilt add hw/input/ps2.c
sed -i 's/"QEMU /"/g' hw/input/ps2.c

# dont need?
# quilt add hw/input/tsc2005.c
# sed -i 's/"QEMU /"/g' hw/input/tsc2005.c

# dont need?
# quilt add hw/input/tsc210x.c
# sed -i 's/"QEMU /"/g' hw/input/tsc210x.c

quilt add hw/input/virtio-input-hid.c
sed -i 's/"QEMU Virtio /"/g' hw/input/virtio-input-hid.c

# already added
sed -i 's/smbios_set_defaults("QEMU"/smbios_set_defaults("Unknown"/' hw/loongarch/virt.c

quilt add hw/misc/pvpanic-isa.c
sed -i 's/"QEMU0001"/"UEFI0001"/g' hw/misc/pvpanic-isa.c

quilt add hw/nvme/ctrl.c
sed -i 's/"QEMU /"/g' hw/nvme/ctrl.c

quilt add hw/nvram/fw_cfg-acpi.c
sed -i 's/"QEMU0002"/"UEFI0002"/' hw/nvram/fw_cfg-acpi.c

# is this needed?
# sed -i 's/0x51454d5520434647ULL/0x4155535520434647ULL/g' hw/nvram/fw_cfg.c

quilt add hw/pci-host/gpex.c
sed -i 's/"QEMU g/"G/g' hw/pci-host/gpex.c

quilt add hw/ppc/e500plat.c
sed -i 's/"QEMU /"/g' hw/ppc/e500plat.c
# is this needed?
# sed -i 's/qemu-e500/asus-e500/g' hw/ppc/e500plat.c

quilt add hw/scsi/mptconfig.c
sed -i 's/"s16s8s16s16s16"/"s10s4s85s45s34"/g' hw/scsi/mptconfig.c
sed -i 's/"QEMU MPT Fusion"/"MPT Fusion"/g' hw/scsi/mptconfig.c
sed -i 's/"QEMU"/"MSI"/g' hw/scsi/mptconfig.c
sed -i 's/"0000111122223333"/"7624862998526197"/g' hw/scsi/mptconfig.c

quilt add hw/scsi/scsi-bus.c
sed -i 's/"QEMU    "/"MSI     "/g' hw/scsi/scsi-bus.c
sed -i 's/"QEMU TARGET     "/"MSI TARGET      "/g' hw/scsi/scsi-bus.c

quilt add hw/scsi/scsi-disk.c
sed -i 's/"QEMU"/"Samsung"/g' hw/scsi/scsi-disk.c
sed -i 's/"QEMU HARDDISK"/"Samsung SSD 980 500GB"/g' hw/scsi/scsi-disk.c
sed -i 's/"QEMU CD-ROM"/"CD-ROM"/g' hw/scsi/scsi-disk.c

quilt add hw/scsi/spapr_vscsi.c
sed -i 's/"QEMU EMPTY      "/"MSI EMPTY       "/g' hw/scsi/spapr_vscsi.c
sed -i 's/"QEMU    "/"MSI     "/g' hw/scsi/spapr_vscsi.c
sed -i 's/"qemu"/"msi"/g' hw/scsi/spapr_vscsi.c

quilt add hw/ufs/lu.c
sed -i 's/"QEMU"/"MSI"/' hw/ufs/lu.c
sed -i 's/"QEMU UFS"/"UFS"/' hw/ufs/lu.c

quilt add hw/usb/canokey.c
sed -i 's/\[STR_PRODUCT\]          = "CanoKey QEMU"/\[STR_PRODUCT\]          = "CanoKey"/' hw/usb/canokey.c
sed -i 's/"0"/"JTU72VDVWE"/' hw/usb/canokey.c

quilt add hw/usb/dev-audio.c
sed -i 's/"QEMU"/"Logitech"/g' hw/usb/dev-audio.c
sed -i 's/"QEMU USB Audio"/"USB Audio"/g' hw/usb/dev-audio.c
sed -i 's/"1"/"IRNUSNFLX1"/g' hw/usb/dev-audio.c

quilt add hw/usb/dev-hid.c
sed -i 's/"QEMU"/"Logitech"/g' hw/usb/dev-hid.c
sed -i 's/"QEMU /"/g' hw/usb/dev-hid.c
sed -i 's/"89126"/"BSGMMXHEP7"/g' hw/usb/dev-hid.c
sed -i 's/"28754"/"ERYV8E95VE"/g' hw/usb/dev-hid.c
sed -i 's/"68284"/"FVVBDBHDBN"/g' hw/usb/dev-hid.c

quilt add hw/usb/dev-hub.c
sed -i 's/"QEMU"/"Logitech"/g' hw/usb/dev-hub.c
sed -i 's/"QEMU /"/g' hw/usb/dev-hub.c
sed -i 's/"314159"/"NRLQOVZPSD"/g' hw/usb/dev-hub.c

quilt add hw/usb/dev-mtp.c
sed -i 's/"QEMU"/"MSI"/g' hw/usb/dev-mtp.c
sed -i 's/"QEMU filesharing"/"filesharing"/g' hw/usb/dev-mtp.c
sed -i 's/"QEMU /"/g' hw/usb/dev-mtp.c
sed -i 's/"34617"/"LFI8O4KH2O"/g' hw/usb/dev-mtp.c

quilt add hw/usb/dev-network.c
sed -i 's/"QEMU"/"Realtek"/g' hw/usb/dev-network.c
sed -i 's/"RNDIS\/QEMU USB Network Device"/"RNDIS\/Realtek USB Network Device"/g' hw/usb/dev-network.c
sed -i 's/"400102030405"/"4C82A94C9ECA"/g' hw/usb/dev-network.c
sed -i 's/"QEMU /"/g' hw/usb/dev-network.c
sed -i 's/"1"/"2WAT53WJS2"/g' hw/usb/dev-network.c
# is this needed?
# sed -i 's/s->vendorid = 0x1234/s->vendorid = 0x8086/g' hw/usb/dev-network.c

quilt add hw/usb/dev-serial.c
sed -i 's/"QEMU"/"Microsoft"/g' hw/usb/dev-serial.c
sed -i 's/"QEMU /"/g' hw/usb/dev-serial.c
sed -i 's/"1"/"0GBVO35AQT"/g' hw/usb/dev-serial.c

quilt add hw/usb/dev-smartcard-reader.c
sed -i 's/"QEMU"/"Identiv"/g' hw/usb/dev-smartcard-reader.c
sed -i 's/"QEMU /"/g' hw/usb/dev-smartcard-reader.c
sed -i 's/\[STR_SERIALNUMBER\]  = "0V62EN322S"/\[STR_SERIALNUMBER\]  = "RKW9A9EBXN"/g' hw/usb/dev-smartcard-reader.c

quilt add hw/usb/dev-storage.c
sed -i 's/"QEMU"/"Samsung"/g' hw/usb/dev-storage.c
sed -i 's/"QEMU /"/g' hw/usb/dev-storage.c
sed -i 's/"1"/"8RIGSFEUOF"/g' hw/usb/dev-storage.c

quilt add hw/usb/dev-uas.c
sed -i 's/"QEMU"/"Microsoft"/g' hw/usb/dev-uas.c
sed -i 's/"27842"/"SWVKSP0E71"/g' hw/usb/dev-uas.c

quilt add hw/usb/dev-wacom.c
sed -i 's/"QEMU"/"Wacom"/g' hw/usb/dev-wacom.c
sed -i 's/"QEMU /"/g' hw/usb/dev-wacom.c
sed -i 's/"1"/"2UMLAOCKUI"/g' hw/usb/dev-wacom.c

quilt add hw/usb/u2f-emulated.c
sed -i 's/"QEMU /"/g' hw/usb/u2f-emulated.c

quilt add hw/usb/u2f-passthru.c
sed -i 's/"QEMU /"/g' hw/usb/u2f-passthru.c

quilt add hw/usb/u2f.c
sed -i 's/"QEMU"/"Microsoft"/g' hw/usb/u2f.c
sed -i 's/"QEMU /"/g' hw/usb/u2f.c
sed -i 's/"0"/"Y0KH87XGM3"/g' hw/usb/u2f.c

quilt add include/standard-headers/linux/qemu_fw_cfg.h
sed -i 's/"QEMU0002"/"UEFI0002"/g' include/standard-headers/linux/qemu_fw_cfg.h
# is this needed?
# sed -i 's/0x51454d5520434647ULL/0x4155535520434647ULL/g' include/standard-headers/linux/qemu_fw_cfg.h

quilt add migration/rdma.c
sed -i 's/"QEMU /"/g' migration/rdma.c

# is this needed?
# sed -i 's/0x51454d5520434647ULL/0x4155535520434647ULL/g' pc-bios/optionrom/optionrom.h

quilt add pc-bios/s390-ccw/virtio-scsi.h
sed -i 's/"QEMU CD-ROM     "/"ASUS CD-ROM     "/g' pc-bios/s390-ccw/virtio-scsi.h

quilt add qapi/ui.json
sed -i 's/"QEMU /"/g' qapi/ui.json

# we don't use seabios
# sed -i 's/"QEMU/"ASUS/g' roms/seabios/src/fw/ssdt-misc.dsl

# we don't use seabios
# sed -i 's/"QEMU/"ASUS/g' roms/seabios-hppa/src/fw/ssdt-misc.dsl

# already added
sed -i 's/"QEMU TCG CPU version "/"TCG CPU version "/g' target/i386/cpu.c

quilt add target/s390x/cpu_models.c
sed -i 's/"QEMU Virtual CPU version %s"/"CPU version %s"/g' target/s390x/cpu_models.c

# TODO check whole smbios.c
quilt add hw/smbios/smbios.c
sed -i 's/t->bios_characteristics = cpu_to_le64(0x08);/t->bios_characteristics = cpu_to_le64(0);/g' hw/smbios/smbios.c
sed -i 's/t->bios_characteristics_extension_bytes\[1\] = 0x14;/t->bios_characteristics_extension_bytes\[1\] = 0;/g' hw/smbios/smbios.c
sed -i 's/t->bios_characteristics_extension_bytes\[1\] |= 0x08;/t->bios_characteristics_extension_bytes\[1\] |= 0;/g' hw/smbios/smbios.c
# sed -i 's/t->voltage = 0;/t->voltage = 0x8B;/g' hw/smbios/smbios.c
# sed -i 's/t->external_clock = cpu_to_le16(0);/t->external_clock = cpu_to_le16(100);/g' hw/smbios/smbios.c
# sed -i 's/t->l1_cache_handle = cpu_to_le16(0xFFFF);/t->l1_cache_handle = cpu_to_le16(0x0039);/g' hw/smbios/smbios.c
# sed -i 's/t->l2_cache_handle = cpu_to_le16(0xFFFF);/t->l2_cache_handle = cpu_to_le16(0x003A);/g' hw/smbios/smbios.c
# sed -i 's/t->l3_cache_handle = cpu_to_le16(0xFFFF);/t->l3_cache_handle = cpu_to_le16(0x003B);/g' hw/smbios/smbios.c
# sed -i 's/t->processor_family = 0x01;/t->processor_family = 0xC6;/g' hw/smbios/smbios.c
# sed -i 's/t->processor_characteristics = cpu_to_le16(0x02);/t->processor_characteristics = cpu_to_le16(0x04);/g' hw/smbios/smbios.c
# sed -i 's/t->memory_type = 0x07;/t->memory_type = 0x1A;/g' hw/smbios/smbios.c
# sed -i 's/t->total_width = cpu_to_le16(0xFFFF);/t->total_width = cpu_to_le16(64);/g' hw/smbios/smbios.c
# sed -i 's/t->data_width = cpu_to_le16(0xFFFF);/t->data_width = cpu_to_le16(64);/g' hw/smbios/smbios.c
# sed -i 's/t->minimum_voltage = cpu_to_le16(0);/t->minimum_voltage = cpu_to_le16(1200);/g' hw/smbios/smbios.c
# sed -i 's/t->maximum_voltage = cpu_to_le16(0);/t->maximum_voltage = cpu_to_le16(1350);/g' hw/smbios/smbios.c
# sed -i 's/t->configured_voltage = cpu_to_le16(0);/t->configured_voltage = cpu_to_le16(1200);/g' hw/smbios/smbios.c
# sed -i 's/t->location = 0x01;/t->location = 0x03;/g' hw/smbios/smbios.c
# sed -i 's/t->error_correction = 0x06;/t->error_correction = 0x03;/g' hw/smbios/smbios.c

###################################################
# cd roms/edk2
# git checkout edk2-stable202411
# git submodule sync --recursive
# git submodule update --init --recursive

# if [[ "$CPU_VENDOR_ID" =~ .*AuthenticAMD.* ]]; then
#     # TODO: randomize Names and IDs
#     # Names
#     sed -i 's|"EDK II"|"American Megatrends"|' MdeModulePkg/MdeModulePkg.dec
#     sed -i 's|"EDK II"|"American Megatrends"|' ShellPkg/ShellPkg.dec
#     sed -i 's|"EFI Development Kit II / OVMF\\0"|"American Megatrends Inc.\\0"|' OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c
#     sed -i 's|"INTEL "|"ALASKA"|' MdeModulePkg/MdeModulePkg.dec
#     sed -i 's|"BHYVE"|"ALASKA"|' OvmfPkg/Bhyve/AcpiTables/Dsdt.asl
#     sed -i 's|"BHYVE"|"ALASKA"|' OvmfPkg/Bhyve/BhyveX64.dsc
#     sed -i "s|EFI_ACPI_OEM_ID            'B','H','Y','V','E',' '|EFI_ACPI_OEM_ID            'A','L','A','S','K','A'|" OvmfPkg/Bhyve/AcpiTables/Platform.h
#     sed -i 's|"BVDSDT"|"A M I "|' OvmfPkg/Bhyve/AcpiTables/Dsdt.asl
#     sed -i "s|SIGNATURE_64('B','V','F','A','C','P',' ',' ')|SIGNATURE_64('A',' ','M',' ','I',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Facp.aslc
#     sed -i "s|SIGNATURE_64('B','V','H','P','E','T',' ',' ')|SIGNATURE_64('A',' ','M',' ','I',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Hpet.aslc
#     sed -i "s|SIGNATURE_64('B','V','M','A','D','T',' ',' ')|SIGNATURE_64('A',' ','M',' ','I',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Madt.aslc
#     sed -i "s|SIGNATURE_64('B','V','M','C','F','G',' ',' ')|SIGNATURE_64('A',' ','M',' ','I',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Mcfg.aslc
#     sed -i "s|SIGNATURE_64('B','V','S','P','C','R',' ',' ')|SIGNATURE_64('A',' ','M',' ','I',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Spcr.aslc
#     sed -i "s|SIGNATURE_32('B','H','Y','V')|SIGNATURE_32('A','M','I',' ')|" OvmfPkg/Bhyve/AcpiTables/Platform.h

#     # IDs
#     # windows doesnt boot with these
#     # sed -i 's|INTEL_Q35_MCH_DEVICE_ID  0x29C0|INTEL_Q35_MCH_DEVICE_ID  0x1480|' OvmfPkg/Include/IndustryStandard/Q35MchIch9.h
#     sed -i 's|0x20202020324B4445|0x2049204D2041|' MdeModulePkg/MdeModulePkg.dec
#     # sed -i 's|0x1234|0x1022|' OvmfPkg/QemuVideoDxe/Driver.c
#     # sed -i 's|0x1b36|0x1022|' OvmfPkg/QemuVideoDxe/Driver.c
#     # sed -i 's|0x1af4|0x1022|' OvmfPkg/QemuVideoDxe/Driver.c
#     # TODO: Replace with correct AMD version
#     # sed -i 's|0x1050|0x1022|' OvmfPkg/QemuVideoDxe/Driver.c
#     # sed -i 's|0x15ad|0x1022|' OvmfPkg/QemuVideoDxe/Driver.c
    
#     # Miscallaneous
#     sed -i 's|"VESA"|"VUSA"|' OvmfPkg/Bhyve/BhyveRfbDxe/VbeShim.c
#     sed -i 's|"FBSD"|"UEFI"|' OvmfPkg/Bhyve/BhyveRfbDxe/VbeShim.c
#     sed -i 's|"0.0.0\\0"|"1.C0\\0"|' OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c
#     sed -i 's|"02/06/2015\\0"|"02/06/2023\\0"|' OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c
# fi

# if [[ "$CPU_VENDOR_ID" =~ .*GenuineIntel.* ]]; then
#     # TODO: randomize Names and IDs
#     # Names
#     sed -i 's|"EDK II"|"Intel Corporation"|' MdeModulePkg/MdeModulePkg.dec
#     sed -i 's|"EDK II"|"Intel Corporation"|' ShellPkg/ShellPkg.dec
#     sed -i 's|"EFI Development Kit II / OVMF\\0"|"Intel Corporation\\0"|' OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c
#     sed -i 's|"BHYVE"|"INTEL "|' OvmfPkg/Bhyve/AcpiTables/Dsdt.asl
#     sed -i 's|"BHYVE"|"INTEL "|' OvmfPkg/Bhyve/BhyveX64.dsc
#     sed -i "s|EFI_ACPI_OEM_ID            'B','H','Y','V','E',' '|EFI_ACPI_OEM_ID            'I','N','T','E','L',' '|" OvmfPkg/Bhyve/AcpiTables/Platform.h
#     sed -i "s|SIGNATURE_32('B','H','Y','V')|SIGNATURE_32('I','N','T','L')|" OvmfPkg/Bhyve/AcpiTables/Platform.h
#     sed -i 's|"BVDSDT"|"U Rvp   "|' OvmfPkg/Bhyve/AcpiTables/Dsdt.asl
#     sed -i "s|SIGNATURE_64('B','V','F','A','C','P',' ',' ')|SIGNATURE_64('U',' ','R','v','p',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Facp.aslc
#     sed -i "s|SIGNATURE_64('B','V','H','P','E','T',' ',' ')|SIGNATURE_64('U',' ','R','v','p',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Hpet.aslc
#     sed -i "s|SIGNATURE_64('B','V','M','A','D','T',' ',' ')|SIGNATURE_64('U',' ','R','v','p',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Madt.aslc
#     sed -i "s|SIGNATURE_64('B','V','M','C','F','G',' ',' ')|SIGNATURE_64('U',' ','R','v','p',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Mcfg.aslc
#     sed -i "s|SIGNATURE_64('B','V','S','P','C','R',' ',' ')|SIGNATURE_64('U',' ','R','v','p',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Spcr.aslc

#     # IDs
#     sed -i 's|0x20202020324B4445|0x2020207076525F55|' MdeModulePkg/MdeModulePkg.dec
#     # windows doesnt boot with these
#     # sed -i 's|0x1234|0x8086|' OvmfPkg/QemuVideoDxe/Driver.c
#     # sed -i 's|0x1b36|0x8086|' OvmfPkg/QemuVideoDxe/Driver.c
#     # sed -i 's|0x1af4|0x8086|' OvmfPkg/QemuVideoDxe/Driver.c
#     # sed -i 's|0x1050|0x0416|' OvmfPkg/QemuVideoDxe/Driver.c
#     # sed -i 's|0x15ad|0x8086|' OvmfPkg/QemuVideoDxe/Driver.c

#     # Miscallaneous
#     sed -i 's|"VESA"|"VUSA"|' OvmfPkg/Bhyve/BhyveRfbDxe/VbeShim.c
#     sed -i 's|"FBSD"|"UEFI"|' OvmfPkg/Bhyve/BhyveRfbDxe/VbeShim.c
#     sed -i 's|"0.0.0\\0"|"1.C0\\0"|' OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c
#     sed -i 's|"02/06/2015\\0"|"02/06/2023\\0"|' OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c
# fi

# cd ../..
###################################################

bash ../../patches/randomized-patch-pve-qemu.sh

# Finish up the patches
quilt refresh
quilt pop -a

unset QUILT_PATCHES
unset QUILT_REFRESH_ARGS
rm -rf .pc

cd ../..

# Define the patch file and header content
PATCH_FILE_PATH="$MODULE/debian/patches/$PATCH_FILE"
HEADER_CONTENT="Description: Evasion patches for $CPU_VENDOR_ID
Author: Botond Lovasz <botilovasz@gmail.com>
Date: $(date +%Y-%m-%d)
"

# Create a temporary file with the header and the original patch content
{
  echo "$HEADER_CONTENT"
  cat "$PATCH_FILE_PATH"
} > temp.patch

# Replace the original patch file with the new one
mv temp.patch "$PATCH_FILE_PATH" 
