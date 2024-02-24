# Copyright 2019-2024 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit desktop wrapper

DESCRIPTION="An IDE for writing tests you can be proud of"
HOMEPAGE="https://www.jetbrains.com/aqua/"
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
	dev-debug/lldb
	media-libs/mesa[X(+)]
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

SIMPLE_NAME="Aqua"
MY_PN="${PN}"
SRC_URI_PATH="aqua"
SRC_URI_PN="${PN}"
BUILD_NUMBER="233.14475.33"
SRC_URI="https://download.jetbrains.com/${SRC_URI_PATH}/${SRC_URI_PN}-${BUILD_NUMBER}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/${PN}-${BUILD_NUMBER}"

src_prepare() {
    default

    rm -rv ./lib/async-profiler/aarch64 || die
    rm -rv ./plugins/python-ce/helpers/pydev/pydevd_attach_to_process/attach_linux_aarch64.so || die
}

src_install() {
	local dir="/opt/${P}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/{"${MY_PN}",format,inspect,ltedit}.sh
	fperms 755 "${dir}"/bin/{fsnotifier,repair,restarter}

	fperms 755 "${dir}"/jbr/bin/{java,javac,javadoc,jcmd,jdb,jfr,jhsdb,jinfo,jmap,jps,jrunscript,jstack,jstat,keytool,rmiregistry,serialver}
	fperms 755 "${dir}"/jbr/lib/{chrome-sandbox,jcef_helper,jexec,jspawnhelper}

    fperms 755 "${dir}"/plugins/javascript-impl/helpers/package-version-range-matcher/node_modules/semver/bin/semver.js
    fperms 755 "${dir}"/plugins/Kotlin/kotlinc/bin/{kotlin,kotlinc,kotlinc-js,kotlinc-jvm,kotlin-dce-js}
    fperms 755 "${dir}"/plugins/maven/lib/maven3/bin/{mvn,mvnDebug,mvnyjp}
    fperms 755 "${dir}"/plugins/python-ce/helpers/{pockets/autolog.py,pycodestyle-2.10.0.py,pycodestyle.py,pydev/pydevd_attach_to_process/linux_and_mac/compile_linux_aarch64.sh,pydev/pydevd_attach_to_process/linux_and_mac/compile_linux.sh,pydev/pydevd_attach_to_process/linux_and_mac/compile_mac.sh,typeshed/scripts/generate_proto_stubs.sh,typeshed/scripts/sync_tensorflow_protobuf_stubs.sh}
    fperms 755 "${dir}"/plugins/tailwindcss/server/tailwindcss-language-server

	make_wrapper "${PN}" "${dir}"/bin/"${MY_PN}".sh
	newicon bin/"${MY_PN}".svg "${PN}".svg
	make_desktop_entry "${PN}" "${SIMPLE_NAME} ${VER}" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
}
