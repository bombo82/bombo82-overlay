# Copyright 2025 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit meson

DESCRIPTION="This library provides a simpler C++ based interface to implement D-Bus into applications in a more C++ approach, based on the C++17 standard."
HOMEPAGE="https://codeberg.org/OpenVPN/gdbuspp/"
SRC_URI="https://codeberg.org/OpenVPN/gdbuspp/archive/v${PV}.tar.gz"
S="${WORKDIR}/${PN}"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="
	dev-libs/glib
"
RDEPEND="${DEPEND}
	sys-apps/dbus
"
BDEPEND="
	dev-build/meson
"
