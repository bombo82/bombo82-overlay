# Copyright 2026 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit desktop udev xdg

DESCRIPTION="Tool to control performance, energy, fan and comfort settings on TUXEDO laptops"
HOMEPAGE="https://github.com/tuxedocomputers/tuxedo-control-center"
SRC_URI="https://github.com/tuxedocomputers/tuxedo-control-center/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${P}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="-* ~amd64"

# npm ci and the electron/pkg binary downloads need network access during the build
RESTRICT="network-sandbox strip splitdebug"

RDEPEND="
	>=app-laptop/tuxedo-drivers-4.0.0
	app-accessibility/at-spi2-core
	dev-libs/libayatana-appindicator
	dev-libs/nss
	dev-libs/nspr
	media-libs/alsa-lib
	media-libs/mesa[X(+)]
	net-print/cups
	sys-apps/dbus
	sys-auth/elogind
	sys-auth/polkit
	sys-power/upower
	virtual/udev
	x11-apps/xrandr
	x11-libs/gdk-pixbuf
	x11-libs/gtk+:3[X]
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libdrm
	x11-libs/libxkbcommon
	x11-libs/libxshmfence
	x11-libs/pango
"
DEPEND="${RDEPEND}"
BDEPEND="
	>=net-libs/nodejs-24[npm]
	virtual/pkgconfig
"

QA_PREBUILT="usr/lib64/tuxedo-control-center/*"

TCC_PREFIX="/usr/lib64/tuxedo-control-center"
TCC_DATA="${TCC_PREFIX}/resources/dist/tuxedo-control-center/data"

src_prepare() {
	default
	eapply "${FILESDIR}/${P}-openrc-shutdown-fallback.patch"

	# relocate the payload paths from upstream's /opt layout to the Gentoo FHS layout
	# (TccPaths is the single source, compiled into both the Electron app and the daemon)
	sed -i "s|/opt/tuxedo-control-center|${TCC_PREFIX}|g" src/common/classes/TccPaths.ts || die "sed on TccPaths.ts failed"
}

src_compile() {
	export npm_config_cache="${T}/npm-cache"
	export XDG_CACHE_HOME="${T}/xdg-cache"
	# keep the Angular CLI non-interactive in the sandbox (analytics prompt kills the build)
	export NG_CLI_ANALYTICS="false"

	npm ci || die "npm ci failed"
	npm run build-prod || die "build-prod failed"
	./node_modules/.bin/electron-builder --linux dir --config "${FILESDIR}/electron-builder.gentoo.json" || die "electron-builder failed"
}

src_install() {
	local unpacked="dist/packages/linux-unpacked"

	insinto "${TCC_PREFIX}"
	doins -r "${unpacked}/."

	# doins resets executable bits; restore them where needed
	fperms 0755 "${TCC_PREFIX}/tuxedo-control-center"
	fperms 4755 "${TCC_PREFIX}/chrome-sandbox"
	fperms 0755 "${TCC_DATA}/service/tccd"
	[[ -e "${ED}${TCC_PREFIX}/chrome_crashpad_handler" ]] && fperms 0755 "${TCC_PREFIX}/chrome_crashpad_handler"

	dosym "${TCC_PREFIX}/tuxedo-control-center" /usr/bin/tuxedo-control-center

	newinitd "${FILESDIR}/tccd.initd" tccd

	# elogind sleep/resume hook (OpenRC equivalent of tccd-sleep.service);
	# /usr/lib/elogind/system-sleep is the package-provided hook location
	# (Gentoo's elogind libexecdir is /usr/lib/elogind, NOT /lib64/elogind);
	# /etc/elogind/system-sleep stays reserved for local admin overrides
	exeinto /usr/lib/elogind/system-sleep
	newexe "${FILESDIR}/tccd-sleep" 99-tccd

	# desktop entries (paths adapted from /opt to the Gentoo layout; unregistered "TUXEDO" category replaced)
	sed -e "s|/opt/tuxedo-control-center/tuxedo-control-center|/usr/bin/tuxedo-control-center|" -e "s|^Icon=.*|Icon=tuxedo-control-center|" -e "s|^Categories=.*|Categories=Settings;System;HardwareSettings;|" src/dist-data/tuxedo-control-center.desktop > "${T}/tuxedo-control-center.desktop" || die
	domenu "${T}/tuxedo-control-center.desktop"

	sed "s|/opt/tuxedo-control-center/tuxedo-control-center|/usr/bin/tuxedo-control-center|" src/dist-data/tuxedo-control-center-tray.desktop > "${T}/tuxedo-control-center-tray.desktop" || die
	insinto /etc/xdg/autostart
	doins "${T}/tuxedo-control-center-tray.desktop"

	newicon -s 256 src/dist-data/tuxedo-control-center_256.png tuxedo-control-center.png
	newicon -s scalable src/dist-data/tuxedo-control-center_256.svg tuxedo-control-center.svg

	insinto /usr/share/metainfo
	doins src/dist-data/com.tuxedocomputers.tcc.metainfo.xml

	# DBus and polkit integration (the polkit policy carries the tccd path)
	insinto /usr/share/dbus-1/system.d
	doins src/dist-data/com.tuxedocomputers.tccd.conf

	sed "s|/opt/tuxedo-control-center|${TCC_PREFIX}|g" src/dist-data/com.tuxedocomputers.tccd.policy > "${T}/com.tuxedocomputers.tccd.policy" || die
	insinto /usr/share/polkit-1/actions
	doins "${T}/com.tuxedocomputers.tccd.policy"
	doins src/dist-data/com.tuxedocomputers.tomte.policy

	# webcam restore rule (references the cameractrls.py path)
	sed "s|/opt/tuxedo-control-center|${TCC_PREFIX}|g" src/udev/99-webcam.rules > "${T}/99-webcam.rules" || die
	udev_dorules "${T}/99-webcam.rules"
}

pkg_postinst() {
	xdg_pkg_postinst
	udev_reload

	elog "The TUXEDO Control Center daemon (tccd) must be running for the"
	elog "application to work. To enable it at boot and start it now, run:"
	elog
	elog "  rc-update add tccd default"
	elog "  rc-service tccd start"
	elog
	elog "The tuxedo-drivers kernel modules must be loaded for most"
	elog "features (fan control, etc.) to work."
}

pkg_postrm() {
	xdg_pkg_postrm
	udev_reload
}
