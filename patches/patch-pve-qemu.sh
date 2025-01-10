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

# cd roms/edk2
# git checkout edk2-stable202411
# cd ../..

export QUILT_PATCHES=../debian/patches
export QUILT_REFRESH_ARGS="-p ab --no-timestamps --no-index" 
PATCH_PRESENT=$(quilt series | grep "-evasion.patch")
if [ -n "$PATCH_PRESENT" ]; then
    quilt delete -r $PATCH_PRESENT
fi

# Load previous patches
quilt push -a

if [[ "$CPU_VENDOR_ID" =~ .*AuthenticAMD.* ]]; then
    echo "AMD CPU detected, applying AMD patches"
    PATCH_FILE="amd-evasion.patch"
    quilt new $PATCH_FILE

fi

if [[ "$CPU_VENDOR_ID" =~ .*GenuineIntel.* ]]; then
    echo "Intel CPU detected, applying Intel patches"
    PATCH_FILE="intel-evasion.patch"
    quilt new $PATCH_FILE

fi

if [[ ! "$CPU_VENDOR_ID" =~ .*AuthenticAMD.* ]] && [[ ! "$CPU_VENDOR_ID" =~ .*GenuineIntel.* ]]; then
    echo "Unknown CPU vendor"
    exit 1
fi

###################################################

sed -i 's/"QEMU v" QEMU_VERSION/"Microsoft v" QEMU_VERSION/g' block/vhdx.c

sed -i 's/"QEMU VVFAT", 10/"ASUS VVFAT", 10/g' block/vvfat.c

sed -i 's/"QEMU Microsoft Mouse"/"Logitech Mouse"/g' chardev/msmouse.c

sed -i 's/"QEMU Wacom Pen Tablet"/"Huion Pen Tablet"/g' chardev/wctablet.c

sed -i 's/"QEMU vhost-user-gpu"/"NVIDIA vhost-user-gpu"/g' contrib/vhost-user-gpu/vhost-user-gpu.c

sed -i 's/desc->oem_id/ACPI_BUILD_APPNAME6/g' hw/acpi/aml-build.c
sed -i 's/desc->oem_table_id/ACPI_BUILD_APPNAME8/g' hw/acpi/aml-build.c
sed -i 's/array, ACPI_BUILD_APPNAME8/array, "PTL "/g' hw/acpi/aml-build.c
sed -i 's/tbl, "QEMU", 8, /tbl, "", 8, /g' hw/acpi/aml-build.c

# TODO
grep "do this once" hw/acpi/vmgenid.c >/dev/null
if [ $? -eq 0 ]; then
	echo "hw/acpi/vmgenid.c 文件只能处理一次！以前已经处理，本次不执行！"
else
	sed -i 's/    Aml \*ssdt/       \/\/FUCK YOU~~~\n       return;\/\/do this once\n    Aml \*ssdt/g' hw/acpi/vmgenid.c
	echo "hw/acpi/vmgenid.c 文件处理完成（第一次处理，只处理一次）"
fi

sed -i 's/QEMU N800/Nokia N800/g' hw/arm/nseries.c
sed -i 's/QEMU LCD panel/LG LCD panel/g' hw/arm/nseries.c
sed -i 's/strcpy((void \*) w, "QEMU ")/strcpy((void \*) w, "MSI  ")/g' hw/arm/nseries.c
sed -i 's/"1.1.10-qemu" : "1.1.6-qemu"/"1.1.10" : "1.1.6"/g' hw/arm/nseries.c

sed -i "s/QEMU 'SBSA Reference' ARM Virtual Machine/Qualcomm 'Reference' ARM SoC/g" hw/arm/sbsa-ref.c

sed -i 's/QEMU " MACHINE_VER_STR(__VA_ARGS__) " ARM Virtual Machine"/AMD  " MACHINE_VER_STR(__VA_ARGS__) " ARM Machine"/' hw/arm/virt.c
sed -i 's/QEMU Virtual Machine/AMD Machine/' hw/arm/virt.c
sed -i 's/KVM Virtual Machine/AMD Machine/' hw/arm/virt.c
sed -i 's/smbios_set_defaults("QEMU"/smbios_set_defaults("Unknown"/' hw/arm/virt.c

sed -i 's/QEMU Sun Mouse/Sun Mouse/g' hw/char/escc.c

sed -i 's/uint32_t dpi = 100;/uint32_t dpi = 82;/g' hw/display/edid-generate.c
sed -i 's/info->vendor = "RHT"/info->vendor = "MSI"/g' hw/display/edid-generate.c
sed -i 's/QEMU Monitor/G27C4X/g' hw/display/edid-generate.c
sed -i 's/info->prefx = 1280;/info->prefx = 1920;/g' hw/display/edid-generate.c
sed -i 's/info->prefy = 800;/info->prefy = 1080;/g' hw/display/edid-generate.c
sed -i 's/uint16_t model_nr = 0x1234;/uint16_t model_nr = 0x10ad;/g' hw/display/edid-generate.c
sed -i 's/edid\[16\] = 42;/edid\[16\] = 8;/g' hw/display/edid-generate.c
sed -i 's/edid\[17\] = 2014 - 1990;/edid\[17\] = 2020 - 2024;/g' hw/display/edid-generate.c

# TODO check if this is correct
grep "do this once" hw/i386/acpi-build.c >/dev/null
if [ $? -eq 0 ]; then
	echo "hw/i386/acpi-build.c 文件只能处理一次！以前已经处理，本次不执行！"
else
	sed -i '/static void build_dbg_aml(Aml \*table)/,/ /s/{/{\n     return;\/\/do this once/g' hw/i386/acpi-build.c
	sed -i '/create fw_cfg node/,/}/s/}/}*\//g' hw/i386/acpi-build.c
	sed -i '/create fw_cfg node/,/}/s/{/\/*{/g' hw/i386/acpi-build.c
	echo "hw/i386/acpi-build.c 文件处理完成（第一次处理，只处理一次）"
fi

sed -i 's/smbios_set_defaults("QEMU"/smbios_set_defaults("Unknown"/' hw/i386/fw_cfg.c
sed -i 's/aml_string("QEMU0002")/aml_string("PNP0A03")/' hw/i386/fw_cfg.c

sed -i 's/const char \*bootloader_name = "qemu";/const char \*bootloader_name = "Windows Boot Manager";/' hw/i386/multiboot.c

sed -i 's/"QEMU Virtual CPU version " v/"CPU version " v/g' hw/i386/pc.c

# TODO check if this is correct
sed -i 's/"QEMU/"ASUS/g' hw/i386/pc_piix.c
sed -i 's/Standard PC (i440FX + PIIX, 1996)/ASUS M4A88TD-Mi440fx/g' hw/i386/pc_piix.c

sed -i 's/m->family = "pc_q35";/m->family = "pc_x570";/' hw/i386/pc_q35.c
sed -i 's/m->desc = "Standard PC (Q35 + ICH9, 2009)";/m->desc = "AMD Ryzen 7 7700X 8-Core Processor";/' hw/i386/pc_q35.c

sed -i 's/"QEMU/"Samsung/g' hw/ide/atapi.c

sed -i 's/"QEMU DVD-ROM"/"HL-DT-ST BD-RE WH16NS60"/g' hw/ide/core.c
sed -i 's/"QEMU MICRODRIVE"/"MicroSD J45S9"/g' hw/ide/core.c
sed -i 's/"QEMU HARDDISK"/"Samsung SSD 980 500GB"/g' hw/ide/core.c
sed -i 's/QM%05d/IH9GSSLW0FFNFYB%05d/g' hw/ide/core.c

sed -i 's/"QEMU /"/g' hw/input/adb-kbd.c

sed -i 's/"QEMU /"/g' hw/input/adb-mouse.c

sed -i 's/"QEMU /"/g' hw/input/ads7846.c

sed -i 's/"QEMU/"Logitech/g' hw/input/hid.c

sed -i 's/"QEMU /"/g' hw/input/ps2.c

sed -i 's/"QEMU /"/g' hw/input/tsc2005.c

sed -i 's/"QEMU /"/g' hw/input/tsc210x.c

sed -i 's/"QEMU Virtio /"/g' hw/input/virtio-input-hid.c

sed -i 's/"QEMU Virtual Machine"/"AMD Machine"/' hw/loongarch/virt.c
sed -i 's/smbios_set_defaults("QEMU"/smbios_set_defaults("Unknown"/' hw/loongarch/virt.c

sed -i 's/"QEMU M68K Virtual Machine"/"AMD M68K Machine"/' hw/m68k/virt.c
sed -i 's/"QEMU " MACHINE_VER_STR(__VA_ARGS__) " M68K Virtual Machine"/"AMD  " MACHINE_VER_STR(__VA_ARGS__) " M68K Machine"/' hw/m68k/virt.c

sed -i 's/"QEMU/"MSI/g' hw/misc/pvpanic-isa.c

sed -i 's/"QEMU /"/g' hw/nvme/ctrl.c

sed -i 's/"QEMU0002"/"PNP0A03"/' hw/nvram/fw_cfg-acpi.c

# TODO check if this is correct
sed -i 's/0x51454d5520434647ULL/0x4155535520434647ULL/g' hw/nvram/fw_cfg.c

sed -i 's/"QEMU/"MSI/g' hw/pci-host/gpex.c

sed -i 's/"QEMU /"/g' hw/ppc/e500plat.c
# TODO check if this is correct
sed -i 's/qemu-e500/asus-e500/g' hw/ppc/e500plat.c

sed -i 's/const char \*devtype = "qemu";/const char \*devtype = "amd";/' hw/ppc/spapr_pci.c

sed -i 's/"s16s8s16s16s16"/"s10s4s85s45s34"/g' hw/scsi/mptconfig.c
sed -i 's/"QEMU MPT Fusion"/"MPT Fusion"/g' hw/scsi/mptconfig.c
sed -i 's/"QEMU"/"MSI"/g' hw/scsi/mptconfig.c
sed -i 's/"0000111122223333"/"7624862998526197"/g' hw/scsi/mptconfig.c

sed -i 's/"QEMU/"MSI /g' hw/scsi/scsi-bus.c

sed -i 's/"QEMU"/"Samsung"/g' hw/scsi/scsi-disk.c
sed -i 's/"QEMU HARDDISK"/"Samsung SSD 980 500GB"/g' hw/scsi/scsi-disk.c
sed -i 's/"QEMU CD-ROM"/"CD-ROM"/g' hw/scsi/scsi-disk.c

sed -i 's/"QEMU EMPTY      "/"EMPTY           "/' hw/scsi/spapr_vscsi.c
sed -i 's/"QEMU    "/"MSI     "/' hw/scsi/spapr_vscsi.c
sed -i 's/"qemu"/"msi"/' hw/scsi/spapr_vscsi.c

sed -i 's/"QEMU"/"MSI"/' hw/ufs/lu.c
sed -i 's/"QEMU UFS"/"UFS"/' hw/ufs/lu.c

sed -i 's/"CanoKey QEMU"/"CanoKey"/' hw/usb/canokey.c
sed -i 's/"0"/"66NN1YJNEP"/' hw/usb/canokey.c

sed -i 's/"QEMU"/"MSI"/g' hw/usb/dev-audio.c
sed -i 's/"QEMU USB Audio"/"USB Audio"/g' hw/usb/dev-audio.c

sed -i 's/"QEMU"/"MSI"/g' hw/usb/dev-hid.c
sed -i 's/"QEMU /"/g' hw/usb/dev-hid.c

sed -i 's/"QEMU"/"MSI"/g' hw/usb/dev-hub.c
sed -i 's/"QEMU /"/g' hw/usb/dev-hub.c
sed -i 's/"314159"/"6DO21HOG1M"/g' hw/usb/dev-hub.c

sed -i 's/"QEMU"/"MSI"/g' hw/usb/dev-mtp.c
sed -i 's/"QEMU filesharing"/"MSI filesharing"/g' hw/usb/dev-mtp.c
sed -i 's/"QEMU /"/g' hw/usb/dev-mtp.c
sed -i 's/"34617"/"LG0ROL1GTL"/g' hw/usb/dev-mtp.c

sed -i 's/"QEMU"/"MSI"/g' hw/usb/dev-network.c
sed -i 's/"RNDIS/QEMU USB Network Device"/"RNDIS USB Network Device"/g' hw/usb/dev-network.c
sed -i 's/"400102030405"/"4C82A94C9ECA"/g' hw/usb/dev-network.c
sed -i 's/"QEMU /"/g' hw/usb/dev-network.c
sed -i 's/"1"/"AG1ROQ5GZL"/g' hw/usb/dev-network.c
# TODO check if this is correct
sed -i 's/s->vendorid = 0x1234/s->vendorid = 0x8086/g' hw/usb/dev-network.c

sed -i 's/"QEMU"/"MSI"/g' hw/usb/dev-serial.c
sed -i 's/"QEMU /"/g' hw/usb/dev-serial.c
sed -i 's/"1"/"Y9KK9WJ0E3"/g' hw/usb/dev-serial.c

sed -i 's/"QEMU"/"MSI"/g' hw/usb/dev-smartcard-reader.c
sed -i 's/"QEMU /"/g' hw/usb/dev-smartcard-reader.c
sed -i 's/"1"/"0V62EN322S"/g' hw/usb/dev-smartcard-reader.c

sed -i 's/"QEMU"/"MSI"/g' hw/usb/dev-storage.c
sed -i 's/"QEMU /"/g' hw/usb/dev-storage.c
sed -i 's/"1"/"QAKUPP59K4"/g' hw/usb/dev-storage.c

sed -i 's/"QEMU"/"MSI"/g' hw/usb/dev-uas.c
sed -i 's/"27842"/"FS6U3J80QZ"/g' hw/usb/dev-uas.c

sed -i 's/"QEMU"/"MSI"/g' hw/usb/dev-wacom.c
sed -i 's/"QEMU /"/g' hw/usb/dev-wacom.c
sed -i 's/"1"/"7LO2AY0YZX"/g' hw/usb/dev-wacom.c

sed -i 's/"QEMU /"/g' hw/usb/u2f-emulated.c

sed -i 's/"QEMU /"/g' hw/usb/u2f-passthru.c

sed -i 's/"QEMU"/"MSI"/g' hw/usb/u2f.c
sed -i 's/"QEMU /"/g' hw/usb/u2f.c
sed -i 's/"0"/"J43A2YN8GO"/g' hw/usb/u2f.c

sed -i 's/"BOCHS "/"ALASKA"/g' include/hw/acpi/aml-build.h
sed -i 's/"BXPC    "/"A M I "/g' include/hw/acpi/aml-build.h

sed -i 's/"QEMU0002"/"PNP0A03"/g' include/standard-headers/linux/qemu_fw_cfg.h
# TODO check if this is correct
sed -i 's/0x51454d5520434647ULL/0x4155535520434647ULL/g' include/standard-headers/linux/qemu_fw_cfg.h

# TODO check if this is correct
sed -i 's/"QEMU/"ASUS/g' migration/migration.c

sed -i 's/"QEMU /"/g' migration/rdma.c

# TODO check if this is correct
sed -i 's/0x51454d5520434647ULL/0x4155535520434647ULL/g' pc-bios/optionrom/optionrom.h

sed -i 's/"QEMU CD-ROM     "/"MSI CD-ROM      "/g' pc-bios/s390-ccw/virtio-scsi.h

sed -i 's/"QEMU /"/g' qapi/ui.json

# TODO check if this is correct
sed -i 's/"QEMU/"ASUS/g' roms/seabios/src/fw/ssdt-misc.dsl

# TODO check if this is correct
sed -i 's/"QEMU/"ASUS/g' roms/seabios-hppa/src/fw/ssdt-misc.dsl

sed -i 's/"QEMU Virtual CPU version "/"AMD CPU version "/g' target/i386/cpu.c
sed -i 's/"Common KVM processor"/"Common AMD processor"/g' target/i386/cpu.c
sed -i 's/"QEMU TCG CPU version "/"TCG CPU version "/g' target/i386/cpu.c
sed -i 's/"TCGTCGTCGTCG"/0/g' target/i386/cpu.c
sed -i 's/"Microsoft Hv"/""/g' target/i386/cpu.c

sed -i 's/"Microsoft VS"/0/g' target/i386/kvm/kvm.c
sed -i 's/"VS#1\\0\\0\\0\\0\\0\\0\\0\\0"/0/g' target/i386/kvm/kvm.c
sed -i 's/"XenVMMXenVMM"/0/g' target/i386/kvm/kvm.c
sed -i 's/"KVMKVMKVM\\0\\0\\0"/0/g' target/i386/kvm/kvm.c

# TODO check for escape characters
sed -i 's/"QEMU Virtual CPU version %s"/"CPU version %s"/g' target/s390x/cpu_models.c

# For target/s390x/tcg/misc_helper.c
sed -i 's/"QEMU            "/"MSI             "/g' target/s390x/tcg/misc_helper.c
sed -i 's/"QEMU"/"MSI "/g' target/s390x/tcg/misc_helper.c
sed -i 's/"QEMUQEMUQEMUQEMU"/"MSIMSIMSIMSIMSIM"/g' target/s390x/tcg/misc_helper.c
sed -i 's/"QEMU    "/"MSI     "/g' target/s390x/tcg/misc_helper.c
sed -i 's/"KVM\/Linux       "/"MSI             "/g' target/s390x/tcg/misc_helper.c

# TODO check whole smbios.c
sed -i 's/t->bios_characteristics_extension_bytes\[1\] = 0x14;/t->bios_characteristics_extension_bytes\[1\] = 0x0F;/g' hw/smbios/smbios.c
sed -i 's/t->voltage = 0;/t->voltage = 0x8B;/g' hw/smbios/smbios.c
sed -i 's/t->external_clock = cpu_to_le16(0);/t->external_clock = cpu_to_le16(100);/g' hw/smbios/smbios.c
sed -i 's/t->l1_cache_handle = cpu_to_le16(0xFFFF);/t->l1_cache_handle = cpu_to_le16(0x0039);/g' hw/smbios/smbios.c
sed -i 's/t->l2_cache_handle = cpu_to_le16(0xFFFF);/t->l2_cache_handle = cpu_to_le16(0x003A);/g' hw/smbios/smbios.c
sed -i 's/t->l3_cache_handle = cpu_to_le16(0xFFFF);/t->l3_cache_handle = cpu_to_le16(0x003B);/g' hw/smbios/smbios.c
sed -i 's/t->processor_family = 0x01;/t->processor_family = 0xC6;/g' hw/smbios/smbios.c
sed -i 's/t->processor_characteristics = cpu_to_le16(0x02);/t->processor_characteristics = cpu_to_le16(0x04);/g' hw/smbios/smbios.c
sed -i 's/t->memory_type = 0x07;/t->memory_type = 0x1A;/g' hw/smbios/smbios.c
sed -i 's/t->total_width = cpu_to_le16(0xFFFF);/t->total_width = cpu_to_le16(64);/g' hw/smbios/smbios.c
sed -i 's/t->data_width = cpu_to_le16(0xFFFF);/t->data_width = cpu_to_le16(64);/g' hw/smbios/smbios.c
sed -i 's/t->minimum_voltage = cpu_to_le16(0);/t->minimum_voltage = cpu_to_le16(1200);/g' hw/smbios/smbios.c
sed -i 's/t->maximum_voltage = cpu_to_le16(0);/t->maximum_voltage = cpu_to_le16(1350);/g' hw/smbios/smbios.c
sed -i 's/t->configured_voltage = cpu_to_le16(0);/t->configured_voltage = cpu_to_le16(1200);/g' hw/smbios/smbios.c
sed -i 's/t->location = 0x01;/t->location = 0x03;/g' hw/smbios/smbios.c
sed -i 's/t->error_correction = 0x06;/t->error_correction = 0x03;/g' hw/smbios/smbios.c

###################################################

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
