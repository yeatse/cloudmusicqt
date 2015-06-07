TEMPLATE = app
TARGET = cloudmusicqt

VERSION = 0.9.4
DEFINES += VER=\\\"$$VERSION\\\"

QT += network webkit sql

CONFIG += mobility
MOBILITY += multimedia systeminfo

HEADERS += \
    qmlapi.h \
    networkaccessmanagerfactory.h \
    singletonbase.h \
    userconfig.h \
    musicfetcher.h \
    blurreditem.h \
    musiccollector.h \
    musicdownloader.h \
    musicdownloaddatabase.h \
    musicdownloadmodel.h \
    lyricloader.h

SOURCES += main.cpp \
    qmlapi.cpp \
    networkaccessmanagerfactory.cpp \
    userconfig.cpp \
    musicfetcher.cpp \
    blurreditem.cpp \
    musiccollector.cpp \
    musicdownloader.cpp \
    musicdownloaddatabase.cpp \
    musicdownloadmodel.cpp \
    lyricloader.cpp

include(qjson/qjson.pri)
DEFINES += QJSON_MAKEDLL

TRANSLATIONS += i18n/cloudmusicqt_zh.ts

folder_symbian3.source = qml/cloudmusicqt
folder_symbian3.target = qml

folder_js.source = qml/js
folder_js.target = qml

simulator {
    DEPLOYMENTFOLDERS = folder_symbian3 folder_js
}

symbian {
    DEPLOYMENTFOLDERS = folder_symbian3 folder_js

    CONFIG += qt-components localize_deployment

    TARGET.UID3 = 0x2006DFF5

    TARGET.CAPABILITY += \
        NetworkServices \
        ReadUserData \
        WriteUserData \
        ReadDeviceData \
        WriteDeviceData \
        SwEvent

    TARGET.EPOCHEAPSIZE = 0x40000 0x4000000

    LIBS += -lavkon -leikcore -lgslauncher

    vendorinfo = "%{\"Yeatse\"}" ":\"Yeatse\""
    my_deployment.pkg_prerules += vendorinfo
    DEPLOYMENT += my_deployment

    # Symbian have a different syntax
    DEFINES -= VER=\\\"$$VERSION\\\"
    DEFINES += VER=\"$$VERSION\"

    MMP_RULES += "EPOCPROCESSPRIORITY windowserver"
}

# Please do not modify the following two lines. Required for deployment.
include(qmlapplicationviewer/qmlapplicationviewer.pri)
qtcAddDeployment()
