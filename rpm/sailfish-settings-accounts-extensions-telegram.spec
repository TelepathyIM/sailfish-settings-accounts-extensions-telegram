Name:       sailfish-settings-accounts-extensions-telegram
Summary:    Settings plugin for Telegram accounts management
Version:    0.2.0
Release:    1
Group:      System/GUI/Other
License:    GPLv2+
URL:        https://github.com/Kaffeine/%{name}
Source0:    https://github.com/Kaffeine/%{name}/archive/%{name}-%{version}.tar.bz2
Requires(post): /sbin/ldconfig
Requires(postun): /sbin/ldconfig

Requires:   telegram-qt-qt5-declarative >= 0.2.0
Requires:   telepathy-morse >= 0.2.0
Requires:   jolla-settings
Requires:   jolla-settings-system >= 0.0.43
Requires:   nemo-qml-plugin-systemsettings
Requires:   sailfishsilica-qt5 >= 0.22.10
Requires:   sailfish-components-contacts-qt5 >= 0.1.7
Requires:   sailfish-components-accounts-qt5 >= 0.1.15
BuildRequires: cmake >= 2.8

%description
Settings plugin for Telegram accounts management.

%prep
%setup -q -n %{name}-%{version}

%build
cmake . -DCMAKE_INSTALL_PREFIX=%{_prefix} \
        -DCMAKE_INSTALL_DATADIR=%{_datadir}

make %{?jobs:-j%jobs}

%install
rm -rf %{buildroot}
%make_install

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig

%define _provider_name telegram

%files
%{_datadir}/accounts/providers/%{_provider_name}.provider
%{_datadir}/accounts/services/%{_provider_name}.service
%{_datadir}/accounts/ui/%{_provider_name}
%{_datadir}/accounts/ui/%{_provider_name}.qml
%{_datadir}/accounts/ui/%{_provider_name}-settings.qml
%{_datadir}/accounts/ui/%{_provider_name}-update.qml
