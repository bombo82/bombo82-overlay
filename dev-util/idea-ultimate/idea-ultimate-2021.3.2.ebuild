# Copyright 2019-2021 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License  as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=7

inherit desktop wrapper

DESCRIPTION="A complete toolset for web, mobile and enterprise development"
HOMEPAGE="https://www.jetbrains.com/idea"
LICENSE="
	|| ( jetbrains_business-4.0 jetbrains_individual-4.2 jetbrains_educational-4.0 jetbrains_classroom-4.2 jetbrains_opensource-4.2 )
	Apache-1.1 Apache-2.0 BSD BSD-2 CC0-1.0 CC-BY-2.5 CDDL CDDL-1.1 codehaus CPL-1.0 GPL-2 GPL-2-with-classpath-exception GPL-3 ISC LGPL-2.1 LGPL-3 MIT MPL-1.1 MPL-2.0 OFL trilead-ssh yFiles yourkit W3C ZLIB
"
SLOT="0"
VER="$(ver_cut 1-2)"
KEYWORDS="~amd64"
RESTRICT="bindist mirror splitdebug"
IUSE="jbr-dcevm jbr-fd +jbr-jcef jbr-vanilla"
REQUIRED_USE="^^ ( jbr-dcevm jbr-fd jbr-jcef jbr-vanilla )"
QA_PREBUILT="opt/${P}/*"
RDEPEND="
	>=app-accessibility/at-spi2-atk-2.15.1
	dev-libs/libdbusmenu
	dev-util/lldb
	media-libs/mesa[X(+)]
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	>=x11-libs/libXi-1.3
	>=x11-libs/libXrandr-1.5
"

SIMPLE_NAME="Idea Ultimate"
MY_PN="idea"
SRC_URI_PATH="idea"
SRC_URI_PN="ideaIU"
JBR_PV="17_0_1"
JBR_PB="164.8"
SRC_URI="https://download.jetbrains.com/${SRC_URI_PATH}/${SRC_URI_PN}-${PV}.tar.gz -> ${P}.tar.gz
	jbr-dcevm?	( https://cache-redirector.jetbrains.com/intellij-jbr/jbr_dcevm-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
	jbr-fd?		( https://cache-redirector.jetbrains.com/intellij-jbr/jbr_fd-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
	jbr-jcef?	( https://cache-redirector.jetbrains.com/intellij-jbr/jbr_jcef-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
	jbr-vanilla?	( https://cache-redirector.jetbrains.com/intellij-jbr/jbr-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
"

BUILD_NUMBER="213.6777.52"
S="${WORKDIR}/idea-IU-${BUILD_NUMBER}"

src_prepare() {
	default

	local pty4j_path="lib/pty4j-native/linux"
	local jansi_path="plugins/maven/lib/maven3/lib/jansi-native"
	local remove_me=( "${pty4j_path}"/ppc64le "${pty4j_path}"/aarch64 "${pty4j_path}"/mips64el "${pty4j_path}"/arm )
	remove_me+=( "${jansi_path}"/freebsd32 "${jansi_path}"/freebsd64 "${jansi_path}"/osx "${jansi_path}"/windows32 "${jansi_path}"/windows64 )

	if ! use jbr-jcef ; then
		remove_me+=( )
	fi

	rm -rv "${remove_me[@]}" || die
}

src_install() {
	local dir="/opt/${P}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/"${MY_PN}".sh

	if ! use jbr-jcef ; then
		doins -r ../jbr
	fi
	fperms 755 "${dir}"/jbr/bin/{jaotc,java,javac,jdb,jfr,jhsdb,jjs,jrunscript,keytool,pack200,rmid,rmiregistry,serialver,unpack200}

	if use jbr-jcef; then
		fperms 755 "${dir}"/jbr/lib/jcef_helper
	fi

	fperms 755 "${dir}"/bin/fsnotifier

	make_wrapper "${PN}" "${dir}"/bin/"${MY_PN}".sh
	newicon bin/"${MY_PN}".svg "${PN}".svg
	make_desktop_entry "${PN}" "${SIMPLE_NAME} ${VER}" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
}
