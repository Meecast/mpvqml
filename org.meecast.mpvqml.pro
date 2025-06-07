TARGET = harbour-mpvqml

QT += qml

CONFIG += \
    sailfishapp
    dbus \

PKGCONFIG += \
           dbus-1 \

QT += \
    dbus

SOURCES += \
    src/main.cpp \
    src/settings.cpp \
    src/dbusadaptor.cpp \
    src/volume/pulseaudiocontrol.cpp \

HEADERS += \
    src/main.h \
    src/settings.h \
    src/dbusadaptor.h \
    src/volume/pulseaudiocontrol.h \

DISTFILES += \
    rpm/harbour-mpvqml \

#QMAKE_CXXFLAGS += "-fPIC"    
#QMAKE_LFLAGS += "-no-pie"
SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += \
    sailfishapp_i18n_idbased \
    sailfishapp_i18n \

TRANSLATIONS = \
   translations/harbour-mpvqml-ru.ts \

PKGCONFIG += mpv
