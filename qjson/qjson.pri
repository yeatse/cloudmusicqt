INCLUDEPATH += $$PWD
DEPENDPATH  += $$PWD

PRIVATE_HEADERS += \
    $$PWD/json_parser.hh \
    $$PWD/json_scanner.h \
    $$PWD/location.hh \
    $$PWD/parser_p.h \
    $$PWD/position.hh \
    $$PWD/qjson_debug.h \
    $$PWD/stack.hh

PUBLIC_HEADERS += \
    $$PWD/parser.h \
    $$PWD/parserrunnable.h \
    $$PWD/qobjecthelper.h \
    $$PWD/serializer.h \
    $$PWD/serializerrunnable.h \
    $$PWD/qjson_export.h

HEADERS += $$PRIVATE_HEADERS $$PUBLIC_HEADERS

SOURCES += \
    $$PWD/json_parser.cc \
    $$PWD/json_scanner.cpp \
    $$PWD/parser.cpp \
    $$PWD/parserrunnable.cpp \
    $$PWD/qobjecthelper.cpp \
    $$PWD/serializer.cpp \
    $$PWD/serializerrunnable.cpp
