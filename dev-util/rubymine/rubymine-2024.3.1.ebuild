# Copyright 2019-2024 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit desktop wrapper

DESCRIPTION="Code Smarter with Ruby on Rails IDE"
HOMEPAGE="https://www.jetbrains.com/ruby/"
SIMPLE_NAME="RubyMine"
MY_PN="${PN}"
SRC_URI_PATH="ruby"
SRC_URI_PN="RubyMine"
SRC_URI="https://download.jetbrains.com/${SRC_URI_PATH}/${SRC_URI_PN}-${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/RubyMine-${PV}"
LICENSE="
	|| ( jetbrains_business-4.0 jetbrains_individual-4.2 jetbrains_educational-4.0 jetbrains_classroom-4.2 jetbrains_opensource-4.2 )
	Apache-1.1 Apache-2.0 BSD BSD-2 CC0-1.0 CDDL CPL-1.0 GPL-2 GPL-2-with-classpath-exception GPL-3 ISC LGPL-2.1 LGPL-3 MIT MPL-1.1 OFL trilead-ssh yFiles yourkit
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
}

src_install() {
	local dir="/opt/${P}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/{"${MY_PN}",{format,jetbrains_client,ltedit,remote-dev-server}.sh}
	fperms 755 "${dir}"/bin/{fsnotifier,restarter}

	fperms 755 "${dir}"/jbr/bin/{java,javac,javadoc,jcmd,jdb,jfr,jhsdb,jinfo,jmap,jps,jrunscript,jstack,jstat,keytool,rmiregistry,serialver}
	fperms 755 "${dir}"/jbr/lib/{chrome-sandbox,jcef_helper,jexec,jspawnhelper}

	fperms 755 "${dir}"/plugins/gateway-plugin/lib/remote-dev-workers/remote-dev-worker-linux-amd64
	fperms 755 "${dir}"/plugins/ruby/rb/{consoles/exec/irb,consoles/exec/pry,stubsgen/gems/gems/rdoc-3.9.4/bin/rdoc,stubsgen/gems/gems/rdoc-3.9.4/bin/ri,terminal/asdf_starter.sh,terminal/chruby_starter.sh,terminal/rbenv_starter.sh,terminal/rvm_starter.sh,wsl/print_dirs.sh,wsl/sync_file.sh}
	fperms 755 "${dir}"/plugins/remote-dev-server/{bin/launcher.sh,selfcontained/bin/xkbcomp,selfcontained/bin/Xvfb}
	fperms 755 "${dir}"/plugins/tailwindcss/server/tailwindcss-language-server

	make_wrapper "${PN}" "${dir}"/bin/"${MY_PN}"
	newicon bin/"${MY_PN}".svg "${PN}".svg
	make_desktop_entry "${PN}" "${SIMPLE_NAME} ${VER}" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
}
