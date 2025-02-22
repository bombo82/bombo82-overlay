# Copyright 2025 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8
PYTHON_COMPAT=( python3_{10..13} )

inherit git-r3 meson python-r1

DESCRIPTION="Next generation OpenVPN client"
HOMEPAGE="https://openvpn.net"
EGIT_REPO_URI="https://codeberg.org/OpenVPN/openvpn3-linux.git"

LICENSE="AGPL-3"
SLOT="0"
IUSE="addon-aws addon-deviceposture bash-completion dco doc selinux systemd"

DEPEND="${PYTHON_DEPS}
	acct-group/openvpn
	acct-user/openvpn
	app-arch/lz4
	dev-libs/gdbuspp
	dev-libs/glib
	dev-libs/jsoncpp
	dev-libs/tinyxml2
	sys-libs/libcap-ng
	dco? (
		dev-libs/libnl
		dev-libs/protobuf
		net-vpn/ovpn-dco
	)
	selinux? (
		sys-libs/libselinux
	)
	systemd? (
		sys-auth/polkit
	)
"
RDEPEND="
	${DEPEND}
	$(python_gen_cond_dep 'dev-python/pyopenssl[${PYTHON_USEDEP}]')
	$(python_gen_cond_dep 'dev-python/pygobject[${PYTHON_USEDEP}]')
	$(python_gen_cond_dep 'dev-python/dbus-python[${PYTHON_USEDEP}]')
"
BDEPEND="
	${PYTHON_DEPS}
	dev-build/meson
	dev-python/meson-python
"

src_configure() {
	local emesonargs=(
                $(meson_feature addon-aws)
                $(meson_feature addon-deviceposture)
                $(meson_feature bash-completion)
                $(meson_feature dco)
                $(meson_feature doc doxygen)
                $(meson_feature selinux)
        )
	meson_src_configure --wrap-mode nopromote -Dunit_tests=disabled -Dtest_programs=disabled
}

pkg_postinst(){
	elog "Run the following command when openvpn3 is installed for the first time:"
	elog "openvpn3-admin init-config --write-configs"
}
