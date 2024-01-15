# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic linux-info linux-mod udev

DESCRIPTION="VMware kernel modules"
HOMEPAGE="https://github.com/mkubecek/vmware-host-modules"

MY_KERNEL_VERSION="6.0"

# Upstream doesn't want to tag versions or anything that looks like properly
# releasing the software, so we need to just pick a commit from
# https://github.com/mkubecek/vmware-host-modules/commits/workstation-${PV}
# and test it ourselves.
#
# Details: https://github.com/mkubecek/vmware-host-modules/issues/158#issuecomment-1228341760
HOST_MODULES_COMMIT="3b4aadaeec916d2d39550808866413736bff4410"

SRC_URI=" https://github.com/mkubecek/vmware-host-modules/archive/${HOST_MODULES_COMMIT}.tar.gz -> ${P}-${HOST_MODULES_COMMIT}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="acct-group/vmware"
DEPEND=""

S="${WORKDIR}/vmware-host-modules-${HOST_MODULES_COMMIT}"
MY_S="$S"

PATCHES=(
	"${FILESDIR}/vmware-modules-16.2.5-kernel-6.4.10.patch"
	"${FILESDIR}/vmware-modules-16.2.5-kernel-6.5.patch"
)

pkg_setup() {
	CONFIG_CHECK="~HIGH_RES_TIMERS"
	if kernel_is -ge 5 5; then
		CONFIG_CHECK="${CONFIG_CHECK} X86_IOPL_IOPERM"
	fi
	if kernel_is -ge 2 6 37 && kernel_is -lt 2 6 39; then
		CONFIG_CHECK="${CONFIG_CHECK} BKL"
	fi
	CONFIG_CHECK="${CONFIG_CHECK} VMWARE_VMCI VMWARE_VMCI_VSOCKETS"

	linux-info_pkg_setup
	linux-mod_pkg_setup

	if kernel_is gt ${MY_KERNEL_VERSION//./ }; then
		ewarn
		ewarn "Warning: this version of the modules is only known to work with kernels up to ${MY_KERNEL_VERSION}, while you are building them for a ${KV_FULL} kernel."
		ewarn
	fi

	VMWARE_MODULE_LIST="vmmon vmnet"

	VMWARE_MOD_DIR="${PN}-${PVR}"

	BUILD_TARGETS="auto-build KERNEL_DIR=${KERNEL_DIR} KBUILD_OUTPUT=${KV_OUT_DIR}"

	filter-flags -mfpmath=sse -mavx -mpclmul -maes
	append-cflags -mno-sse  # Found a problem similar to bug #492964

	for mod in ${VMWARE_MODULE_LIST}; do
		MODULE_NAMES="${MODULE_NAMES} ${mod}(misc:${MY_S}/${mod}-only)"
	done
}

src_prepare() {
	# decouple the kernel include dir from the running kernel version: https://github.com/stefantalpalaru/gentoo-overlay/issues/17
	sed -i \
		-e "s%HEADER_DIR = /lib/modules/\$(VM_UNAME)/build/include%HEADER_DIR = ${KERNEL_DIR}/include%" \
		-e "s%VM_UNAME = .*\$%VM_UNAME = ${KV_FULL}%" \
		*/Makefile || die "sed failed"

	# Allow user patches so they can support RC kernels and whatever else
	default
}

src_install() {
	linux-mod_src_install
	local udevrules="${T}/60-vmware.rules"
	cat > "${udevrules}" <<-EOF
		KERNEL=="vmci",  GROUP="vmware", MODE="660"
		KERNEL=="vmw_vmci",  GROUP="vmware", MODE="660"
		KERNEL=="vmmon", GROUP="vmware", MODE="660"
		KERNEL=="vsock", GROUP="vmware", MODE="660"
	EOF
	udev_dorules "${udevrules}"

	dodir /etc/modprobe.d/

	cat > "${D}"/etc/modprobe.d/vmware.conf <<-EOF
		# Support for vmware vmci in kernel module
		alias vmci	vmw_vmci
	EOF

	export installed_modprobe_conf=1
	dodir /etc/modprobe.d/
	cat >> "${D}"/etc/modprobe.d/vmware.conf <<-EOF
		# Support for vmware vsock in kernel module
		alias vsock	vmw_vsock_vmci_transport
	EOF

	export installed_modprobe_conf=1
}

pkg_postinst() {
	linux-mod_pkg_postinst
	udev_reload
	ewarn "Don't forget to run 'rc-service vmware restart' to use the new kernel modules."
}

pkg_postrm() {
	linux-mod_pkg_postrm
	udev_reload
}
