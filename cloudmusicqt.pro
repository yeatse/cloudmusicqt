TEMPLATE = app
TARGET = cloudmusicqt

VERSION = 1.0.0
DEFINES += VER=\\\"$$VERSION\\\"

QT += network webkit

CONFIG += mobility
MOBILITY += multimedia systeminfo

SOURCES += main.cpp

folder_symbian3.source = qml/cloudmusicqt
folder_symbian3.target = qml

simulator {
    DEPLOYMENTFOLDERS = folder_symbian3
}

symbian {
    DEPLOYMENTFOLDERS = folder_symbian3

    CONFIG += qt-components localize_deployment
    TARGET.UID3 = 0x2006DFF5
    TARGET.CAPABILITY += \
        NetworkServices \
        ReadUserData \
        WriteUserData \
        ReadDeviceData \
        WriteDeviceData
    TARGET.EPOCHEAPSIZE = 0x40000 0x4000000

    LIBS += -lavkon

    vendorinfo = "%{\"Yeatse\"}" ":\"Yeatse\""
    my_deployment.pkg_prerules += vendorinfo
    DEPLOYMENT += my_deployment

    # Symbian have a different syntax
    DEFINES -= VER=\\\"$$VERSION\\\"
    DEFINES += VER=\"$$VERSION\"
}

# Please do not modify the following two lines. Required for deployment.
include(qmlapplicationviewer/qmlapplicationviewer.pri)
qtcAddDeployment()
