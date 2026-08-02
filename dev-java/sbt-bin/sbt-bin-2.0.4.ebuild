# Copyright 2025 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit java-pkg-2

DESCRIPTION="sbt is a simple build tool for Scala, Java, and more"
HOMEPAGE="https://www.scala-sbt.org/"
SRC_URI="https://github.com/sbt/sbt/releases/download/v${PV}/${PN/-bin}-${PV}.tgz"
S="${WORKDIR}/sbt"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=virtual/jre-1.8
	!dev-java/sbt"

src_prepare() {
	rm -rv ./bin/{sbtn-aarch64-pc-linux,sbtn-universal-apple-darwin,sbtn-x86_64-pc-win32.exe} || die

	default
}

src_install() {
	local dest="/usr/share/${PN}"

	sed -i -e 's#bin/sbt-launch.jar#lib/sbt-launch.jar#g;' \
		bin/sbt || die

	insinto "${dest}/lib"
	doins bin/sbt

	insinto "${dest}"
	doins -r conf

	fperms 0755 "${dest}/lib/sbt"
	dosym "${dest}/lib/sbt" /usr/bin/sbt
}
