# Copyright 2019-2021 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License  as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=7

inherit desktop wrapper

DESCRIPTION="The smartest JavaScript IDE"
HOMEPAGE="https://www.jetbrains.com/webstorm"
LICENSE="
	|| ( jetbrains_business-3.1 jetbrains_individual-4.1 jetbrains_education-3.2 jetbrains_classroom-4.1 jetbrains_open_source-4.1 )
	Apache-1.1 Apache-2.0 BSD BSD-2 CC0-1.0 CDDL CDDL-1.1 CPL-1.0 GPL-2 GPL-2-with-classpath-exception GPL-3 ISC LGPL-2.1 LGPL-3 MIT MPL-1.1 OFL trilead-ssh yFiles yourkit W3C ZLIB
"
SLOT="0"
VER="$(ver_cut 1-2)"
KEYWORDS="~amd64 ~x86"
RESTRICT="bindist mirror splitdebug"
IUSE="jbr-dcevm jbr-fd +jbr-jcef jbr-vanilla"
REQUIRED_USE="amd64 ( ^^ ( jbr-dcevm jbr-fd jbr-jcef jbr-vanilla ) )"
QA_PREBUILT="opt/${P}/*"
RDEPEND="
	dev-libs/libdbusmenu
	dev-util/lldb
"

SIMPLE_NAME="WebStorm"
MY_PN="${PN}"
SRC_URI_PATH="webstorm"
SRC_URI_PN="WebStorm"
JBR_PV="11_0_10"
JBR_PB="1419.1"
SRC_URI="https://download.jetbrains.com/${SRC_URI_PATH}/${SRC_URI_PN}-${PV}.tar.gz -> ${P}.tar.gz
	amd64?	(
		jbr-dcevm?	( https://jetbrains.bintray.com/intellij-jbr/jbr_dcevm-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
		jbr-fd?		( https://jetbrains.bintray.com/intellij-jbr/jbr_fd-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
		jbr-jcef?	( https://jetbrains.bintray.com/intellij-jbr/jbr_jcef-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
		jbr-vanilla?	( https://jetbrains.bintray.com/intellij-jbr/jbr_nomod-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
	)
	x86?	( https://jetbrains.bintray.com/intellij-jbr/jbr-${JBR_PV}-linux-x86-b${JBR_PB}.tar.gz )
"

BUILD_NUMBER="211.6693.108"
S="${WORKDIR}/WebStorm-${BUILD_NUMBER}"

src_prepare() {
	default

	local pty4j_path="lib/pty4j-native/linux"
	local remove_me=( "${pty4j_path}"/ppc64le "${pty4j_path}"/aarch64 "${pty4j_path}"/mips64el )
	use amd64 || remove_me+=( bin/fsnotifier64 "${pty4j_path}"/x86_64 )
	use x86 || remove_me+=( bin/fsnotifier "${pty4j_path}"/x86 )

	if use amd64 && ! use jbr-jcef ; then
		remove_me+=( )
	fi

	rm -rv "${remove_me[@]}" || die
}

src_install() {
	local dir="/opt/${P}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/"${MY_PN}".sh

	if use amd64 && ! use jbr-jcef ; then
		doins -r ../jbr
	fi
	fperms 755 "${dir}"/jbr/bin/{jaotc,java,javac,jdb,jfr,jhsdb,jjs,jrunscript,keytool,pack200,rmid,rmiregistry,serialver,unpack200}

	if use amd64; then
		fperms 755 "${dir}"/bin/fsnotifier64
	fi
	if use x86; then
		fperms 755 "${dir}"/bin/fsnotifier
	fi

	make_wrapper "${PN}" "${dir}"/bin/"${MY_PN}".sh
	newicon bin/"${MY_PN}".svg "${PN}".svg
	make_desktop_entry "${PN}" "${SIMPLE_NAME} ${VER}" "${PN}" "Development;IDE;WebDevelopment;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
}
