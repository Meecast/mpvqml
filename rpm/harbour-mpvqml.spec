%define __requires_exclude ^libdbus-1|libQt5Quick.so.5.*$
Name:       harbour-mpvqml
Summary:    Mpv with Qml
Version:    0.4
Release:    3
License:    GPL-2.0
URL:        https://meecast.org
Source0:    %{name}-%{version}.tar.bz2

Requires:   sailfishsilica-qt5 >= 0.10.9
BuildRequires:  pkgconfig(sailfishapp)
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5DBus)

%description
Qml frontend for mpv for SailfishOS

%prep
%autosetup

%build
%qmake5
sed -i "s/ -pie//" Makefile
%make_build

%install
%make_install


%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%defattr(644,root,root,-)
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png

%changelog
* Tue May 13 2025 Vlad Vasilyeu <vasvlad@gmail.com> - 0.4-1
- Added dbus to start video playback in mpvqml using FileBrowser on the device
- Added the ability to launch the application (org.meecast.mpvqml) with a file name or URL as an argument to play it immediately.
- Added audio's button for changing it
- Fixed font color when using light theme on About page #1
* Fri May 09 2025 Vlad Vasilyeu <vasvlad@gmail.com> - 0.3-1
- Fixed bug with video file selection in Aurora4 in landscape mode
- Fixed prevent blanking screen
- Added About page
- Added information about mpv version and features to About page
- Added subtitle's button for changing it
* Tue Apr 29 2025 Vlad Vasilyeu <vasvlad@gmail.com> - 0.2-1
- Added main view
- Added save position setting
- Added buttons forward and back 10 seconds
- Added URL source for play video


