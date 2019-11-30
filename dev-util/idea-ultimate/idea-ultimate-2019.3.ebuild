# Copyright 2019 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License  as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=7

inherit desktop eutils

DESCRIPTION="A complete toolset for web, mobile and enterprise development"
HOMEPAGE="https://www.jetbrains.com/idea"
SRC_URI="https://download.jetbrains.com/idea/ideaIU-${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="|| ( jetbrains_business-3.1 jetbrains_individual-4.1 jetbrains_education-3.2 jetbrains_classroom-4.1 jetbrains_open_source-4.1 )
	Apache-1.1 Apache-2.0 BSD BSD-2 CC0-1.0 CC-BY-2.5 CDDL classworlds CPL-1.0 GPL-2 GPL-2-with-classpath-exception GPL-3 ISC java-mission-control LGPL-2.1 LGPL-3 MIT MPL-1.1 OFL trilead-ssh yFiles yourkit W3C
"
SLOT="0"
VER="$(ver_cut 1-2)"
KEYWORDS="~amd64 ~x86"
RESTRICT="bindist mirror splitdebug"
IUSE="custom-jdk"

RDEPEND="
	!custom-jdk? ( virtual/jdk )"

BUILD_NUMBER="193.5233.102"
S="${WORKDIR}/idea-IU-${BUILD_NUMBER}"

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
	fperms 755 "${dir}"/bin/idea.sh

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

	make_wrapper "${PN}" "${dir}/bin/idea.sh"
	newicon "bin/idea.svg" "${PN}.svg"
	make_desktop_entry "${PN}" "Idea Ultimate ${VER}" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
}
