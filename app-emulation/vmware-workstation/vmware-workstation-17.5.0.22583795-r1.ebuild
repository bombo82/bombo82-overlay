# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..12} )
inherit readme.gentoo-r1 pam python-any-r1 xdg-utils

MY_PN="VMware-Workstation-Full"
MY_PV=$(ver_cut 1-3)
PV_MODULES="${MY_PV}"
PV_BUILD=$(ver_cut 4)
MY_P="${MY_PN}-${MY_PV}-${PV_BUILD}"
VMWARE_FUSION_VER="13.0.0/20802013" # https://softwareupdate.vmware.com/cds/vmw-desktop/fusion/
UNLOCKER_VERSION="3.0.5"

DESCRIPTION="Emulate a complete PC without the performance overhead of most emulators"
HOMEPAGE="https://www.vmware.com/products/workstation-pro.html"
SRC_URI="
	https://download3.vmware.com/software/WKST-${MY_PV//./}-LX/${MY_P}.x86_64.bundle
	macos-guests? (
		https://github.com/paolo-projects/unlocker/archive/${UNLOCKER_VERSION}.tar.gz -> unlocker-${UNLOCKER_VERSION}.tar.gz
		vmware-tools-darwinPre15? ( https://softwareupdate.vmware.com/cds/vmw-desktop/fusion/${VMWARE_FUSION_VER}/x86/core/com.vmware.fusion.zip.tar -> com.vmware.fusion-${PV}.zip.tar )
		vmware-tools-darwin? ( https://softwareupdate.vmware.com/cds/vmw-desktop/fusion/${VMWARE_FUSION_VER}/x86/core/com.vmware.fusion.zip.tar -> com.vmware.fusion-${PV}.zip.tar )
	)
	"

LICENSE="GPL-2 GPL-3 MIT-with-advertising vmware"
SLOT="0"
KEYWORDS="~amd64"
# the kernel modules are optional because they're not needed to connect to VMs
# running on remote systems - https://bugs.gentoo.org/604426
IUSE="doc macos-guests +modules ovftool vix"
DARWIN_GUESTS="darwin darwinPre15"
IUSE_VMWARE_GUESTS="${DARWIN_GUESTS} linux linuxPreGlibc25 netware solaris windows winPre2k winPreVista"
for guest in ${IUSE_VMWARE_GUESTS}; do
	IUSE+=" vmware-tools-${guest}"
done
REQUIRED_USE="
	vmware-tools-darwin? ( macos-guests )
	vmware-tools-darwinPre15? ( macos-guests )
"
RESTRICT="mirror preserve-libs strip"

BDEPEND="
	app-admin/chrpath
"
RDEPEND="
	app-arch/bzip2
	app-arch/unzip
	app-shells/bash
	dev-db/sqlite:3
	dev-libs/dbus-glib
	dev-libs/gmp:0
	dev-libs/icu
	dev-libs/json-c
	dev-libs/nettle:0
	gnome-base/dconf
	media-gfx/graphite2
	media-libs/alsa-lib
	media-libs/libvorbis
	media-libs/mesa
	media-plugins/alsa-plugins[speex]
	net-dns/libidn
	net-libs/gnutls
	sys-apps/tcp-wrappers
	sys-apps/util-linux
	sys-auth/polkit
	virtual/libcrypt:*
	x11-libs/libXxf86vm
	x11-libs/libdrm
	x11-libs/libxshmfence
	x11-libs/startup-notification
	x11-libs/xcb-util
	x11-themes/hicolor-icon-theme
"
DEPEND="
	${PYTHON_DEPS}
	>=dev-util/patchelf-0.9
	modules? ( ~app-emulation/vmware-modules-${PV_MODULES} )
	ovftool? ( app-admin/chrpath )
"

S=${WORKDIR}/extracted
VM_INSTALL_DIR="/opt/vmware"

QA_PREBUILT="/opt/*"

QA_WX_LOAD="opt/vmware/lib/vmware/tools-upgraders/vmware-tools-upgrader-32 opt/vmware/lib/vmware/bin/vmware-vmx-stats opt/vmware/lib/vmware/bin/vmware-vmx-debug opt/vmware/lib/vmware/bin/vmware-vmx"
# adding "opt/vmware/lib/vmware/lib/libvmware-gksu.so/libvmware-gksu.so" to QA_WX_LOAD doesn't work

MY_ED="$ED"
src_unpack() {
	if has usersandbox ${FEATURES}; then
		ewarn "You are emerging ${P} with 'usersandbox' enabled." \
			"If unpacking fails, try emerging with 'FEATURES=-usersandbox'!"
	fi

	for a in ${A}; do
		if [ ${a##*.} == 'bundle' ]; then
			cp "${DISTDIR}/${a}" "${WORKDIR}"
		else
			unpack ${a}
		fi
	done

	export LC_ALL=C # https://communities.vmware.com/thread/618570?start=15&tstart=0
	local bundle="${MY_P}.x86_64.bundle"
	chmod 755 "${bundle}"
	# this needs a /tmp mounted without "noexec" because it extracts and executes scripts in there
	./${bundle} --console --required --eulas-agreed --extract=extracted || die "unable to extract bundle"

	if ! use vix; then
		rm -r extracted/vmware-vix-core extracted/vmware-vix-lib-Workstation* || die "unable to remove dir"
	fi

	if use vmware-tools-darwinPre15 || use vmware-tools-darwin; then
		unzip -q com.vmware.fusion.zip || die
		for guest in ${DARWIN_GUESTS}; do
			if use vmware-tools-${guest}; then
				mkdir extracted/vmware-tools-${guest}
				mv "payload/VMware Fusion.app/Contents/Library/isoimages/x86_x64/${guest}.iso" extracted/vmware-tools-${guest}/ || die
			fi
		done
		rm -rf __MACOSX payload manifest.plist preflight postflight com.vmware.fusion.zip
	fi
}

src_prepare() {
	default

	rm -f */bin/vmware-modconfig
	rm -rf */lib/modules/binary
	mkdir vmware-network-editor/lib/lib
	mv vmware-network-editor/lib/libvmware-netcfg.so vmware-network-editor/lib/lib/

	if use ovftool; then
		chrpath -d vmware-ovftool/libcurl.so.4
	fi

	if use macos-guests; then
		sed -i -e "s#vmx_path = '/usr#vmx_path = '${MY_ED}${VM_INSTALL_DIR//\//\\/}#" \
			-e "s#os\.path\.isfile('/usr#os.path.isfile('${MY_ED}${VM_INSTALL_DIR//\//\\/}#" \
			-e "s#vmwarebase = '/usr#vmwarebase = '${MY_ED}${VM_INSTALL_DIR//\//\\/}#" \
			"${WORKDIR}"/unlocker-*/unlocker.py
	fi

	DOC_CONTENTS="
/etc/env.d is updated during ${PN} installation. Please run:\n
'env-update && source /etc/profile'\n
Before you can use ${PN}, you must configure a default network setup.
You can do this by running 'emerge --config ${PN}'.\n
To be able to run ${PN} your user must be in the 'vmware' group."
}

src_install() {
	local major_minor=$(ver_cut 1-2 "${PV}")
	local vmware_installer_version=$(cat "${S}/vmware-installer/manifest.xml" | grep -oPm1 "(?<=<version>)[^<]+")

	# revdep-rebuild entry
	insinto /etc/revdep-rebuild
	echo "SEARCH_DIRS_MASK=\"${VM_INSTALL_DIR}\"" >> "${T}/10${PN}"
	doins "${T}"/10${PN}

	# install the binaries
	into "${VM_INSTALL_DIR}"
	dobin */bin/*
	dosbin */sbin/*
	rm "${MY_ED}${VM_INSTALL_DIR}"/bin/configure-initscript.sh || die
	mv "${MY_ED}${VM_INSTALL_DIR}"/sbin/vmware-authdlauncher "${MY_ED}${VM_INSTALL_DIR}"/sbin/vmware-authdlauncher.bin
	cat > "${MY_ED}${VM_INSTALL_DIR}"/sbin/vmware-authdlauncher <<-EOF
		#!/usr/bin/env bash
		export LD_LIBRARY_PATH="/opt/vmware/lib/vmware/lib/libssl.so.1.0.2:/opt/vmware/lib/vmware/lib/libcrypto.so.1.0.2"
		"${VM_INSTALL_DIR}"/sbin/vmware-authdlauncher.bin "\$@"
	EOF
	chmod 755 "${MY_ED}${VM_INSTALL_DIR}"/sbin/vmware-authdlauncher

	# install the libraries
	insinto "${VM_INSTALL_DIR}"/lib/vmware
	doins -r */lib/* vmware-vmx/roms
	rm "${MY_ED}${VM_INSTALL_DIR}"/lib/vmware/*.so || die

	# install the installer
	insinto "${VM_INSTALL_DIR}"/lib/vmware-installer/${vmware_installer_version}
	doins -r vmware-installer/{cdsHelper,vmis,vmis-launcher,vmware-cds-helper,vmware-installer,vmware-installer.py,python}
	chrpath -k -r '/../lib:$ORIGIN/../lib' "${MY_ED}${VM_INSTALL_DIR}"/lib/vmware-installer/${vmware_installer_version}/python/lib/lib-dynload/*.so >/dev/null || die
	fperms 0755 "${VM_INSTALL_DIR}"/lib/vmware-installer/${vmware_installer_version}/{vmis-launcher,cdsHelper,vmware-installer}
	dosym "${VM_INSTALL_DIR}"/lib/vmware-installer/${vmware_installer_version}/vmware-installer "${VM_INSTALL_DIR}"/bin/vmware-installer
	insinto /etc/vmware-installer
	doins vmware-installer/bootstrap
	sed -i \
		-e "s/@@VERSION@@/${vmware_installer_version}/" \
		-e "s,@@VMWARE_INSTALLER@@,${VM_INSTALL_DIR}/lib/vmware-installer/${vmware_installer_version}," \
		"${MY_ED}/etc/vmware-installer/bootstrap"

	# install the ancillaries
	insinto /usr
	doins -r */share

	# Hardcoded EULA path. We need to disable the default compression.
	insinto /usr/share/doc/vmware-workstation
	doins vmware-workstation/doc/EULA
	docompress -x /usr/share/doc/vmware-workstation
	# always needed
	insinto /usr/lib/vmware-ovftool
	doins vmware-ovftool/vmware.eula

	if use doc; then
		dodoc -r */doc/*
	fi

	exeinto "${VM_INSTALL_DIR}"/lib/vmware/setup
	doexe */vmware-config

	# pam
	pamd_mimic_system vmware-authd auth account

	# fuse
	insinto /etc/modprobe.d
	newins vmware-vmx/etc/modprobe.d/modprobe-vmware-fuse.conf vmware-fuse.conf

	# install vmware-vix
	if use vix; then
		# install the binary
		into "${VM_INSTALL_DIR}"
		dobin "$S"/vmware-vix-*/bin/*

		# install the libraries
		insinto "${VM_INSTALL_DIR}"/lib/vmware-vix
		doins -r "$S"/vmware-vix-*/lib/*

		dosym vmware-vix/libvixAllProducts.so "${VM_INSTALL_DIR}"/lib/libbvixAllProducts.so

		# install headers
		insinto /usr/include/vmware-vix
		doins "$S"/vmware-vix-*/include/*

		if use doc; then
			dodoc -r "$S"/vmware-vix-*/doc/*
		fi
	fi

	# install ovftool
	if use ovftool; then
		cd "${S}"/vmware-ovftool

		insinto "${VM_INSTALL_DIR}"/lib/vmware-ovftool
		doins -r *

		chmod 0755 "${MY_ED}${VM_INSTALL_DIR}"/lib/vmware-ovftool/{ovftool,ovftool.bin}
		sed -i 's/readlink/readlink -f/' "${MY_ED}${VM_INSTALL_DIR}"/lib/vmware-ovftool/ovftool
		dosym ../lib/vmware-ovftool/ovftool "${VM_INSTALL_DIR}"/bin/ovftool

		cd - >/dev/null
	fi

	# create symlinks for the various tools
	local tool;
	for tool in thnuclnt vmware vmplayer{,-daemon} licenseTool vmamqpd \
			vmware-{app-control,enter-serial,gksu,fuseUI,modconfig{,-console},netcfg,setup-helper,tray,unity-helper,vmblock-fuse,vprobe,zenity}; do
		dosym appLoader "${VM_INSTALL_DIR}"/lib/vmware/bin/"${tool}"
	done
	dosym "${VM_INSTALL_DIR}"/lib/vmware/bin/vmplayer "${VM_INSTALL_DIR}"/bin/vmplayer
	dosym "${VM_INSTALL_DIR}"/lib/vmware/bin/vmware "${VM_INSTALL_DIR}"/bin/vmware
	dosym "${VM_INSTALL_DIR}"/lib/vmware/bin/vmware-fuseUI "${VM_INSTALL_DIR}"/bin/vmware-fuseUI
	dosym "${VM_INSTALL_DIR}"/lib/vmware/bin/vmware-netcfg "${VM_INSTALL_DIR}"/bin/vmware-netcfg
	dosym "${VM_INSTALL_DIR}"/lib/vmware/icu /etc/vmware/icu

	# fix permissions
	fperms 0755 "${VM_INSTALL_DIR}"/lib/vmware/bin/{appLoader,fusermount,mkisofs,vmware-remotemks}
	fperms 0755 "${VM_INSTALL_DIR}"/lib/vmware/setup/vmware-config
	fperms 4711 "${VM_INSTALL_DIR}"/lib/vmware/bin/vmware-vmx{,-debug,-stats}
	fperms 0755 "${VM_INSTALL_DIR}"/lib/vmware/lib/libvmware-gksu.so/gksu-run-helper
	fperms 4711 "${VM_INSTALL_DIR}"/sbin/vmware-authd
	if use vix; then
		fperms 0755 "${VM_INSTALL_DIR}"/lib/vmware-vix/setup/vmware-config
	fi

	# create the environment
	local envd="${T}/90vmware"
	cat > "${envd}" <<-EOF
		PATH='${VM_INSTALL_DIR}/bin:${VM_INSTALL_DIR}/sbin'
		ROOTPATH='${VM_INSTALL_DIR}/bin'
		CONFIG_PROTECT_MASK='/etc/vmware-installer'
		VMWARE_USE_SHIPPED_LIBS=1
	EOF
	echo 'VMWARE_USE_SHIPPED_LIBS=1' >> "${envd}"

	doenvd "${envd}"

	# create the configuration
	dodir /etc/vmware

	cat > "${MY_ED}"/etc/vmware/bootstrap <<-EOF
		BINDIR='${VM_INSTALL_DIR}/bin'
		LIBDIR='${VM_INSTALL_DIR}/lib'
	EOF

	cat > "${MY_ED}"/etc/vmware/config <<-EOF
		.encoding = "UTF-8"
		bindir = "${VM_INSTALL_DIR}/bin"
		libdir = "${VM_INSTALL_DIR}/lib/vmware"
		initscriptdir = "/etc/init.d"
		authd.fullpath = "${VM_INSTALL_DIR}/sbin/vmware-authd"
		gksu.rootMethod = "su"
		VMCI_CONFED = "no"
		VMBLOCK_CONFED = "no"
		VSOCK_CONFED = "no"
		NETWORKING = "yes"
		player.product.version = "${MY_PV}"
		product.buildNumber = "${PV_BUILD}"
		product.version = "${MY_PV}"
		product.name = "VMware Workstation"
		workstation.product.version = "${MY_PV}"
		vmware.fullpath = "${VM_INSTALL_DIR}/bin/vmware"
		installerDefaults.componentDownloadEnabled = "no"
		installerDefaults.autoSoftwareUpdateEnabled.epoch = "4641104763"
		installerDefaults.dataCollectionEnabled.epoch = "7910652514"
		installerDefaults.dataCollectionEnabled = "no"
		installerDefaults.transferVersion = "1"
		installerDefaults.autoSoftwareUpdateEnabled = "no"
		acceptEULA = "yes"
		acceptOVFEULA = "yes"
	EOF

	if use vix; then
		cat >> "${MY_ED}"/etc/vmware/config <<-EOF
			vix.libdir = "${VM_INSTALL_DIR}/lib/vmware-vix"
			vix.config.version = "1"
		EOF
	fi

	if use modules; then
		# install the init.d script
		local initscript="${T}/vmware.rc"
		sed -e "s:@@BINDIR@@:${VM_INSTALL_DIR}/bin:g" \
			"${FILESDIR}/vmware-${major_minor}.rc" > "${initscript}" || die
		newinitd "${initscript}" vmware
	fi

	# fill in variable placeholders
	sed -e "s:@@LIBCONF_DIR@@:${VM_INSTALL_DIR}/lib/vmware/libconf:g" \
		-i "${MY_ED}${VM_INSTALL_DIR}"/lib/vmware/libconf/etc/gtk-3.0/gdk-pixbuf.loaders || die
	sed -e "s:@@BINARY@@:${EPREFIX}${VM_INSTALL_DIR}/bin/vmplayer:g" \
		-e "/^Encoding/d" \
		-i "${MY_ED}/usr/share/applications/vmware-player.desktop" || die
	sed -e "s:@@BINARY@@:${EPREFIX}${VM_INSTALL_DIR}/bin/vmware:g" \
		-e "/^Encoding/d" \
		-i "${MY_ED}/usr/share/applications/vmware-workstation.desktop" || die
	sed -e "s:@@BINARY@@:${EPREFIX}${VM_INSTALL_DIR}/bin/vmware-netcfg:g" \
		-e "/^Encoding/d" \
		-i "${MY_ED}/usr/share/applications/vmware-netcfg.desktop" || die

	# enable macOS guests support
	if use macos-guests; then
		python3 "${WORKDIR}"/unlocker-*/unlocker.py >/dev/null || die "unlocker.py failed"
	fi

	# VMware tools
	for guest in ${IUSE_VMWARE_GUESTS}; do
		if use vmware-tools-${guest}; then
			local dbfile="${MY_ED}/etc/vmware-installer/database"
			if ! [ -e "${dbfile}" ]; then
				> "${dbfile}"
				sqlite3 "${dbfile}" "CREATE TABLE settings(key VARCHAR PRIMARY KEY, value VARCHAR NOT NULL, component_name VARCHAR NOT NULL);"
				sqlite3 "${dbfile}" "INSERT INTO settings(key,value,component_name) VALUES('db.schemaVersion','2','vmware-installer');"
				sqlite3 "${dbfile}" "CREATE TABLE components(id INTEGER PRIMARY KEY, name VARCHAR NOT NULL, version VARCHAR NOT NULL, buildNumber INTEGER NOT NULL, component_core_id INTEGER NOT NULL, longName VARCHAR NOT NULL, description VARCHAR, type INTEGER NOT NULL);"
			fi
			local manifest="vmware-tools-${guest}/manifest.xml"
			if [ -e "${manifest}" ]; then
				local version="$(grep -oPm1 '(?<=<version>)[^<]+' ${manifest})"
				sqlite3 "${dbfile}" "INSERT INTO components(name,version,buildNumber,component_core_id,longName,description,type) VALUES(\"vmware-tools-$guest\",\"$version\",\"${PV_BUILD}\",1,\"$guest\",\"$guest\",1);"
			else
				sqlite3 "${dbfile}" "INSERT INTO components(name,version,buildNumber,component_core_id,longName,description,type) VALUES(\"vmware-tools-$guest\",\"${VMWARE_FUSION_VER%/*}\",\"${VMWARE_FUSION_VER#*/}\",1,\"$guest\",\"$guest\",1);"
			fi
			insinto "${VM_INSTALL_DIR}/lib/vmware/isoimages"
			doins vmware-tools-${guest}/${guest}.iso
		fi
	done

	# metadata
	mv "${MY_ED}/usr/share/appdata" "${MY_ED}/usr/share/metainfo"

	# readme
	readme.gentoo_create_doc
}

pkg_config() {
	"${VM_INSTALL_DIR}"/bin/vmware-networks --postinstall ${PN},old,new
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
	xdg_icon_cache_update
	readme.gentoo_print_elog
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
	xdg_icon_cache_update
}
