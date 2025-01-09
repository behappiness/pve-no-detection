#! /bin/bash

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

KERNEL=submodules/ubuntu-kernel
PATCHES=patches/kernel

# Clean up previous patches
cd $MODULE
PATCH_PRESENT=$(ls $PATCHES | grep "-evasion.patch")
if [ -n "$PATCH_PRESENT" ]; then
    rm -rf $PATCHES/$PATCH_PRESENT
fi

PQ_BRANCH="pq"

# Load previous patches
bash ./debian/scripts/import-patchqueue $KERNEL $PATCHES $PQ_BRANCH

CPU_BASECLOCK=$(dmidecode -t processor | grep "Current Speed" | awk '{print $3}')

DIVIDER=$((CPU_BASECLOCK / 200)) # divide by 200 to get the divider?? later can be changed by sysctl
DIVIDER_SECOND=10

echo "Applying AMD patches"
############################################################
# Define the file to be modified
SVM="$KERNEL/arch/x86/kvm/svm/svm.c"
# Use sed to apply changes
# sed -i '/#include <linux\/smp.h>/a \
# #include <linux\/sysctl.h>' "$SVM"

sed -i '/MODULE_LICENSE("GPL");/a \
static u32 rdtsc_print_once = 1;\nstatic u32 rdtsc_timediffdivider = '$DIVIDER';\nstatic u32 rdtsc_timediffdividersecond = '$DIVIDER_SECOND';\nstatic bool rdtsc_secondcall = false;' "$SVM"

# sed -i '/u32 msrpm_offsets\[MSRPM_OFFSETS\] __read_mostly;/a \
# static struct ctl_table rdtsc_sysctl_table\[\] = {\n    {\n        .procname = "rdtsc_print_once",\n        .data = &rdtsc_print_once,\n        .maxlen = sizeof(rdtsc_print_once),\n        .mode = 0644,\n        .proc_handler = &proc_dointvec,\n    },\n    {\n        .procname = "rdtsc_timediffdivider",\n        .data = &rdtsc_timediffdivider,\n        .maxlen = sizeof(rdtsc_timediffdivider),\n        .mode = 0644,\n        .proc_handler = &proc_dointvec,\n    },\n    {\n        .procname = "rdtsc_timediffdividersecond",\n        .data = &rdtsc_timediffdividersecond,\n        .maxlen = sizeof(rdtsc_timediffdividersecond),\n        .mode = 0644,\n        .proc_handler = &proc_dointvec,\n    },\n    {}\n};\nstatic struct ctl_table_header \*rdtsc_sysctl_table_header;' "$SVM"

sed -i '/svm_set_intercept(svm, INTERCEPT_RSM);/a \
	svm_set_intercept(svm, INTERCEPT_RDTSC);' "$SVM"

sed -i '/static int (\*const svm_exit_handlers\[\])(struct kvm_vcpu \*vcpu)/i \
static int svm_handle_rdtsc(struct kvm_vcpu \*vcpu)\n{\n	static u64 rdtsc_fake = 0;\n	static u64 rdtsc_prev = 0;\n	u64 rdtsc_real = rdtsc();\n   u64 fake_diff;\n	if(rdtsc_print_once){\n		printk("\[handle_rdtsc\] Fake rdtsc svm function is working\\n");\n		rdtsc_print_once = 0;\n		rdtsc_fake = rdtsc_real;\n	}\n	if(rdtsc_prev != 0)\n	{\n		if(rdtsc_real > rdtsc_prev)\n		{\n			u64 diff = rdtsc_real - rdtsc_prev;\n            if(rdtsc_secondcall){\n                fake_diff =  diff \/ (rdtsc_timediffdivider\/rdtsc_timediffdividersecond);\n            }\n            else{\n                fake_diff =  diff \/ rdtsc_timediffdivider;\n            }\n			rdtsc_secondcall = !rdtsc_secondcall;\n			rdtsc_fake = fake_diff;\n		}\n	}\n	if(rdtsc_fake > rdtsc_real){\n		rdtsc_fake = rdtsc_real;\n	}\n	rdtsc_prev = rdtsc_real;\n	vcpu->arch.regs\[VCPU_REGS_RAX\] = rdtsc_fake & -1u;\n	vcpu->arch.regs\[VCPU_REGS_RDX\] = (rdtsc_fake >> 32) & -1u;\n	return svm_skip_emulated_instruction(vcpu);\n}' "$SVM"

sed -i '/\[SVM_EXIT_AVIC_UNACCELERATED_ACCESS\]	= avic_unaccelerated_access_interception,/a \
	\[SVM_EXIT_RDTSC\]			= svm_handle_rdtsc,' "$SVM"

# sed -i '/__unused_size_checks();/a \
# 	rdtsc_sysctl_table_header = register_sysctl_table(rdtsc_sysctl_table);' "$SVM"

# sed -i '/kvm_exit();/i \
# 	unregister_sysctl_table(rdtsc_sysctl_table_header);' "$SVM"
############################################################


echo "Applying Intel patches"
############################################################
VMX="$KERNEL/arch/x86/kvm/vmx/vmx.c"

# sed -i '/#include <linux\/entry-kvm.h>/a \
# #include <linux\/sysctl.h>' "$VMX"

sed -i '/MODULE_LICENSE("GPL");/a \
static u32 rdtsc_print_once = 1;\nstatic u32 rdtsc_timediffdivider = '$DIVIDER';\nstatic u32 rdtsc_timediffdividersecond = '$DIVIDER_SECOND';\nstatic bool rdtsc_secondcall = false;' "$VMX"

sed -i '/CPU_BASED_USE_IO_BITMAPS |/d' "$VMX"
sed -i '/exec_control &= ~(CPU_BASED_RDTSC_EXITING |/c \
	exec_control &= ~(CPU_BASED_USE_IO_BITMAPS |' "$VMX"

# sed -i '/bool __read_mostly enable_vpid = 1;/i \
# static struct ctl_table rdtsc_sysctl_table\[\] = {\n    {\n        .procname = "rdtsc_print_once",\n        .data = &rdtsc_print_once,\n        .maxlen = sizeof(rdtsc_print_once),\n        .mode = 0644,\n        .proc_handler = &proc_dointvec,\n    },\n    {\n        .procname = "rdtsc_timediffdivider",\n        .data = &rdtsc_timediffdivider,\n        .maxlen = sizeof(rdtsc_timediffdivider),\n        .mode = 0644,\n        .proc_handler = &proc_dointvec,\n    },\n    {\n        .procname = "rdtsc_timediffdividersecond",\n        .data = &rdtsc_timediffdividersecond,\n        .maxlen = sizeof(rdtsc_timediffdividersecond),\n        .mode = 0644,\n        .proc_handler = &proc_dointvec,\n    },\n    {}\n};\nstatic struct ctl_table_header \*rdtsc_sysctl_table_header;' "$VMX"

sed -i '/static int (\*kvm_vmx_exit_handlers\[\])(struct kvm_vcpu \*vcpu)/i \
static int vmx_handle_rdtsc(struct kvm_vcpu \*vcpu)\n{\n	static u64 rdtsc_fake = 0;\n	static u64 rdtsc_prev = 0;\n	u64 rdtsc_real = rdtsc();\n   u64 fake_diff;\n	if(rdtsc_print_once){\n		printk("\[handle_rdtsc\] Fake rdtsc vmx function is working\\n");\n		rdtsc_print_once = 0;\n		rdtsc_fake = rdtsc_real;\n	}\n	if(rdtsc_prev != 0)\n	{\n		if(rdtsc_real > rdtsc_prev)\n		{\n			u64 diff = rdtsc_real - rdtsc_prev;\n            if(rdtsc_secondcall){\n                fake_diff =  diff \/ (rdtsc_timediffdivider\/rdtsc_timediffdividersecond);\n            }\n            else{\n                fake_diff =  diff \/ rdtsc_timediffdivider;\n            }\n			rdtsc_secondcall = !rdtsc_secondcall;\n			rdtsc_fake = fake_diff;\n		}\n	}\n	if(rdtsc_fake > rdtsc_real){\n		rdtsc_fake = rdtsc_real;\n	}\n	rdtsc_prev = rdtsc_real;\n	vcpu->arch.regs\[VCPU_REGS_RAX\] = rdtsc_fake & -1u;\n	vcpu->arch.regs\[VCPU_REGS_RDX\] = (rdtsc_fake >> 32) & -1u;\n	return vmx_skip_emulated_instruction(vcpu);\n}' "$VMX"

sed -i '/\[EXIT_REASON_NOTIFY\]		      = handle_notify,/a \
	\[EXIT_REASON_RDTSC\]			= vmx_handle_rdtsc,' "$VMX"

# sed -i '/kvm_exit();/i \
# 	unregister_sysctl_table(rdtsc_sysctl_table_header);' "$VMX"

# sed -i '/int r, cpu;/a \
# 	rdtsc_sysctl_table_header = register_sysctl_table(rdtsc_sysctl_table);' "$VMX"
############################################################


echo "Applying MSR patches"
############################################################
KVM="$KERNEL/arch/x86/kvm/x86.c"

sed -i '/int kvm_emulate_rdmsr(struct kvm_vcpu \*vcpu)/i \
static u64 data_1d9=0x4000;' "$KVM"

sed -i '/r = kvm_get_msr_with_filter(vcpu, ecx, &data);/a \
	if(ecx==0x4b564d00){r=1;}\n	if(ecx==0x1db){r=1;}\n	if(ecx==0x1a2){r=0;}\n	if(ecx==0x19c){r=0;}' "$KVM"

sed -i '/trace_kvm_msr_read(ecx, data);/i \
		if(ecx==0x1d9){data=data_1d9;}' "$KVM"

sed -i '/r = kvm_set_msr_with_filter(vcpu, ecx, data);/c \
	if(ecx==0x1d9){\n		if(data==0x4000||data==0x4001||data==0x4002||data==0x4003){r=0;}\n	}else{\n		r = kvm_set_msr_with_filter(vcpu, ecx, data);\n	}' "$KVM"

sed -i '/trace_kvm_msr_write(ecx, data);/i \
		if(ecx==0x1d9){\n			if(data==0x4000||data==0x4001){data_1d9=0x4000;}\n			if(data==0x4002||data==0x4003){data_1d9=0x4002;}\n			if(data==0x0||data==0x01){data_1d9=0;}\n			if(data==0x2||data==0x03){data_1d9=2;}\n		}' "$KVM"
############################################################

cd $KERNEL
git add .
git commit -m "AMD Intel MSR evasion"
cd ../..

# Finish up the patches
bash ./debian/scripts/export-patchqueue $KERNEL $PATCHES Ubuntu-6.11.0-13.14

echo "Deleting patchqueue branch"
cd $KERNEL
git branch -D $PQ_BRANCH
cd ../..

cd ..
