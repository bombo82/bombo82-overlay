# Copyright 2025-2026 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

PYTHON_COMPAT=( python3_{8..14} )

inherit flag-o-matic meson python-any-r1

DESCRIPTION="C++17 D-Bus wrapper library based on glib"
HOMEPAGE="https://codeberg.org/OpenVPN/gdbuspp/"
SRC_URI="https://codeberg.org/OpenVPN/gdbuspp/archive/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="debug doc test"
RESTRICT="!test? ( test )"

DEPEND="
	dev-libs/glib:2
"
RDEPEND="
	${DEPEND}
	sys-apps/dbus
"
BDEPEND="
	virtual/pkgconfig
	doc? ( app-text/doxygen )
	test? (
		$(python_gen_any_dep '
			dev-python/dbus-python[${PYTHON_USEDEP}]
			dev-python/xmltodict[${PYTHON_USEDEP}]
		')
		sys-apps/dbus
	)
"

python_check_deps() {
	python_has_version "dev-python/dbus-python[${PYTHON_USEDEP}]" && \
	python_has_version "dev-python/xmltodict[${PYTHON_USEDEP}]"
}

pkg_setup() {
	use test && python-any-r1_pkg_setup
}

src_prepare() {
	default

	# Meson build system expects a version.txt file if not in a git repo
	echo "${PV}" > "${S}/version.txt" || die
}

src_configure() {
	local emesonargs=(
		$(meson_use doc doxygen)
		$(meson_use debug internal_debug)
		$(meson_use test long_tests)
		-Dinstall_testprogs=false
	)
	meson_src_configure
}

src_test() {
	dbus-run-session meson test -C "${BUILD_DIR}" --print-errorlogs --verbose
}

src_install() {
	meson_src_install
	# The meson build system installs documentation to /usr/share/doc/gdbuspp
	# but Gentoo policy requires /usr/share/doc/${PF}
	if [[ -d "${ED}/usr/share/doc/${PN}" ]]; then
		docinto .
		dodoc -r "${ED}/usr/share/doc/${PN}"/*
		rm -rf "${ED}/usr/share/doc/${PN}" || die
	fi
}
