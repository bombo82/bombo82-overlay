# Copyright 2019 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License  as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=7

inherit autotools user

DESCRIPTION="Distributed compiling of C(++) code across several machines; based on distcc"
HOMEPAGE="https://github.com/icecc/icecream"
SRC_URI="https://github.com/icecc/${PN}/archive/${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~hppa ~ppc ~x86"
IUSE=""

DEPEND="
	sys-libs/libcap-ng
	app-text/docbook2X
"
RDEPEND="
	${DEPEND}
	dev-util/shadowman
"

AT_NOELIBTOOLIZE="yes"

pkg_setup() {
	enewgroup icecream
	enewuser icecream -1 -1 /var/cache/icecream icecream
}

src_prepare() {
	default
	eautoreconf
}

src_install() {
	default
	find "${D}" -name '*.la' -delete || die

	insinto /etc/logrotate.d
	newinitd "${FILESDIR}"/icecream icecream

	insinto /usr/share/shadowman/tools
	newins - icecc <<<'/usr/libexec/icecc/bin'
}

pkg_prerm() {
	if [[ -z ${REPLACED_BY_VERSION} && ${ROOT} == / ]]; then
		eselect compiler-shadow remove icecc
	fi
}

pkg_postinst() {
	if [[ ${ROOT} == / ]]; then
		eselect compiler-shadow update icecc
	fi
}
