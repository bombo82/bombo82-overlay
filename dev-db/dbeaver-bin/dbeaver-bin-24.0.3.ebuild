# Copyright 2020-2024 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License  as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit desktop wrapper

DESCRIPTION="Free universal database tool and SQL client"
HOMEPAGE="https://dbeaver.io/"
SRC_URI="https://dbeaver.io/files/${PV}/dbeaver-ce-${PV}-linux.gtk.x86_64.tar.gz"
S="${WORKDIR}/dbeaver"
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror"

DEPEND=">=x11-libs/gtk+-2:2"
RDEPEND="${DEPEND}
	media-libs/alsa-lib
	x11-libs/libXtst
"

QA_FLAGS_IGNORED="CFLAGS LDFLAGS"

src_prepare() {
	default

	rm -rv ./plugins/com.sun.jna_5.13.0.v20230812-1000/com/sun/jna/{aix-*,darwin-*,freebsd-*,linux-aarch64,linux-arm,linux-armel,linux-loongarch64,linux-mips64el,linux-ppc,linux-ppc64le,linux-riscv64,linux-s390x,linux-x86,openbsd-*,sunos-*,win32,win32-*} || die
}

src_install() {
	local dir="/opt/${PN}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}/dbeaver"
	fperms 755 "${dir}/jre/bin/java"

	make_wrapper "${PN}" "${dir}/dbeaver"
	newicon "dbeaver.png" "${PN}.png"
	make_desktop_entry "${PN}" "DBeaver" "${PN}" "Development;IDE"
}
