# Copyright 2019 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License  as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=7

inherit desktop eutils

DESCRIPTION="The Python IDE for Professional Developers"
HOMEPAGE="https://www.jetbrains.com/pycharm"
SRC_URI="https://download.jetbrains.com/python/pycharm-professional-${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="|| ( jetbrains_business-3.1 jetbrains_individual-4.1 jetbrains_student-3.2 jetbrains_classroom-4.1 jetbrains_open_source-4.1 )"
SLOT="$(ver_cut 1-2)"
KEYWORDS="~amd64 ~x86"
RESTRICT="mirror splitdebug"
IUSE="custom-jdk"

RDEPEND="
	!custom-jdk? ( virtual/jdk )"

S="${WORKDIR}/pycharm-${PV}"

QA_PREBUILT="opt/${P}/*"

src_prepare() {
	default

	local remove_me=()

	use amd64 || remove_me+=( bin/fsnotifier64 lib/pty4j-native/linux/x86_64)
	use x86 || remove_me+=( bin/fsnotifier lib/pty4j-native/linux/x86)

	use custom-jdk || remove_me+=( jbr )

	rm -rv "${remove_me[@]}" || die
}

src_install() {
	local dir="/opt/${P}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/pycharm.sh

	if use amd64; then
		fperms 755 "${dir}"/bin/fsnotifier64
	fi
	if use x86; then
		fperms 755 "${dir}"/bin/fsnotifier
	fi

	if use custom-jdk; then
		if [[ -d jbr ]]; then
		fperms 755 "${dir}"/jbr/bin/{jaotc,java,javac,jdb,jjs,jrunscript,keytool,pack200,rmid,rmiregistry,serialver,unpack200}
		fi
	fi

	make_wrapper "${PN}" "${dir}/bin/pycharm.sh"
	newicon "bin/pycharm.svg" "${PN}.svg"
	make_desktop_entry "${PN}" "PyCharm ${SLOT}" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
}
