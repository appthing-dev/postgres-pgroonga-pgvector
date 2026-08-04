# syntax=docker/dockerfile:1
# 定制 PostgreSQL 镜像: 官方 postgres:18.4-trixie + pgroonga(全文检索) + pgvector(向量检索)
# 合并自:
#   - pgroonga/docker  debian/18/Dockerfile (https://github.com/pgroonga/docker)
#   - pgvector/pgvector Dockerfile (https://github.com/pgvector/pgvector)
# 定制: 基础镜像 postgres:18-trixie -> postgres:18.4-trixie, PG_MAJOR=17 -> 18, bookworm -> trixie
# 版本通过 build-arg 传入(CI 自动检查上游后覆盖), 默认值与 versions.txt 保持一致
# 注意: 修改此文件会触发 GitHub Actions 重新构建并推送镜像

ARG PG_VERSION=18.4
ARG PG_CODENAME=trixie
ARG PG_MAJOR=18
ARG PGROONGA_VERSION=4.0.8-1
ARG PGVECTOR_VERSION=0.8.6

FROM postgres:${PG_VERSION}-${PG_CODENAME}

ARG PG_MAJOR
ARG PGROONGA_VERSION
ARG PGVECTOR_VERSION

# ===================== pgroonga =====================
# 官方源: https://github.com/pgroonga/docker/blob/main/debian/18/Dockerfile
RUN \
  apt update && \
  apt install -y -V lsb-release wget && \
  wget https://packages.apache.org/artifactory/arrow/debian/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb && \
  apt install -y -V ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb && \
  rm apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb && \
  wget https://packages.groonga.org/debian/groonga-apt-source-latest-$(lsb_release --codename --short).deb && \
  apt install -y -V ./groonga-apt-source-latest-$(lsb_release --codename --short).deb && \
  rm groonga-apt-source-latest-$(lsb_release --codename --short).deb && \
  apt update && \
  apt install -y -V \
    postgresql-${PG_MAJOR}-pgdg-pgroonga=${PGROONGA_VERSION} \
    groonga-normalizer-mysql \
    groonga-plugin-language-model \
    groonga-token-filter-stem \
    groonga-tokenizer-mecab && \
  apt clean && \
  rm -rf /var/lib/apt/lists/*

# ===================== pgvector =====================
# 官方源: https://github.com/pgvector/pgvector/blob/master/Dockerfile
ADD https://github.com/pgvector/pgvector.git#v${PGVECTOR_VERSION} /tmp/pgvector

RUN apt-get update && \
	apt-mark hold locales && \
	apt-get install -y --no-install-recommends build-essential postgresql-server-dev-${PG_MAJOR} && \
	cd /tmp/pgvector && \
	make clean && \
	make OPTFLAGS="" && \
	make install && \
	mkdir /usr/share/doc/pgvector && \
	cp LICENSE README.md /usr/share/doc/pgvector && \
	rm -r /tmp/pgvector && \
	apt-get remove -y build-essential postgresql-server-dev-${PG_MAJOR} && \
	apt-get autoremove -y && \
	apt-mark unhold locales && \
	rm -rf /var/lib/apt/lists/*
