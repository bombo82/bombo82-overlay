# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop wrapper

DESCRIPTION="A cross-platform IDE for C and C++"
HOMEPAGE="https://www.jetbrains.com/clion"
LICENSE="
	|| ( jetbrains_business-4.0 jetbrains_individual-4.2 jetbrains_educational-4.0 jetbrains_classroom-4.2 jetbrains_opensource-4.2 )
	Apache-1.1 Apache-2.0 BSD BSD-2 CC0-1.0 CDDL CPL-1.0 GPL-2-with-classpath-exception GPL-3 ISC LGPL-2.1 LGPL-3 MIT MPL-1.1 OFL PSF-2 trilead-ssh UoI-NCSA yFiles yourkit
"
SLOT="0"
VER="$(ver_cut 1-2)"
KEYWORDS="~amd64"
RESTRICT="bindist mirror splitdebug"
IUSE="jbrsdk jbr-fd +jbrsdk-jcef jbr-vanilla"
REQUIRED_USE="^^ ( jbrsdk jbr-fd jbrsdk-jcef jbr-vanilla )"
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

SIMPLE_NAME="CLion"
MY_PN="${PN}"
SRC_URI_PATH="cpp"
SRC_URI_PN="CLion"
JBR_PV="17.0.3"
JBR_PB="463.3"
SRC_URI="https://download.jetbrains.com/${SRC_URI_PATH}/${SRC_URI_PN}-${PV}.tar.gz -> ${P}.tar.gz
	jbr-fd?		( https://cache-redirector.jetbrains.com/intellij-jbr/jbr_fd-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
	jbr-vanilla?	( https://cache-redirector.jetbrains.com/intellij-jbr/jbr-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
	jbrsdk?	( https://cache-redirector.jetbrains.com/intellij-jbr/jbrsdk-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
	jbrsdk-jcef?	( https://cache-redirector.jetbrains.com/intellij-jbr/jbrsdk_jcef-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
"

src_prepare() {
	default

	local pty4j_path="lib/pty4j-native/linux"
	local remove_me=( "${pty4j_path}"/ppc64le "${pty4j_path}"/aarch64 "${pty4j_path}"/mips64el "${pty4j_path}"/arm )

	if ! use jbrsdk-jcef ; then
		remove_me+=( )
	fi

	rm -rv "${remove_me[@]}" || die
}

src_install() {
	local dir="/opt/${P}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/"${MY_PN}".sh
	fperms 755 "${dir}"/bin/clang/linux/clang{d,-tidy}

	if ! use jbrsdk-jcef ; then
		doins -r ../jbr
	fi
	fperms 755 "${dir}"/jbr/bin/{jaotc,java,javac,jdb,jfr,jhsdb,jjs,jrunscript,keytool,pack200,rmid,rmiregistry,serialver,unpack200}

	if use jbrsdk-jcef; then
		fperms 755 "${dir}"/jbr/lib/jcef_helper
	fi

	fperms 755 "${dir}"/bin/fsnotifier
	fperms 755 "${dir}"/bin/ninja/linux/ninja

	make_wrapper "${PN}" "${dir}"/bin/"${MY_PN}".sh
	newicon bin/"${MY_PN}".svg "${PN}".svg
	make_desktop_entry "${PN}" "${SIMPLE_NAME} ${VER}" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
}
