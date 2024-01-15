# Copyright 2020-2024 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License  as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit desktop wrapper

DESCRIPTION="Multiplatform Visual Studio Code from Microsoft (binary version)"
HOMEPAGE="https://code.visualstudio.com"
SRC_URI="https://update.code.visualstudio.com/${PV}/linux-x64/stable -> ${PF}.tar.gz"
LICENSE="MS-vscode"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror"

DEPEND="
	media-libs/libpng
	x11-libs/gtk+:3
	x11-libs/cairo
	x11-libs/libXtst
	!app-editors/vscode
"

RDEPEND="
	${DEPEND}
	net-print/cups
	x11-libs/libnotify
	x11-libs/libXScrnSaver
	dev-libs/nss
	app-crypt/libsecret[crypt]
"

QA_PRESTRIPPED="opt/${PN}/code"
QA_PREBUILT="opt/${PN}/code"
QA_FLAGS_IGNORED="CFLAGS LDFLAGS"

S="${WORKDIR}/VSCode-linux-x64"

src_install(){
	local dir="/opt/${PN}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/code
	fperms 755 "${dir}"/code

	make_wrapper "${PN}" "${dir}/bin/code"
	newicon "resources/app/resources/linux/code.png" "${PN}.png"
	make_desktop_entry "${PN}" "Visual Studio Code" "${PN}" "Development;IDE"
}

pkg_postinst(){
	elog "You may install some additional utils, so check them in:"
	elog "https://code.visualstudio.com/Docs/setup#_additional-tools"
}
