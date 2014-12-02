.POSIX:

all: build

.PHONY: all workdir download build clean

MIRROR?=ftp.jp.freebsd.org
ARCH?=amd64
VERSION?=10.1-RELEASE

WRKDIR?=${PWD}/.tmp
DSTDIR?=${WRKDIR}/dist
BASE?=${DSTDIR}
PKG_STATIC?=/usr/local/sbin/pkg-static
PACKAGESDIR?=packages

workdir: ${WRKDIR} ${DSTDIR}
${WRKDIR}:
	@mkdir $@
${DSTDIR}:
	@mkdir $@

download: workdir ${WRKDIR}/.download_done
${WRKDIR}/.download_done:
	@fetch -o ${DSTDIR}/base.txz http://${MIRROR}/pub/FreeBSD/releases/${ARCH}/${VERSION}/base.txz
	@fetch -o ${DSTDIR}/kernel.txz http://${MIRROR}/pub/FreeBSD/releases/${ARCH}/${VERSION}/kernel.txz
	@touch $@

build: download ${WRKDIR}/.build_done
${WRKDIR}/.build_done:
	@make -C mfsbsd iso BASE=${BASE} WRKDIR=${WRKDIR} PACKAGESDIR=${PACKAGESDIR} PKG_STATIC=${PKG_STATIC}
	@touch $@

clean:
	@chflags -R noschg ${WRKDIR}
	@rm -fr ${WRKDIR}
	@make -C mfsbsd clean
