# Copyright 2019-2022 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit autotools

DESCRIPTION="Distributed compiling of C(++) code across several machines; based on distcc"
HOMEPAGE="https://github.com/icecc/icecream"
SRC_URI="https://github.com/icecc/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~x86"

DEPEND="
	acct-user/icecream
	acct-group/icecream
	sys-libs/libcap-ng
	app-arch/libarchive
	dev-libs/lzo
	app-arch/zstd
	app-text/docbook2X
"
RDEPEND="
	${DEPEND}
	dev-util/shadowman
"

src_prepare() {
	default
	eautoreconf
}

src_install() {
	default
	find "${D}" -name '*.la' -delete || die

	dodoc "${FILESDIR}"/HOWTO_Setup_an_ICECREAM_Compile_Cluster_on_Gentoo.md

	newinitd "${FILESDIR}"/iceccd.rc iceccd
	newinitd "${FILESDIR}"/icecc-scheduler.rc icecc-scheduler
	newconfd "${FILESDIR}"/iceccd.confd iceccd
	newconfd "${FILESDIR}"/icecc-scheduler.confd icecc-scheduler

	insinto /usr/share/shadowman/tools
	newins - icecc <<<'/usr/libexec/icecc/bin'

	insinto /etc/logrotate.d
	newins "${FILESDIR}"/icecream.logrotate icecream
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

	elog "For configuration help and howto refer to the documentation inside"
	elog "/usr/share/doc/${PF}/ folder."
	elog ""
	elog "icecream is split into two services:"
	elog "  - iceccd: the compile daemon"
	elog "  - icecc-scheduler: the job scheduler"
	elog ""
	elog "To enable and start them:"
	elog "  rc-update add iceccd default"
	elog "  rc-service iceccd start"
	elog "  rc-update add icecc-scheduler default"
	elog "  rc-service icecc-scheduler start"
}
