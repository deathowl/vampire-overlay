# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils git-r3 flag-o-matic gnome2-utils

DESCRIPTION="Nintendo 3DS Emulator"
HOMEPAGE="https://citra-emu.org/"
EGIT_REPO_URI="https://github.com/citra-emu/citra.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""

#This emulator sure likes its bundles.
#The source tree has an enormous externals directory with tons of libraries in it.
#This looks like a nightmare to a maintainer at first glance. I just gave up at first, honestly.
#However, what you may not realise is that a lot (but not all) of those libraries are actually 
#header-only, so there's not much point in bothering to make them into a dependency anyway.
#It is still kind of a nightmare, though.

#As of the time of writing (2019-01-02) citra depends on:
#Header-only libraries:
#catch,glad(generated by upstream),open-source archives(generated by upstream),microprofile,
#nihstro,xbyak,cppzmq(scripting),cpp-jwt(network),json(network),httplib(network)
#Normal libraries:
#boost(subset),cryptopp,cubeb(optional),dynarmic,enet,libfmt,discord-rpc(optional),
#inih,soundtouch(subset),zeromq(scripting),libressl(network),lurlparser(network)
#Irrelevant directories:
#getopt(for mingw compilation only),cmake-modules(just some cmake modules)

#Ebuilds missing for normal libraries from the main tree:
#cubeb,dynarmic,discord-rpc,inih,lurlparser
#libressl is likely to be not present too

#I don't want to bother with this, so I just use static everywhere except boost. Maybe later.

#dev-libs/crypto++ #net-libs/enet #dev-libs/libfmt #media-libs/libsoundtouch 
#scripting? ( #	net-libs/zeromq #)

#EGIT_SUBMODULES=( '*' '-externals/*' 'externals/catch' 'externals/nihstro' 'externals/xbyak'
#'externals/cpp-jwt' 'externals/cppzmq' 'externals/libressl' )
EGIT_SUBMODULES=( '*' '-externals/*' 'externals/libzmq' 'externals/cppzmq' )

IUSE="doc sdl2 qt5 system-boost clang i18n scripting web"

REQUIRED_USE="|| ( sdl2 qt5 )"
RDEPEND="virtual/opengl
	system-boost? ( >=dev-libs/boost-1.66.0:= )
	sdl2? ( media-libs/libsdl2 )
	qt5? (
		dev-qt/qtcore:5
		dev-qt/qtgui:5
		dev-qt/qtopengl:5
		dev-qt/qtwidgets:5
		dev-qt/qtmultimedia:5
		i18n? ( dev-qt/linguist-tools )
	)"
DEPEND="${DEPEND}
	>=dev-util/cmake-3.6
	doc? ( >=app-doc/doxygen-1.8.8[dot] )
	!clang? ( >=sys-devel/gcc-5 )
	clang? (
		>=sys-devel/clang-3.8
		>=sys-libs/libcxx-3.8
	)"

src_prepare() {
	eapply "${FILESDIR}/citra-system-boost.patch"
	cmake-utils_src_prepare
}

src_configure() {
	if use clang; then
		export CC=clang
		export CXX=clang++
		append-cxxflags "-stdlib=libc++" # Upstream requires libcxx when building with clang
	fi

	local mycmakeargs=(
		-DENABLE_QT="$(usex qt5)"
		-DENABLE_SDL2="$(usex sdl2)"
		-DCITRA_USE_BUNDLED_SDL2=OFF
		-DCITRA_USE_BUNDLED_QT=OFF
		-DUSE_SYSTEM_BOOST="$(usex system-boost)"
		-DENABLE_WEB_SERVICE=$(usex web)
		-DENABLE_SCRIPTING=$(usex scripting)
	)
	append-cxxflags "-fno-new-ttp-matching"
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
	if use doc; then
		doxygen || die
	fi
}

src_install() {
	cmake-utils_src_install
	dodoc README.md CONTRIBUTING.md
	use doc && dodoc -r doc-build/html
}

pkg_postinst() {
	if use i18n; then
		elog "Translations only work with the Qt5 interface"
	fi
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
	gnome2_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
	gnome2_icon_cache_update
}
