TARGET = harbour-mpvqml

QT += qml

CONFIG += \
    sailfishapp

PKGCONFIG += \

SOURCES += \
    src/main.cpp \
    src/settings.cpp \

HEADERS += \
    src/main.h \
    src/settings.h \

DISTFILES += \
    rpm/harbour-mpvqml \

#QMAKE_CXXFLAGS += "-fPIC"    
#QMAKE_LFLAGS += "-no-pie"
SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += sailfishapp_i18n

PKGCONFIG += mpv
