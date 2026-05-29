# Copyright 2025-2026 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8
PYTHON_COMPAT=( python3_{8..14} )
OPENVPN3_CORE_TAG="release/3.11.6"
ASIO_TAG="asio-1-36-0"

inherit meson python-single-r1

DESCRIPTION="Next generation OpenVPN client"
HOMEPAGE="https://openvpn.net"
SRC_URI="
	https://github.com/OpenVPN/openvpn3-linux/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/OpenVPN/openvpn3/archive/refs/tags/${OPENVPN3_CORE_TAG}.tar.gz -> openvpn3-core-${OPENVPN3_CORE_TAG//\//-}.tar.gz
	https://github.com/chriskohlhoff/asio/archive/refs/tags/${ASIO_TAG}.tar.gz -> asio-${ASIO_TAG}.tar.gz
"

LICENSE="AGPL-3+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="addon-aws addon-deviceposture bash-completion dco doc selinux systemd test"
RESTRICT="!test? ( test )"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

PATCHES=(
	"${FILESDIR}/${P}-use-system-fmt.patch"
	"${FILESDIR}/${P}-use-system-gtest.patch"
	"${FILESDIR}/${P}-optional-systemd.patch"
	"${FILESDIR}/${P}-fix-dco-disabled-build.patch"
)

DEPEND="
	${PYTHON_DEPS}
	acct-group/openvpn
	acct-user/openvpn
	app-arch/lz4
	dev-libs/libfmt
	dev-libs/gdbuspp
	dev-libs/glib:2
	dev-libs/jsoncpp:=
	dev-libs/libnl:3
	dev-libs/tinyxml2:=
	sys-apps/util-linux
	sys-libs/libcap-ng
	dco? (
		dev-libs/protobuf:=
		net-vpn/ovpn-dco
	)
	selinux? (
		sys-libs/libselinux
	)
	systemd? (
		sys-apps/systemd:=
		sys-auth/polkit
	)
	test? (
		dev-cpp/gtest
		sys-apps/dbus
	)
"
RDEPEND="
	${DEPEND}
	$(python_gen_cond_dep '
		dev-python/pyopenssl[${PYTHON_USEDEP}]
		dev-python/pygobject[${PYTHON_USEDEP}]
		dev-python/dbus-python[${PYTHON_USEDEP}]
	')
"
BDEPEND="
	dev-build/meson
	virtual/pkgconfig
	bash-completion? ( $(python_gen_cond_dep 'dev-python/docutils[${PYTHON_USEDEP}]') )
	doc? ( app-text/doxygen )
"
S="${WORKDIR}/openvpn3-linux-${PV}"

src_unpack() {
	unpack ${A}

	[[ -d ${S} ]] || mv openvpn3-linux-* "${S}" || die

	rm -rf "${S}/openvpn3-core" || die
	mv "openvpn3-${OPENVPN3_CORE_TAG//\//-}" "${S}/openvpn3-core" || die

	rm -rf "${S}/vendor/asio" || die
	mkdir -p "${S}/vendor/asio" || die
	mv "asio-${ASIO_TAG}/asio" "${S}/vendor/asio/asio" || die
}

pkg_setup() {
	python-single-r1_pkg_setup
}

src_prepare() {
	default

	cat > src/build-version.h <<-EOF || die
		#pragma once

		#define OPENVPN_VERSION "${OPENVPN3_CORE_TAG#release/}"
		#define PACKAGE_GUIVERSION "v${PV}"
		#define PACKAGE_NAME "OpenVPN3/Linux"
	EOF
}

src_configure() {
	local emesonargs=(
		$(meson_feature addon-aws)
		$(meson_feature addon-deviceposture)
		$(meson_feature bash-completion)
		$(meson_feature dco)
		$(meson_feature doc doxygen)
		$(meson_feature selinux)
		-Ddocdir="${EPREFIX}/usr/share/doc/${PF}"
		-Dselinux_policy=disabled
		-Dopenvpn3_core_version="${OPENVPN3_CORE_TAG#release/}"
		$(meson_feature test unit_tests)
		$(meson_feature test test_programs)
	)
	meson_src_configure
}

src_install() {
	meson_src_install
	python_fix_shebang "${D}/usr/bin" "${D}/usr/sbin"
	python_optimize

	keepdir /var/lib/openvpn3/configs
}

src_test() {
	dbus-run-session meson test -C "${BUILD_DIR}" --print-errorlogs
}

pkg_postinst() {
	elog "Run the following command when openvpn3 is installed for the first time:"
	elog "openvpn3-admin init-config --write-configs"
}
