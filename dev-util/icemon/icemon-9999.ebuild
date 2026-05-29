# Copyright 2019-2026 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit cmake git-r3

DESCRIPTION="Monitor program for use with Icecream compile clusters based on KDE Frameworks"
HOMEPAGE="https://en.opensuse.org/Icecream https://github.com/icecc/icemon"
EGIT_REPO_URI="https://github.com/icecc/${PN}.git"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS=""

RDEPEND="
	dev-qt/qtbase:6[gui,widgets]
	sys-devel/icecream
"
DEPEND="${RDEPEND}
	kde-frameworks/extra-cmake-modules"
BDEPEND="
	kde-frameworks/extra-cmake-modules
	app-text/pandoc"
