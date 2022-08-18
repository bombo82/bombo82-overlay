# Copyright 2019 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License  as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit meson

DESCRIPTION="Monitor program for use with Icecream compile clusters based on KDE Frameworks"
HOMEPAGE="https://github.com/JPEWdev/icecream-sundae"
SRC_URI="https://github.com/JPEWdev/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="
	sys-libs/ncurses
	sys-devel/icecream
"
DEPEND="${RDEPEND}
	dev-util/meson
	dev-util/ninja
	sys-libs/glibc
"

PATCHES=(
	"${FILESDIR}/${P}-add-compatibility-with-icecream-v1.3.patch"
)
