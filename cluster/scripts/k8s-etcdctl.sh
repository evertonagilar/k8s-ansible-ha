#!/bin/bash
#
# Instalar o etcdctl
#
#
#######################################################################


echo 'Instalar o etcdctl'

ETCD_VER=v3.4.32
DOWNLOAD_URL=https://github.com/etcd-io/etcd/releases/download

rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz

install /tmp/etcd-download-test/etcdctl /usr/local/bin