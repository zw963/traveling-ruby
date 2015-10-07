#!/bin/bash
set -e
source /tr_build/functions.sh

FFI_VERSION=3.2.1
MYSQL_LIB_VERSION=6.1.5
POSTGRESQL_VERSION=9.3.5
ICU_VERSION=54.1
ICU_DIR_VERSION=54_1
LIBSSH2_VERSION=1.4.3

# TODO: set march=i586?
MAKE_CONCURRENCY=2
if [[ "$ARCHITECTURE" = x86_64 ]]; then
	ARCHITECTURE_BITS=64
else
	ARCHITECTURE_BITS=32
fi
export PATH=/tr_runtime/bin:$PATH


### Install base software

echo $ARCHITECTURE > /ARCHITECTURE

if [[ "$ARCHITECTURE" = x86_64 ]]; then
	run curl -OL --fail https://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
else
	run curl -OL --fail https://dl.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
fi
run rpm -Uvh epel-release-5-4.noarch.rpm
run rm -f epel-release-5-4.noarch.rpm
run yum install -y wget sudo readline-devel ncurses-devel
run /hbb/bin/pip install s3cmd
run mkdir -p /ccache
run create_user app "App" 1000


### libffi

header "Installing libffi"
LIBFFI_FILE=`echo /tr_runtime/lib*/libffi.so.6`
if [[ ! -e "$LIBFFI_FILE" ]]; then
	download_and_extract libffi-$FFI_VERSION.tar.gz \
		libffi-$FFI_VERSION \
		ftp://sourceware.org/pub/libffi/libffi-$FFI_VERSION.tar.gz

	(
		source /hbb_shlib/activate
		export CFLAGS="$SHLIB_CFLAGS"
		export CXXFLAGS="$SHLIB_CXXFLAGS"
		export LDLAGS="$SHLIB_LDFLAGS"
		run ./configure --prefix=/tr_runtime \
			--enable-shared --disable-static \
			--enable-portable-binary
		run make -j$MAKE_CONCURRENCY
		run make install-strip
		if [[ "$ARCHITECTURE" = x86_64 ]]; then
			run strip --strip-debug /tr_runtime/lib64/libffi.so.6
		else
			run strip --strip-debug /tr_runtime/lib/libffi.so.6
		fi
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf libffi-$FFI_VERSION
fi


### MySQL

header "Installing MySQL"
if [[ ! -e /tr_runtime/lib/libmysqlclient.a ]]; then
	download_and_extract mysql-connector-c-$MYSQL_LIB_VERSION-src.tar.gz \
		mysql-connector-c-$MYSQL_LIB_VERSION-src \
		http://dev.mysql.com/get/Downloads/Connector-C/mysql-connector-c-$MYSQL_LIB_VERSION-src.tar.gz

	(
		source /hbb_shlib/activate
		run cmake -DCMAKE_INSTALL_PREFIX=/tr_runtime \
			-DCMAKE_C_FLAGS="$SHLIB_CFLAGS" \
			-DCMAKE_CXX_FLAGS="$SHLIB_CXXFLAGS" \
			-DCMAKE_LDFLAGS="$SHLIB_LDFLAGS" \
			-DDISABLE_SHARED=1 \
			.
		run make -j$MAKE_CONCURRENCY libmysql
		run make -C libmysql install
		run make -C include install
		run make -C scripts install
		run sed -i "s|^ldflags=''|ldflags='-lstdc++'|"  /tr_runtime/bin/mysql_config
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf mysql-connector-c-$MYSQL_LIB_VERSION-src
fi


### PostgreSQL

header "Installing PostgreSQL"
if [[ ! -e /tr_runtime/lib/libpq.a ]]; then
	download_and_extract postgresql-$POSTGRESQL_VERSION.tar.bz2 \
		postgresql-$POSTGRESQL_VERSION \
		http://ftp.postgresql.org/pub/source/v9.3.5/postgresql-$POSTGRESQL_VERSION.tar.bz2

	(
		source /hbb_shlib/activate
		export CFLAGS="$SHLIB_CFLAGS"
		export CXXFLAGS="$SHLIB_CXXFLAGS"
		export LDLAGS="$SHLIB_LDFLAGS"
		run ./configure --prefix=/tr_runtime
		run make -j$MAKE_CONCURRENCY -C src/common
		run make -j$MAKE_CONCURRENCY -C src/backend
		run make -j$MAKE_CONCURRENCY -C src/interfaces/libpq
		run make -C src/interfaces/libpq install-strip
		run make -j$MAKE_CONCURRENCY -C src/include
		run make -C src/include install-strip
		run make -j$MAKE_CONCURRENCY -C src/bin/pg_config
		run make -C src/bin/pg_config install-strip
		run rm /tr_runtime/lib/libpq.so*
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf postgresql-$POSTGRESQL_VERSION
fi


### ICU

header "Installing ICU"
if [[ ! -e /tr_runtime/lib/libicudata.a ]]; then
	download_and_extract icu4c-$ICU_DIR_VERSION-src.tgz \
		icu/source \
		http://download.icu-project.org/files/icu4c/$ICU_VERSION/icu4c-$ICU_DIR_VERSION-src.tgz

	(
		source /hbb_exe/activate
		export CFLAGS="$STATICLIB_CFLAGS -DU_CHARSET_IS_UTF8=1 -DU_USING_ICU_NAMESPACE=0"
		export CXXFLAGS="$STATICLIB_CXXFLAGS -DU_CHARSET_IS_UTF8=1 -DU_USING_ICU_NAMESPACE=0"
		unset LDFLAGS
		run ./configure --prefix=/tr_runtime --disable-samples --disable-tests \
			--enable-static --disable-shared --with-library-bits=$ARCHITECTURE_BITS
		run make -j$MAKE_CONCURRENCY VERBOSE=1
		run make install -j$MAKE_CONCURRENCY
		run strip --strip-debug /tr_runtime/lib/libicu*.a
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf icu
fi


### libssh2

header "Installing libssh2"
if [[ ! -e /tr_runtime/lib/libssh2.a ]]; then
	download_and_extract libssh2-$LIBSSH2_VERSION.tar.gz \
		libssh2-$LIBSSH2_VERSION \
		http://www.libssh2.org/download/libssh2-$LIBSSH2_VERSION.tar.gz

	(
		source /hbb_exe/activate
		export CFLAGS="$STATICLIB_CFLAGS"
		export CXXFLAGS="$STATICLIB_CXXFLAGS"
		unset LDFLAGS
		run ./configure --prefix=/tr_runtime --enable-static --disable-shared \
			--with-openssl --with-libz --disable-examples-build --disable-debug
		run make -j$CONCURRENCY
		run make install-strip -j$CONCURRENCY
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf libssh2-$LIBSSH2_VERSION
fi


### Cleanup

rm -rf /tr_build /tmp/*
yum clean all
