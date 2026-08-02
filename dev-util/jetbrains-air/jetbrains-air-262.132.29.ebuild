# Copyright 2019-2026 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit desktop wrapper

DESCRIPTION="An Agentic Development Environment by JetBrains"
HOMEPAGE="https://air.dev/"
SIMPLE_NAME="JetBrains Air"
MY_PN="Air"
SRC_URI_PATH="air"
SRC_URI_PN="air"
SRC_URI="https://download.jetbrains.com/${SRC_URI_PATH}/installers/linux_x64/${SRC_URI_PN^}-${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/Air"
LICENSE="
	jetbrains_team_tools-2.3
	anthropic-claude-code Apache-2.0 BSD BSD-2 CC0-1.0 CDDL-1.1 CDLA-Permissive-2.0 EPL-1.0 ISC MIT MPL-2.0 Unicode-3.0 Unlicense ZLIB
"
SLOT="0"
VER="$(ver_cut 1-2)"
KEYWORDS="~amd64"
RESTRICT="bindist mirror splitdebug"
QA_PREBUILT="opt/${P}/*"
RDEPEND="
	dev-libs/glib
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

src_install() {
	local dir="/opt/${P}"

	insinto "${dir}"
	doins -r *

	fperms 755 "${dir}"/bin/Air
	fperms 755 "${dir}"/jbr/bin/{jar,jarsigner,java,javac,javadoc,javap,jcmd,jconsole,jdb,jdeprscan,jdeps,jfr,jhsdb,jimage,jinfo,jlink,jmap,jmod,jnativescan,jpackage,jps,jrunscript,jshell,jstack,jstat,jstatd,jwebserver,keytool,rmiregistry,serialver}
	fperms 755 "${dir}"/jbr/lib/{jexec,jspawnhelper}
	fperms 755 "${dir}"/lib/app/bin/{air,printenv}

	make_wrapper "${PN}" "${dir}"/bin/"${MY_PN}"
	newicon lib/"${MY_PN}".png "${PN}".png
	make_desktop_entry "${PN}" "${SIMPLE_NAME} ${VER}" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
	}
