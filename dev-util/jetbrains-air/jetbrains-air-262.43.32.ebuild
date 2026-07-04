# Copyright 2019-2026 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit desktop wrapper

DESCRIPTION="An Agentic Development Environment by JetBrains"
HOMEPAGE="https://air.dev/"
SIMPLE_NAME="JetBrains Air"
MY_PN="Air"
SRC_URI_PATH="air/installers/linux_x64"
SRC_URI_PN="Air"
SRC_URI="https://download.jetbrains.com/${SRC_URI_PATH}/${SRC_URI_PN}-${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/Air"
LICENSE="
	|| ( jetbrains_business-4.0 jetbrains_individual-4.2 jetbrains_educational-4.0 jetbrains_classroom-4.2 jetbrains_opensource-4.2 )
	Apache-1.1 Apache-2.0 BSD BSD-2 CC0-1.0 CDDL CDDL-1.1 CPL-1.0 GPL-2 GPL-2-with-classpath-exception GPL-3 ISC LGPL-2.1 LGPL-3 MIT MPL-1.1 OFL trilead-ssh yFiles yourkit W3C ZLIB
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
	fperms 755 "${dir}"/bin/"${MY_PN}"

	fperms 755 "${dir}"/jbr/bin/{jar,jarsigner,java,javac,javadoc,javap,jcmd,jconsole,jdb,jdeprscan,jdeps,jfr,jhsdb,jimage,jinfo,jlink,jmap,jmod,jnativescan,jpackage,jps,jrunscript,jshell,jstack,jstat,jstatd,jwebserver,keytool,rmiregistry,serialver}
	fperms 755 "${dir}"/jbr/lib/{jexec,jspawnhelper}
	fperms 755 "${dir}"/lib/app/bin/{air,printenv}
	fperms 755 "${dir}"/lib/app/libs/libjnidispatch.so

	make_wrapper "${PN}" "${dir}"/bin/"${MY_PN}"
	newicon lib/"${MY_PN}".png "${PN}".png
	make_desktop_entry "${PN}" "${SIMPLE_NAME} ${VER}" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
}
