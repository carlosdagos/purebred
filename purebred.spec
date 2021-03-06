# generated by cabal-rpm-0.11.2
# https://fedoraproject.org/wiki/Packaging:Haskell

%global pkg_name purebred
%global pkgver %{pkg_name}-%{version}

%bcond_with tests

Name:           %{pkg_name}
Version:        0.1.0.0
Release:        0.20180113%{?dist}
Summary:        An mail user agent built around notmuch

License:        AGPLv3
Url:            https://hackage.haskell.org/package/%{pkg_name}
Source0:        https://hackage.haskell.org/package/%{pkgver}/%{pkgver}.tar.gz

BuildRequires:  ghc-Cabal-devel
BuildRequires:  ghc-rpm-macros
# Begin cabal-rpm deps:
BuildRequires:  chrpath
BuildRequires:  ghc-attoparsec-devel
BuildRequires:  ghc-brick-devel
BuildRequires:  ghc-bytestring-devel
BuildRequires:  ghc-case-insensitive-devel
BuildRequires:  ghc-directory-devel
BuildRequires:  ghc-filepath-devel
BuildRequires:  ghc-lens-devel
BuildRequires:  ghc-mime-mail-devel
BuildRequires:  ghc-mtl-devel
BuildRequires:  ghc-network-devel
BuildRequires:  ghc-notmuch-devel
BuildRequires:  ghc-optparse-applicative-devel
BuildRequires:  ghc-process-devel
BuildRequires:  ghc-purebred-email-devel
BuildRequires:  ghc-text-devel
BuildRequires:  ghc-text-zipper-devel
BuildRequires:  ghc-time-devel
BuildRequires:  ghc-vector-devel
BuildRequires:  ghc-vty-devel
BuildRequires:  ghc-xdg-basedir-devel
%if %{with tests}
BuildRequires:  ghc-ini-devel
BuildRequires:  ghc-quickcheck-instances-devel
BuildRequires:  ghc-regex-posix-devel
BuildRequires:  ghc-tasty-devel
BuildRequires:  ghc-tasty-hunit-devel
BuildRequires:  ghc-tasty-quickcheck-devel
BuildRequires:  ghc-temporary-devel
%endif
Requires: purebred-basic = %{version}-%{release}
Requires: purebred-config = %{version}-%{release}
# End cabal-rpm deps

%description
An mail user agent built around notmuch.


%package -n ghc-%{name}
Summary:        Haskell %{name} library

%description -n ghc-%{name}
This package provides the Haskell %{name} shared library.


%package -n ghc-%{name}-devel
Summary:        Haskell %{name} library development files
Provides:       ghc-%{name}-static = %{version}-%{release}
Requires:       ghc-compiler = %{ghc_version}
Requires(post): ghc-compiler = %{ghc_version}
Requires(postun): ghc-compiler = %{ghc_version}
Requires:       ghc-%{name}%{?_isa} = %{version}-%{release}

%description -n ghc-%{name}-devel
This package provides the Haskell %{name} library development files.

%package basic
Summary: An terminal based mail user agent.

%description basic
An mail user agent built around notmuch.

%package config
Summary: purebred config
Requires: ghc-purebred-devel = %{version}-%{release}

%description config
This package provides configuration files for purebred.


%prep
%setup -q


%build
%ghc_lib_build


%install
%ghc_lib_install
%ghc_fix_rpath %{pkgver}
mv %{buildroot}%{_ghclicensedir}/{,ghc-}%{name}

install -p -m 0644 -D configs/config.hs %{buildroot}%{_datadir}/purebred/config.hs


%check
%cabal_test


%post -n ghc-%{name}-devel
%ghc_pkg_recache


%postun -n ghc-%{name}-devel
%ghc_pkg_recache


%files

%files basic
%license LICENSE
%doc README.md
%{_bindir}/%{name}


%files -n ghc-%{name} -f ghc-%{name}.files
%license LICENSE


%files -n ghc-%{name}-devel -f ghc-%{name}-devel.files
%doc README.md

%files config
%{_datadir}/purebred/config.hs

%changelog
* Thu Dec  7 2017 Fedora Haskell SIG <haskell@lists.fedoraproject.org> - 0.1.0.0-0.20171207
- spec file generated by cabal-rpm-0.11.2
