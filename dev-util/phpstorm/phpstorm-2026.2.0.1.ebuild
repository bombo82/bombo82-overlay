# Copyright 2019-2024 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit desktop wrapper

DESCRIPTION="The Lightning-Smart PHP IDE"
HOMEPAGE="https://www.jetbrains.com/go/"
SIMPLE_NAME="PhpStorm"
MY_PN="${PN}"
SRC_URI_PATH="webide"
SRC_URI_PN="PhpStorm"
SRC_URI="https://download.jetbrains.com/${SRC_URI_PATH}/${SRC_URI_PN}-${PV}.tar.gz -> ${P}.tar.gz"
BUILD_NUMBER="262.8665.325"
S="${WORKDIR}/PhpStorm-${BUILD_NUMBER}"
LICENSE="
	|| ( jetbrains_business-4.2 jetbrains_individual-4.4 jetbrains_educational-4.2 jetbrains_classroom-4.3 jetbrains_opensource-4.3 )
	Apache-2.0 BSD BSD-2 CC0-1.0 CC-BY-2.5 CDDL-1.1 codehaus CPL-1.0 EPL-1.0 EPL-2.0 GPL-2-with-classpath-exception ISC JDOM JSON LGPL-2 LGPL-2.1 LGPL-3 MIT MPL-2.0 OFL-1.1 redocly unicode UPL-1.0 yFiles ZLIB
"
SLOT="0"
VER="$(ver_cut 1-2)"
KEYWORDS="~amd64"
RESTRICT="bindist mirror splitdebug"
QA_PREBUILT="opt/${P}/*"
RDEPEND="
	dev-libs/libdbusmenu
	llvm-core/lldb
	media-libs/mesa[X(+)]
	sys-devel/gcc
	sys-libs/glibc
	sys-libs/libselinux
	sys-process/audit
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
"

src_prepare() {
	default

	rm -rv ./lib/async-profiler/aarch64 || die
	rm -rv ./plugins/remote-dev-server/selfcontained/X11/xkb/symbols/macintosh_vndr || die
}

src_install() {
	local dir="/opt/${P}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/"${MY_PN}"

	fperms 755 "${dir}"/bin/{format.sh,fsnotifier,inspect.sh,jetbrains_client.sh,ltedit.sh,phpstorm,phpstorm.sh,remote-dev-server,remote-dev-server.sh,restarter}
	fperms 755 "${dir}"/jbr/bin/{java,javac,javadoc,jcmd,jdb,jfr,jhsdb,jinfo,jmap,jps,jrunscript,jstack,jstat,jwebserver,keytool,rmiregistry,serialver}
	fperms 755 "${dir}"/jbr/lib/{jexec,jspawnhelper}
	fperms 755 "${dir}"/plugins/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-linux-amd64
	fperms 755 "${dir}"/plugins/jcef-plugin/jcef/{cef_server,chrome-sandbox,jcef_helper}
	fperms 755 "${dir}"/plugins/remote-dev-server/bin/launcher.sh
	fperms 755 "${dir}"/plugins/remote-dev-server/selfcontained/bin/{xkbcomp,Xvfb}
	fperms 755 "${dir}"/plugins/tailwindcss/server/bin/tailwindcss-language-server

	make_wrapper "${PN}" "${dir}"/bin/"${MY_PN}"
	newicon bin/"${MY_PN}".svg "${PN}".svg
	make_desktop_entry "${PN}" "${SIMPLE_NAME} ${VER}" "${PN}" "Development;IDE;WebDevelopment;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
	}
