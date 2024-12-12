# Copyright 2022-2024 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit desktop wrapper

DESCRIPTION="Fast & powerful cross-platform .NET IDE"
HOMEPAGE="https://www.jetbrains.com/rider/"
SIMPLE_NAME="Rider"
MY_PN="rider"
SRC_URI_PATH="rider"
SRC_URI_PN="JetBrains.Rider"
SRC_URI="https://download.jetbrains.com/${SRC_URI_PATH}/${SRC_URI_PN}-${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/JetBrains Rider-${PV}"
# FIXME check licenses
LICENSE="
	|| ( jetbrains_business-4.0 jetbrains_individual-4.2 jetbrains_educational-4.0 jetbrains_classroom-4.2 jetbrains_opensource-4.2 )
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

	rm -rv ./lib/ReSharperHost/linux-arm || die
	rm -rv ./lib/ReSharperHost/linux-arm64 || die
	rm -rv ./lib/ReSharperHost/linux-musl-arm || die
	rm -rv ./lib/ReSharperHost/linux-musl-arm64 || die
	rm -rv ./lib/async-profiler/aarch64 || die
	rm -rv ./plugins/cidr-debugger-plugin/bin/lldb/linux/aarch64 || die
	rm -rv ./plugins/dotTrace.dotMemory/DotFiles/linux-arm64 || die
}

src_install() {
	local dir="/opt/${P}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/{"${MY_PN}",{format,inspect,jetbrains_client,ltedit,remote-dev-server}.sh}
	fperms 755 "${dir}"/bin/{fsnotifier,restarter}
	fperms 755 "${dir}"/bin/Bridge.framework/Versions/A/{Bridge,Resources/BridgeService}
	fperms 755 "${dir}"/bin/JBDevice.framework/Versions/A/{JBDevice,Resources/JBDeviceService}
	fperms 755 "${dir}"

	fperms 755 "${dir}"/jbr/bin/{java,javac,javadoc,jcmd,jdb,jfr,jhsdb,jinfo,jmap,jps,jrunscript,jstack,jstat,keytool,rmiregistry,serialver}
	fperms 755 "${dir}"/jbr/lib/{chrome-sandbox,jcef_helper,jexec,jspawnhelper}

	fperms 755 "${dir}"/lib/ReSharperHost/{Rider.Backend.sh,runtime-dotnet.sh}
	fperms 755 "${dir}"/lib/ReSharperHost/linux-x64/{dotnet/dotnet,Rider.Backend}

	fperms 755 "${dir}"/plugins/cidr-debugger-plugin/bin/lldb/linux/x64/{bin/lldb,bin/lldb-argdumper,bin/LLDBFrontend,bin/lldb-server,lib/xml2Conf.sh}
	fperms 755 "${dir}"/plugins/dotCommon/DotFiles/linux-x64/JetBrains.Profiler.PdbServer
	fperms 755 "${dir}"/plugins/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-linux-amd64
	fperms 755 "${dir}"/plugins/remote-dev-server/{bin/launcher.sh,selfcontained/bin/xkbcomp,selfcontained/bin/Xvfb}
	fperms 755 "${dir}"/plugins/tailwindcss/server/tailwindcss-language-server
	fperms 755 "${dir}"/tools/profiler/{dotMemory.sh,dotTrace.sh}

	make_wrapper "${PN}" "${dir}"/bin/"${MY_PN}"
	newicon bin/"${MY_PN}".svg "${PN}".svg
	make_desktop_entry "${PN}" "${SIMPLE_NAME} ${VER}" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
}
