# Copyright 2022-2024 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit desktop wrapper

DESCRIPTION="Your single entry point to all remote development environments"
HOMEPAGE="https://www.jetbrains.com/remote-development/gateway/"
SIMPLE_NAME="JetBrains Gateway"
MY_PN="gateway"
SRC_URI_PATH="idea/gateway"
SRC_URI_PN="JetBrainsGateway"
BUILD_NUMBER="253.30387.104"
SRC_URI="https://download.jetbrains.com/${SRC_URI_PATH}/${SRC_URI_PN}-${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${SRC_URI_PN}-${BUILD_NUMBER}"
LICENSE="
	jetbrains_team_tools-2.1
	Apache-1.1 Apache-2.0 BSD BSD-2 CC0-1.0 CC-BY-2.5 CDDL CDDL-1.1 codehaus CPL-1.0 GPL-2 GPL-2-with-classpath-exception GPL-3 ISC LGPL-2.1 LGPL-3 MIT MPL-1.1 MPL-2.0 OFL trilead-ssh yFiles yourkit W3C ZLIB
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
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
"

src_install() {
	local dir="/opt/${P}"

	insinto "${dir}"
	doins -r *
  fperms 755 "${dir}"/bin/"${MY_PN}"

  fperms 755 "${dir}"/bin/{format.sh,fsnotifier,gateway,gateway.sh,inspect.sh,ltedit.sh,restarter}
  fperms 755 "${dir}"/jbr/bin/{java,javac,javadoc,jcmd,jdb,jfr,jhsdb,jinfo,jmap,jps,jrunscript,jstack,jstat,jwebserver,keytool,rmiregistry,serialver}
  fperms 755 "${dir}"/jbr/lib/{jexec,jspawnhelper}
  fperms 755 "${dir}"/lib/remote-dev-workers/{remote-dev-worker-darwin-amd64,remote-dev-worker-darwin-arm64,remote-dev-worker-linux-amd64,remote-dev-worker-linux-arm64,remote-dev-worker-windows-amd64.exe,remote-dev-worker-windows-arm64.exe}
  fperms 755 "${dir}"/plugins/platform-ijent-impl/{ijent-aarch64-unknown-linux-musl-release,ijent-x86_64-unknown-linux-musl-release}

	make_wrapper "${PN}" "${dir}"/bin/"${MY_PN}".sh
	newicon bin/"${MY_PN}".svg "${PN}".svg
	make_desktop_entry "${PN}" "${SIMPLE_NAME} ${VER}" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
}
