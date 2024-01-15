# Copyright 2019 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License  as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit cmake

DESCRIPTION="Monitor program for use with Icecream compile clusters based on KDE Frameworks"
HOMEPAGE="https://en.opensuse.org/Icecream https://github.com/icecc/icemon"
SRC_URI="https://github.com/icecc/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	dev-qt/qtcore:5
	dev-qt/qtgui:5
	dev-qt/qtwidgets:5
	sys-devel/icecream
"
DEPEND="${RDEPEND}
	app-text/docbook2X
"

src_configure() {
	local mycmakeargs=(
		-DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=OFF
	)
	cmake_src_configure
}
