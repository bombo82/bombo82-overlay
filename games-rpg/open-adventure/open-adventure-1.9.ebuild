# Copyright 2019 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License  as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=7

inherit autotools eutils

DESCRIPTION="Forward-port of the Crowther/Woods Adventure 2.5 from 1995"
HOMEPAGE="http://www.catb.org/~esr/open-adventure/"
SRC_URI="https://gitlab.com/esr/${PN}/-/archive/${PV}/${P}.tar.gz"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="
	dev-python/pyyaml
	dev-libs/libedit
"
DEPEND="${RDEPEND}"

src_install() {
	local dir="/opt/${P}"

	insinto "${dir}"
	doins advent
	fperms 755 "${dir}/advent"

	make_wrapper "${PN}" "${dir}/advent"
}
