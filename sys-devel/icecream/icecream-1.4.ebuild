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

	elog "For configuration help  and howto refer to the documentation inside"
	elog "/usr/share/doc/icecream-${PN} folder."

	ewarn "Starting with icecream-1.3.10-r2, the management of init scripts and"
	ewarn "configuration files has been split between the icecc compile daemon (iceccd)"
	ewarn "and the icecc scheduler."
	ewarn ""
	ewarn "Please migrate to new configurations and new init scripts:"
	ewarn "1. stop and disable old icecream daemon"
	ewarn "    rc-service icecream stop"
	ewarn "    rc-update del icecream"
	ewarn ""
	ewarn "2. (optionally) configure icecream compile daemon (iceccd) /etc/conf.d/iceccd"
	ewarn ""
	ewarn "3. (optionally) add iceccd to autostart and start it"
	ewarn "    rc-update add iceccd default"
	ewarn "    rc-service iceccd start"
	ewarn "4. (optionally) configure icecream scheduler /etc/conf.d/icecc-scheduler"
	ewarn ""
	ewarn "5. (optionally) add icecc-scheduler to autostart and start it"
	ewarn "    rc-update add icecc-scheduler default"
	ewarn "    rc-service icecc-scheduler start"
	ewarn ""
	ewarn "6. remove old icecream init script, configuration and logs"
	ewarn "    rm /etc/init.d/icecream"
	ewarn "    rm /etc/conf.d/icecream"
	ewarn "    rm /var/log/icecream/*"
}
