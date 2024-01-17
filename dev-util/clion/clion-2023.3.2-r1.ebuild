# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop wrapper

DESCRIPTION="A cross-platform IDE for C and C++"
HOMEPAGE="https://www.jetbrains.com/clion/"
LICENSE="
	|| ( jetbrains_business-4.0 jetbrains_individual-4.2 jetbrains_educational-4.0 jetbrains_classroom-4.2 jetbrains_opensource-4.2 )
	Apache-1.1 Apache-2.0 BSD BSD-2 CC0-1.0 CDDL CPL-1.0 GPL-2-with-classpath-exception GPL-3 ISC LGPL-2.1 LGPL-3 MIT MPL-1.1 OFL PSF-2 trilead-ssh UoI-NCSA yFiles yourkit
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
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
"

SIMPLE_NAME="CLion"
MY_PN="${PN}"
SRC_URI_PATH="cpp"
SRC_URI_PN="CLion"
SRC_URI="https://download.jetbrains.com/${SRC_URI_PATH}/${SRC_URI_PN}-${PV}.tar.gz -> ${P}.tar.gz"

src_install() {
	local dir="/opt/${P}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/{"${MY_PN}",format,inspect,jetbrains_client,ltedit,remote-dev-server}.sh
	fperms 755 "${dir}"/bin/{fsnotifier,repair,restarter}
	fperms 755 "${dir}"/bin/clang/linux/x64/{clangd,clang-tidy,clazy-standalone,llvm-symbolizer}
	fperms 755 "${dir}"/bin/cmake/linux/x64/bin/{cmake,cpack,ctest}
	fperms 755 "${dir}"/bin/gdb/linux/x64/bin/{gcore,gdb,gdb-add-index,gdbserver}
	fperms 755 "${dir}"/bin/lldb/linux/x64/bin/{lldb,lldb-argdumper,LLDBFrontend,lldb-server}
	fperms 755 "${dir}"/bin/ninja/linux/x64/ninja

	fperms 755 "${dir}"/jbr/bin/{java,javac,javadoc,jcmd,jdb,jfr,jhsdb,jinfo,jmap,jps,jrunscript,jstack,jstat,keytool,rmiregistry,serialver}
	fperms 755 "${dir}"/jbr/lib/{chrome-sandbox,jcef_helper,jexec,jspawnhelper}

	fperms 755 "${dir}"/plugins/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-linux-amd64
    fperms 755 "${dir}"/plugins/javascript-impl/helpers/package-version-range-matcher/node_modules/semver/bin/semver.js
    fperms 755 "${dir}"/plugins/python-ce/helpers/{pockets/autolog.py,pycodestyle-2.10.0.py,pycodestyle.py,pydev/pydevd_attach_to_process/linux_and_mac/compile_linux_aarch64.sh,pydev/pydevd_attach_to_process/linux_and_mac/compile_linux.sh,pydev/pydevd_attach_to_process/linux_and_mac/compile_mac.sh,typeshed/scripts/generate_proto_stubs.sh,typeshed/scripts/sync_tensorflow_protobuf_stubs.sh}
    fperms 755 "${dir}"/plugins/remote-dev-server/{bin/launcher.sh,selfcontained/bin/xkbcomp,selfcontained/bin/Xvfb}
    fperms 755 "${dir}"/plugins/tailwindcss/server/tailwindcss-language-server

	make_wrapper "${PN}" "${dir}"/bin/"${MY_PN}".sh
	newicon bin/"${MY_PN}".svg "${PN}".svg
	make_desktop_entry "${PN}" "${SIMPLE_NAME} ${VER}" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
}
