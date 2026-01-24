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
  fperms 755 "${dir}"/bin/"${MY_PN}"

  fperms 755 "${dir}"/bin/{format.sh,fsnotifier,jetbrains_client.sh,ltedit.sh,remote-dev-server,remote-dev-server.sh,restarter,rinspect.sh,rubymine,rubymine.sh}
  fperms 755 "${dir}"/jbr/bin/{java,javac,javadoc,jcmd,jdb,jfr,jhsdb,jinfo,jmap,jps,jrunscript,jstack,jstat,jwebserver,keytool,rmiregistry,serialver}
  fperms 755 "${dir}"/jbr/lib/{cef_server,chrome-sandbox,jcef_helper,jexec,jspawnhelper}
  fperms 755 "${dir}"/plugins/gateway-plugin/lib/remote-dev-workers/{remote-dev-worker-darwin-amd64,remote-dev-worker-darwin-arm64,remote-dev-worker-linux-amd64,remote-dev-worker-linux-arm64,remote-dev-worker-windows-amd64.exe,remote-dev-worker-windows-arm64.exe}
  fperms 755 "${dir}"/plugins/platform-ijent-impl/{ijent-aarch64-unknown-linux-musl-release,ijent-x86_64-unknown-linux-musl-release}
  fperms 755 "${dir}"/plugins/remote-dev-server/bin/launcher.sh
  fperms 755 "${dir}"/plugins/remote-dev-server/selfcontained/bin/{xkbcomp,Xvfb}
  fperms 755 "${dir}"/plugins/ruby/rb/consoles/exec/{irb,pry}
  fperms 755 "${dir}"/plugins/ruby/rb/stubsgen/gems/gems/rdoc-3.9.4/bin/{rdoc,ri}
  fperms 755 "${dir}"/plugins/ruby/rb/terminal/{asdf_starter.sh,chruby_starter.sh,mise_starter.sh,rbenv_starter.sh,rvm_starter.sh}
  fperms 755 "${dir}"/plugins/ruby/rb/wsl/{print_dirs.sh,sync_file.sh}
  fperms 755 "${dir}"/plugins/tailwindcss/server/tailwindcss-language-server

	make_wrapper "${PN}" "${dir}"/bin/"${MY_PN}"
	newicon bin/"${MY_PN}".svg "${PN}".svg
	make_desktop_entry "${PN}" "${SIMPLE_NAME} ${VER}" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
}
