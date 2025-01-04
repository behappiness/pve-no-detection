# Define submodules
EDK2 = pve-edk2-firmware
KERNEL = pve-kernel
QEMU = pve-qemu

SUBMODULES = $(EDK2) $(KERNEL) $(QEMU)

# Default target
all: install-dependencies update-submodules apply-patches build

# Initialize and update submodules
update-submodules: submodule-$(EDK2) submodule-$(KERNEL) submodule-$(QEMU)

submodule-$(EDK2):
	$(MAKE) -C $(EDK2) submodule || { sed -i 's|https://github.com/Zeex/subhook.git|https://github.com/tianocore/edk2-subhook.git|' $(EDK2)/edk2/.gitmodules }
	git submodule sync --recursive $(EDK2)
	$(MAKE) -C $(EDK2) submodule

submodule-$(KERNEL):
	$(MAKE) -C $(KERNEL) build-dir-fresh
	PVE_KERNEL_DIR = $(shell find $(KERNEL) -type d -name '$(KERNEL)*')
	mk-build-deps -ir $(KERNEL)/$(PVE_KERNEL_DIR)/debian/control

submodule-$(QEMU):
	$(MAKE) -C $(QEMU) submodule || { sed -i 's|https://github.com/Zeex/subhook.git|https://github.com/tianocore/edk2-subhook.git|' $(QEMU)/qemu/roms/edk2/.gitmodules }
	git submodule sync --recursive $(QEMU)
	$(MAKE) -C $(QEMU) submodule

# Build each submodule using its own Makefile
build: $(SUBMODULES)

$(EDK2):
	@echo "Building $(EDK2)..."
	$(MAKE) -C $(EDK2)

$(KERNEL):
	@echo "Building $(KERNEL)..."
	$(MAKE) -C $(KERNEL) deb

$(QEMU):
	@echo "Building $(QEMU)..."
	$(MAKE) -C $(QEMU)

# Apply patches if needed
apply-patches: apply-patch-$(EDK2) apply-patch-$(KERNEL) apply-patch-$(QEMU)

apply-patch-$(EDK2):
	@echo "Applying patches-$(EDK2)..."
	bash patches/patch-$(EDK2).sh

apply-patch-$(KERNEL):
	@echo "Applying patches-$(KERNEL)..."
	bash patches/patch-$(KERNEL).sh

apply-patch-$(QEMU):
	@echo "Applying patches-$(QEMU)..."
	bash patches/patch-$(QEMU).sh

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
	apt install -y devscripts gcc-aarch64-linux-gnu gcc-riscv64-linux-gnu iasl mtools nasm python3-pexpect xorriso


.PHONY: all build $(SUBMODULES) install-dependencies
.PHONY: update-submodules submodule-$(EDK2) submodule-$(KERNEL) submodule-$(QEMU)
.PHONY: apply-patches apply-patch-$(EDK2) apply-patch-$(KERNEL) apply-patch-$(QEMU)
.PHONY: clean clean-$(EDK2) clean-$(KERNEL) clean-$(QEMU)
