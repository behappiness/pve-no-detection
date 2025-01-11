# Define submodules
EDK2 = pve-edk2-firmware
KERNEL = pve-kernel
QEMU = pve-qemu

SUBMODULES = $(EDK2) $(KERNEL) $(QEMU)

# Default target
all: install-dependencies submodules patches build

# Initialize and update submodules
submodules: submodule-$(EDK2) submodule-$(KERNEL) submodule-$(QEMU)

submodule-$(EDK2):
	git submodule update --init $(EDK2)
	$(MAKE) -C $(EDK2) submodule

submodule-$(KERNEL):
	git submodule update --init $(KERNEL)
	$(MAKE) -C $(KERNEL) submodule

submodule-$(QEMU):
	git submodule update --init
	$(MAKE) -C $(QEMU) submodule
#	cd $(QEMU)/qemu/roms/edk2 && git checkout edk2-stable202411 #maybe this is not needed

# Build each submodule using its own Makefile
build: $(SUBMODULES)

$(EDK2):
	@echo "Building $(EDK2)..."
	$(MAKE) -C $(EDK2)

$(KERNEL):
	@echo "Building $(KERNEL)..."
	$(MAKE) -C $(KERNEL) build-dir-fresh
	mk-build-deps -ir $(KERNEL)/proxmox-kernel-*/debian/control
	$(MAKE) -C $(KERNEL) deb

$(QEMU):
	@echo "Building $(QEMU)..."
	$(MAKE) -C $(QEMU)

# Apply patches if needed
patches: patch-$(EDK2) patch-$(KERNEL) patch-$(QEMU)

patch-$(EDK2):
	@echo "Applying patches-$(EDK2)..."
	bash patches/patch-$(EDK2).sh $(EDK2)

patch-$(KERNEL):
	@echo "Applying patches-$(KERNEL)..."
	bash patches/patch-$(KERNEL).sh $(KERNEL)

patch-$(QEMU):
	@echo "Applying patches-$(QEMU)..."
	bash patches/patch-$(QEMU).sh $(QEMU)

# Clean
clean: clean-$(EDK2) clean-$(KERNEL) clean-$(QEMU)

clean-$(EDK2):
	@echo "Cleaning $(EDK2)..."
	$(MAKE) -C $(EDK2) clean

clean-$(KERNEL):
	@echo "Cleaning $(KERNEL)..."
	$(MAKE) -C $(KERNEL) clean

clean-$(QEMU):
	@echo "Cleaning $(QEMU)..."
	$(MAKE) -C $(QEMU) clean

install-dependencies:
	apt update
	apt install -y devscripts gcc-aarch64-linux-gnu gcc-riscv64-linux-gnu iasl mtools nasm python3-pexpect xorriso git-buildpackage
	apt install -y git devscripts quilt meson check libacl1-dev libaio-dev libattr1-dev libcap-ng-dev libcurl4-gnutls-dev libepoxy-dev libfdt-dev libgbm-dev libglusterfs-dev libgnutls28-dev libiscsi-dev libjpeg-dev libpci-dev libpixman-1-dev libproxmox-backup-qemu0-dev librbd-dev libsdl1.2-dev libseccomp-dev libslirp-dev libspice-protocol-dev libspice-server-dev libsystemd-dev liburing-dev libusb-1.0-0-dev libusbredirparser-dev libvirglrenderer-dev libzstd-dev python3-sphinx-rtd-theme python3-venv quilt uuid-dev xfslibs-dev

install: install-$(KERNEL) install-$(QEMU) install-$(EDK2)

install-$(EDK2):
	$(eval VERSION_STRING = $(shell ls $(EDK2)/ | grep -E -x -- "$(EDK2)_[0-9]+\.[0-9]+\.[0-9]+-[0-9]+_all.deb" | head -n 1 | grep -oP '(?<=edk2-firmware_)[0-9]+\.[0-9]+\.[0-9]+-[0-9]+'))
	dpkg -i $(EDK2)/$(EDK2)-ovmf_$(VERSION_STRING)_all.deb
	apt install -f -y
	apt-mark hold $(EDK2)-ovmf

install-$(KERNEL): 
	$(eval VERSION_STRING = $(shell ls $(KERNEL)/ | grep -E -x -- "proxmox-kernel-[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-pve_[0-9]+\.[0-9]+\.[0-9]+-[0-9]+_amd64.deb" | head -n 1 | grep -oP '(?<=proxmox-kernel-)[0-9]+\.[0-9]+\.[0-9]+-[0-9]+'))
	dpkg -i $(KERNEL)/proxmox-kernel-$(VERSION_STRING)-pve_$(VERSION_STRING)_amd64.deb
	apt install -f -y
	apt-mark hold proxmox-kernel-$(VERSION_STRING)-pve
	# Pin the kernel using proxmox-boot-tool (press 'y')
	proxmox-boot-tool kernel pin $(VERSION_STRING)-pve

install-$(QEMU):
	$(eval VERSION_STRING = $(shell ls $(QEMU)/ | grep -E -x -- "$(QEMU)-kvm_[0-9]+\.[0-9]+\.[0-9]+-[0-9]+_amd64.deb" | head -n 1 | grep -oP '(?<=$(QEMU)-kvm_)[0-9]+\.[0-9]+\.[0-9]+-[0-9]+'))
	dpkg -i $(QEMU)/$(QEMU)-kvm_$(VERSION_STRING)_amd64.deb
	apt install -f -y
	apt-mark hold $(QEMU)-kvm

.PHONY: all build $(SUBMODULES) install-dependencies
.PHONY: submodules submodule-$(EDK2) submodule-$(KERNEL) submodule-$(QEMU)
.PHONY: patches patch-$(EDK2) patch-$(KERNEL) patch-$(QEMU)
.PHONY: clean clean-$(EDK2) clean-$(KERNEL) clean-$(QEMU)
