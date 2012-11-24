TARGETS = boot.udev boot.sysctl boot.rootfsck boot.loadmodules boot.localnet boot.localfs boot.cleanup boot.cycle boot.klog boot.swap
INTERACTIVE = boot.rootfsck boot.localfs
boot.rootfsck: boot.udev
boot.loadmodules: boot.udev
boot.localnet: boot.rootfsck
boot.localfs: boot.loadmodules boot.rootfsck
boot.cleanup: boot.localfs
boot.cycle: boot.localfs
boot.klog: boot.localfs
boot.swap: boot.localfs
