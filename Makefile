.POSIX:

all: build

.PHONY: all workdir download build clean

MIRROR?=ftp.jp.freebsd.org
ARCH?=amd64
VERSION?=10.1-RELEASE
WORKDIR?=${PWD}/.tmp
DISTDIR?=${WORKDIR}/dist

workdir: ${WORKDIR} ${DISTDIR}
${WORKDIR}:
	@mkdir $@
${DISTDIR}:
	@mkdir $@

download: workdir ${WORKDIR}/.download_done
${WORKDIR}/.download_done:
	@fetch -o ${DISTDIR}/base.txz http://${MIRROR}/pub/FreeBSD/releases/${ARCH}/${VERSION}/base.txz
	@fetch -o ${DISTDIR}/kernel.txz http://${MIRROR}/pub/FreeBSD/releases/${ARCH}/${VERSION}/kernel.txz
	@touch $@

build: download ${WORKDIR}/.build_done
${WORKDIR}/.build_done:
	@make -C mfsbsd BASE=${WORKDIR}/dist PKG_STATIC=/usr/local/sbin/pkg-static iso
	@touch $@

clean:
	@rm -fr ${WORKDIR}
