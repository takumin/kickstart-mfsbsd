# vim: set ts=8 sw=8 sts=8 noet :

.POSIX:

all: build

.PHONY: all workdir download pkgng custom build clean

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
	@cp ${HOME}/.ssh/authorized_keys ${WRKDIR}/mfsbsd/conf/authorized_keys
	# hosts
	@echo '127.0.0.1 localhost' > ${WRKDIR}/mfsbsd/conf/hosts
	@echo '::1       localhost' >> ${WRKDIR}/mfsbsd/conf/hosts
	# loader.conf
	@echo 'autoboot_delay="-1"' > ${WRKDIR}/mfsbsd/conf/loader.conf
	@echo 'beastie_disable="YES"' >> ${WRKDIR}/mfsbsd/conf/loader.conf
	@echo 'mfsbsd.autodhcp="YES"' >> ${WRKDIR}/mfsbsd/conf/loader.conf
	@echo 'mfsbsd.hostname="mfsbsd"' >> ${WRKDIR}/mfsbsd/conf/loader.conf
	@echo 'mfsbsd.rootpw="mfsbsd"' >> ${WRKDIR}/mfsbsd/conf/loader.conf
	@echo 'geom_uzip_load="YES"' >> ${WRKDIR}/mfsbsd/conf/loader.conf
	@echo 'tmpfs_load="YES"' >> ${WRKDIR}/mfsbsd/conf/loader.conf
	@echo 'mfs_load="YES"' >> ${WRKDIR}/mfsbsd/conf/loader.conf
	@echo 'mfs_type="mfs_root"' >> ${WRKDIR}/mfsbsd/conf/loader.conf
	@echo 'mfs_name="/mfsroot"' >> ${WRKDIR}/mfsbsd/conf/loader.conf
	@echo 'ahci_load="YES"' >> ${WRKDIR}/mfsbsd/conf/loader.conf
	@echo 'vfs.root.mountfrom="ufs:/dev/md0"' >> ${WRKDIR}/mfsbsd/conf/loader.conf
	@echo 'mfsbsd.autodhcp="YES"' >> ${WRKDIR}/mfsbsd/conf/loader.conf
	# rc.conf
	@echo 'ifconfig_DEFAULT="SYNCDHCP"' > ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'tcp_drop_synfin="YES"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'icmp_drop_redirect="YES"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'sshd_enable="YES"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'sendmail_enable="NO"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'sendmail_cert_create="NO"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'sendmail_submit_enable="NO"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'sendmail_outbound_enable="NO"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'sendmail_msp_queue_enable="NO"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'cron_enable="NO"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'local_enable="YES"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'keymap="${KEYMAP}"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'keyrate="fast"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'keybell="off"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'ntpdate_enable="YES"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	@echo 'ntpdate_hosts="${NTPSERVER}"' >> ${WRKDIR}/mfsbsd/conf/rc.conf
	# sshd_config
	@mkdir -p ${WRKDIR}/mfsbsd/customfiles/etc/ssh
	@echo 'PermitRootLogin without-password' >> ${WRKDIR}/mfsbsd/customfiles/etc/ssh/sshd_config
	# timezone
	@cp -a /usr/share/zoneinfo/${TIMEZONE} ${WRKDIR}/mfsbsd/customfiles/etc/localtime
	@touch ${WRKDIR}/mfsbsd/customfiles/etc/wall_cmos_clock
	@chmod 0444 ${WRKDIR}/mfsbsd/customfiles/etc/wall_cmos_clock
	@touch $@

build: custom ${WRKDIR}/.build_done
${WRKDIR}/.build_done:
	@make -C mfsbsd iso BASE=${DSTDIR} WRKDIR=${WRKDIR} PACKAGESDIR=${PKGDIR} PKG_STATIC=${WRKDIR}/usr/local/sbin/pkg-static
	@touch $@

clean:
	@chflags -R noschg ${WRKDIR}
	@rm -fr ${WRKDIR}
	@make -C mfsbsd clean
