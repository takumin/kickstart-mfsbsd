# vim: set ts=8 sw=8 sts=8 noet :

.POSIX:

all: build

.PHONY: all workdir download pkgng custom create clean

MIRROR?=	ftp.jp.freebsd.org
ARCH?=		amd64
VERSION?=	10.1-RELEASE
KEYMAP?=	jp.capsctrl.kbd
TIMEZONE?=	Asia/Tokyo
NTPSERVER?=	ntp.jst.mfeed.ad.jp

WRKDIR?=	${.CURDIR}/.tmp
DSTDIR?=	${WRKDIR}/dist
PKGDIR?=	${.CURDIR}/packages
PKG_ABI:=	freebsd:${VERSION:C/([0-9]{1,2}).*/\1/}:x86:${ARCH:C/.*([0-9]{2}.*)/\1/}

workdir: ${WRKDIR} ${DSTDIR}
${WRKDIR}:
	@mkdir $@
${DSTDIR}:
	@mkdir $@

download: workdir ${WRKDIR}/.download_done
${WRKDIR}/.download_done:
	@fetch -o ${DSTDIR}/base.txz http://${MIRROR}/pub/FreeBSD/releases/${ARCH}/${VERSION}/base.txz
	@fetch -o ${DSTDIR}/kernel.txz http://${MIRROR}/pub/FreeBSD/releases/${ARCH}/${VERSION}/kernel.txz
	@fetch -o ${WRKDIR}/pkg.txz http://pkg.freebsd.org/${PKG_ABI}/latest/Latest/pkg.txz
	@touch $@

pkgng: download ${WRKDIR}/.pkgng_done
${WRKDIR}/.pkgng_done:
	@tar -xf ${WRKDIR}/pkg.txz -C ${WRKDIR} --include "*pkg-static"
	@touch $@

custom: pkgng ${WRKDIR}/.custom_done
${WRKDIR}/.custom_done:
	# authorized_keys
	@cp ${HOME}/.ssh/authorized_keys ${.CURDIR}/mfsbsd/conf/authorized_keys
	# hosts
	@echo '127.0.0.1 localhost' > ${.CURDIR}/mfsbsd/conf/hosts
	@echo '::1       localhost' >> ${.CURDIR}/mfsbsd/conf/hosts
	# loader.conf
	@echo 'autoboot_delay="-1"' > ${.CURDIR}/mfsbsd/conf/loader.conf
	@echo 'beastie_disable="YES"' >> ${.CURDIR}/mfsbsd/conf/loader.conf
	@echo 'mfsbsd.autodhcp="YES"' >> ${.CURDIR}/mfsbsd/conf/loader.conf
	@echo 'mfsbsd.hostname="mfsbsd"' >> ${.CURDIR}/mfsbsd/conf/loader.conf
	@echo 'mfsbsd.rootpw="mfsbsd"' >> ${.CURDIR}/mfsbsd/conf/loader.conf
	@echo 'geom_uzip_load="YES"' >> ${.CURDIR}/mfsbsd/conf/loader.conf
	@echo 'tmpfs_load="YES"' >> ${.CURDIR}/mfsbsd/conf/loader.conf
	@echo 'mfs_load="YES"' >> ${.CURDIR}/mfsbsd/conf/loader.conf
	@echo 'mfs_type="mfs_root"' >> ${.CURDIR}/mfsbsd/conf/loader.conf
	@echo 'mfs_name="/mfsroot"' >> ${.CURDIR}/mfsbsd/conf/loader.conf
	@echo 'ahci_load="YES"' >> ${.CURDIR}/mfsbsd/conf/loader.conf
	@echo 'vfs.root.mountfrom="ufs:/dev/md0"' >> ${.CURDIR}/mfsbsd/conf/loader.conf
	@echo 'mfsbsd.autodhcp="YES"' >> ${.CURDIR}/mfsbsd/conf/loader.conf
	# rc.conf
	@echo 'ifconfig_DEFAULT="SYNCDHCP"' > ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'tcp_drop_synfin="YES"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'icmp_drop_redirect="YES"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'sshd_enable="YES"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'sendmail_enable="NO"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'sendmail_cert_create="NO"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'sendmail_submit_enable="NO"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'sendmail_outbound_enable="NO"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'sendmail_msp_queue_enable="NO"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'cron_enable="NO"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'local_enable="YES"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'keymap="${KEYMAP}"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'keyrate="fast"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'keybell="off"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'ntpdate_enable="YES"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	@echo 'ntpdate_hosts="${NTPSERVER}"' >> ${.CURDIR}/mfsbsd/conf/rc.conf
	# sshd_config
	@mkdir -p ${.CURDIR}/mfsbsd/customfiles/etc/ssh
	@echo 'PermitRootLogin without-password' >> ${.CURDIR}/mfsbsd/customfiles/etc/ssh/sshd_config
	# timezone
	@cp -a /usr/share/zoneinfo/${TIMEZONE} ${.CURDIR}/mfsbsd/customfiles/etc/localtime
	@touch ${.CURDIR}/mfsbsd/customfiles/etc/wall_cmos_clock
	@chmod 0444 ${.CURDIR}/mfsbsd/customfiles/etc/wall_cmos_clock
	@touch $@

create: custom ${WRKDIR}/.create_done
${WRKDIR}/.create_done:
	@sudo make -C mfsbsd iso BASE=${DSTDIR} WRKDIR=${WRKDIR} \
		PACKAGESDIR=${PKGDIR} PKG_STATIC=${WRKDIR}/usr/local/sbin/pkg-static \
		ISOIMAGE=../mfsBSD-${VERSION}-${ARCH}.iso
	@touch $@

clean:
	@sudo make -C mfsbsd clean WRKDIR=${WRKDIR}
