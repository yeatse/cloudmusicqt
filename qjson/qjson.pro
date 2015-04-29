TEMPLATE = lib
TARGET = qjson
QT -= gui

#VERSION = 0.8.1

DEFINES += QJSON_MAKEDLL

include(qjson.pri)

unix:!symbian {
    headers.path=$$PREFIX/include/qjson
    headers.files=$$HEADERS
    target.path=$$PREFIX/lib/$${LIB_ARCH}
    INSTALLS += headers target
    OBJECTS_DIR=.obj
    MOC_DIR=.moc
}

win32 {
    headers.path=$$PREFIX/include/qjson
    headers.files=$$HEADERS
    target.path=$$PREFIX/lib
    INSTALLS += headers target
}

symbian {
    CONFIG += staticlib debug_and_release epocallowdlldata

    #Export headers to SDK Epoc32/include directory
    exportheaders.sources = $$PUBLIC_HEADERS
    exportheaders.path = qjson
    for(header, exportheaders.sources) {
        BLD_INF_RULES.prj_exports += "$$header $$exportheaders.path/$$basename(header)"
    }
}
