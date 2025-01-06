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
cd $MODULE/edk2
export QUILT_PATCHES=../debian/patches
export QUILT_REFRESH_ARGS="-p ab --no-timestamps --no-index" 
PATCH_PRESENT=$(quilt series | grep "-evasion.patch")
if [ -n "$PATCH_PRESENT" ]; then
    quilt delete -r $PATCH_PRESENT
fi

# Load previous patches
quilt push -a

if [ "$CPU_VENDOR_ID" == "AuthenticAMD" ]; then
    echo "AMD CPU detected, applying AMD patches"
    PATCH_FILE="amd-evasion.patch"
    quilt new $PATCH_FILE

    quilt add MdeModulePkg/MdeModulePkg.dec
    quilt add OvmfPkg/Bhyve/AcpiTables/Dsdt.asl
    quilt add OvmfPkg/Bhyve/AcpiTables/Facp.aslc
    quilt add OvmfPkg/Bhyve/AcpiTables/Hpet.aslc
    quilt add OvmfPkg/Bhyve/AcpiTables/Madt.aslc
    quilt add OvmfPkg/Bhyve/AcpiTables/Mcfg.aslc
    quilt add OvmfPkg/Bhyve/AcpiTables/Platform.h
    quilt add OvmfPkg/Bhyve/AcpiTables/Spcr.aslc
    quilt add OvmfPkg/Bhyve/BhyveRfbDxe/VbeShim.c
    quilt add OvmfPkg/Bhyve/BhyveX64.dsc
    quilt add OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c
    # quilt add OvmfPkg/Include/IndustryStandard/Q35MchIch9.h
    # quilt add OvmfPkg/QemuVideoDxe/Driver.c
    # quilt add ShellPkg/ShellPkg.dec

    # TODO: randomize Names and IDs
    # Names
    sed -i 's|"EDK II"|"American Megatrends"|' MdeModulePkg/MdeModulePkg.dec
    sed -i 's|"EDK II"|"American Megatrends"|' ShellPkg/ShellPkg.dec
    sed -i 's|"EFI Development Kit II / OVMF\\0"|"American Megatrends Inc.\\0"|' OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c
    sed -i 's|"INTEL "|"ALASKA"|' MdeModulePkg/MdeModulePkg.dec
    sed -i 's|"BHYVE"|"ALASKA"|' OvmfPkg/Bhyve/AcpiTables/Dsdt.asl
    sed -i 's|"BHYVE"|"ALASKA"|' OvmfPkg/Bhyve/BhyveX64.dsc
    sed -i "s|EFI_ACPI_OEM_ID            'B','H','Y','V','E',' '|EFI_ACPI_OEM_ID            'A','L','A','S','K','A'|" OvmfPkg/Bhyve/AcpiTables/Platform.h
    sed -i 's|"BVDSDT"|"A M I "|' OvmfPkg/Bhyve/AcpiTables/Dsdt.asl
    sed -i "s|SIGNATURE_64('B','V','F','A','C','P',' ',' ')|SIGNATURE_64('A',' ','M',' ','I',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Facp.aslc
    sed -i "s|SIGNATURE_64('B','V','H','P','E','T',' ',' ')|SIGNATURE_64('A',' ','M',' ','I',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Hpet.aslc
    sed -i "s|SIGNATURE_64('B','V','M','A','D','T',' ',' ')|SIGNATURE_64('A',' ','M',' ','I',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Madt.aslc
    sed -i "s|SIGNATURE_64('B','V','M','C','F','G',' ',' ')|SIGNATURE_64('A',' ','M',' ','I',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Mcfg.aslc
    sed -i "s|SIGNATURE_64('B','V','S','P','C','R',' ',' ')|SIGNATURE_64('A',' ','M',' ','I',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Spcr.aslc
    sed -i "s|SIGNATURE_32('B','H','Y','V')|SIGNATURE_32('A','M','I',' ')|" OvmfPkg/Bhyve/AcpiTables/Platform.h

    # IDs
    sed -i 's|INTEL_Q35_MCH_DEVICE_ID  0x29C0|INTEL_Q35_MCH_DEVICE_ID  0x1480|' OvmfPkg/Include/IndustryStandard/Q35MchIch9.h
    sed -i 's|0x20202020324B4445|0x2049204D2041|' MdeModulePkg/MdeModulePkg.dec
    sed -i 's|0x1234|0x1022|' OvmfPkg/QemuVideoDxe/Driver.c
    sed -i 's|0x1b36|0x1022|' OvmfPkg/QemuVideoDxe/Driver.c
    sed -i 's|0x1af4|0x1022|' OvmfPkg/QemuVideoDxe/Driver.c
    # TODO: Replace with correct AMD version
    sed -i 's|0x1050|0x1022|' OvmfPkg/QemuVideoDxe/Driver.c
    sed -i 's|0x15ad|0x1022|' OvmfPkg/QemuVideoDxe/Driver.c
    
    # Miscallaneous
    sed -i 's|"VESA"|"VUSA"|' OvmfPkg/Bhyve/BhyveRfbDxe/VbeShim.c
    sed -i 's|"FBSD"|"UEFI"|' OvmfPkg/Bhyve/BhyveRfbDxe/VbeShim.c
    sed -i 's|"0.0.0\\0"|"1.C0\\0"|' OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c
    sed -i 's|"02/06/2015\\0"|"02/06/2023\\0"|' OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c
fi

if [ "$CPU_VENDOR_ID" == "GenuineIntel" ]; then
    echo "Intel CPU detected, applying Intel patches"
    PATCH_FILE="intel-evasion.patch"
    quilt new $PATCH_FILE

    quilt add MdeModulePkg/MdeModulePkg.dec
    quilt add OvmfPkg/Bhyve/AcpiTables/Dsdt.asl
    quilt add OvmfPkg/Bhyve/AcpiTables/Facp.aslc
    quilt add OvmfPkg/Bhyve/AcpiTables/Hpet.aslc
    quilt add OvmfPkg/Bhyve/AcpiTables/Madt.aslc
    quilt add OvmfPkg/Bhyve/AcpiTables/Mcfg.aslc
    quilt add OvmfPkg/Bhyve/AcpiTables/Platform.h
    quilt add OvmfPkg/Bhyve/AcpiTables/Spcr.aslc
    quilt add OvmfPkg/Bhyve/BhyveRfbDxe/VbeShim.c
    quilt add OvmfPkg/Bhyve/BhyveX64.dsc
    quilt add OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c
    quilt add OvmfPkg/QemuVideoDxe/Driver.c
    quilt add ShellPkg/ShellPkg.dec

    # TODO: randomize Names and IDs
    # Names
    sed -i 's|"EDK II"|"Intel Corporation"|' MdeModulePkg/MdeModulePkg.dec
    sed -i 's|"EDK II"|"Intel Corporation"|' ShellPkg/ShellPkg.dec
    sed -i 's|"EFI Development Kit II / OVMF\\0"|"Intel Corporation\\0"|' OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c
    sed -i 's|"BHYVE"|"INTEL "|' OvmfPkg/Bhyve/AcpiTables/Dsdt.asl
    sed -i 's|"BHYVE"|"INTEL "|' OvmfPkg/Bhyve/BhyveX64.dsc
    sed -i "s|EFI_ACPI_OEM_ID            'B','H','Y','V','E',' '|EFI_ACPI_OEM_ID            'I','N','T','E','L',' '|" OvmfPkg/Bhyve/AcpiTables/Platform.h
    sed -i "s|SIGNATURE_32('B','H','Y','V')|SIGNATURE_32('I','N','T','L')|" OvmfPkg/Bhyve/AcpiTables/Platform.h
    sed -i 's|"BVDSDT"|"U Rvp   "|' OvmfPkg/Bhyve/AcpiTables/Dsdt.asl
    sed -i "s|SIGNATURE_64('B','V','F','A','C','P',' ',' ')|SIGNATURE_64('U',' ','R','v','p',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Facp.aslc
    sed -i "s|SIGNATURE_64('B','V','H','P','E','T',' ',' ')|SIGNATURE_64('U',' ','R','v','p',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Hpet.aslc
    sed -i "s|SIGNATURE_64('B','V','M','A','D','T',' ',' ')|SIGNATURE_64('U',' ','R','v','p',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Madt.aslc
    sed -i "s|SIGNATURE_64('B','V','M','C','F','G',' ',' ')|SIGNATURE_64('U',' ','R','v','p',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Mcfg.aslc
    sed -i "s|SIGNATURE_64('B','V','S','P','C','R',' ',' ')|SIGNATURE_64('U',' ','R','v','p',' ',' ',' ')|" OvmfPkg/Bhyve/AcpiTables/Spcr.aslc

    # IDs
    sed -i 's|0x20202020324B4445|0x2020207076525F55|' MdeModulePkg/MdeModulePkg.dec
    sed -i 's|0x1234|0x8086|' OvmfPkg/QemuVideoDxe/Driver.c
    sed -i 's|0x1b36|0x8086|' OvmfPkg/QemuVideoDxe/Driver.c
    sed -i 's|0x1af4|0x8086|' OvmfPkg/QemuVideoDxe/Driver.c
    sed -i 's|0x1050|0x0416|' OvmfPkg/QemuVideoDxe/Driver.c
    sed -i 's|0x15ad|0x8086|' OvmfPkg/QemuVideoDxe/Driver.c

    # Miscallaneous
    sed -i 's|"VESA"|"VUSA"|' OvmfPkg/Bhyve/BhyveRfbDxe/VbeShim.c
    sed -i 's|"FBSD"|"UEFI"|' OvmfPkg/Bhyve/BhyveRfbDxe/VbeShim.c
    sed -i 's|"0.0.0\\0"|"1.C0\\0"|' OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c
    sed -i 's|"02/06/2015\\0"|"02/06/2023\\0"|' OvmfPkg/Bhyve/SmbiosPlatformDxe/SmbiosPlatformDxe.c
fi

if [ "$CPU_VENDOR_ID" != "AuthenticAMD" ] && [ "$CPU_VENDOR_ID" != "GenuineIntel" ]; then
    echo "Unknown CPU vendor"
    exit 1
fi

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
