Name:       sailfish-settings-accounts-extensions-telegram
Summary:    Settings plugin for Telegram accounts management
Version:    0.2.0
Release:    1
Group:      System/GUI/Other
License:    GPLv2+
URL:        https://github.com/TelepathyIM/%{name}
Source0:    https://github.com/TelepathyIM/%{name}/archive/%{name}-%{version}.tar.bz2

Requires:   telegram-qt-qt5-declarative >= 0.2.0
Requires:   telepathy-morse >= 0.2.0
Requires:   jolla-settings
Requires:   jolla-settings-system >= 0.0.43
Requires:   nemo-qml-plugin-systemsettings
Requires:   sailfishsilica-qt5 >= 0.22.10
Requires:   sailfish-components-contacts-qt5 >= 0.1.7
Requires:   sailfish-components-accounts-qt5 >= 0.1.15
BuildRequires: cmake >= 3.2

%description
Settings plugin for Telegram accounts management.

%prep
%setup -q -n %{name}-%{version}

%build
%cmake \
    .

%__make %{?_smp_mflags}

%install
%make_install

%define _provider_name telegram

%files
%{_datadir}/accounts/providers/%{_provider_name}.provider
%{_datadir}/accounts/services/%{_provider_name}.service
%{_datadir}/accounts/ui/%{_provider_name}
%{_datadir}/accounts/ui/%{_provider_name}.qml
%{_datadir}/accounts/ui/%{_provider_name}-settings.qml
%{_datadir}/accounts/ui/%{_provider_name}-update.qml
