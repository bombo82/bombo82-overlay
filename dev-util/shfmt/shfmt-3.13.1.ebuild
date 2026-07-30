# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit edo go-module

MY_PN="${PN/fmt/}"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="A shell parser, formatter, and interpreter with bash support"
HOMEPAGE="https://github.com/mvdan/sh"
SRC_URI="https://github.com/mvdan/${MY_PN}/archive/v${PV}.tar.gz -> ${MY_P}.tar.gz
	https://github.com/nuclear06/gentoo-deps/releases/download/${P}/${P}-deps.tar.xz"
S="${WORKDIR}/${MY_P}"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+man"

BDEPEND="man? ( app-text/scdoc )"

DOCS=( {CHANGELOG,README}.md )

src_compile() {
	LDFLAGS="-s -w -X main.version=${PV}"

	ego build -ldflags "${LDFLAGS}" ./cmd/shfmt

	use man && edo scdoc < cmd/shfmt/shfmt.1.scd > shfmt.1
}

src_test() {
	ego test -work ./...
}

src_install() {
	einstalldocs
	dobin shfmt
	use man && doman shfmt.1
}
