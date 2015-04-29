#ifndef SINGLETONBASE_H
#define SINGLETONBASE_H

#include <QMutex>
#include <QScopedPointer>

#define DECLARE_SINGLETON(Class) \
Q_DISABLE_COPY(Class) \
public: \
    static Class* Instance() \
    { \
        static QMutex mutex; \
        static QScopedPointer<Class> inst; \
        if (!inst) { \
            mutex.lock(); \
            if (!inst) inst.reset(new Class); \
            mutex.unlock(); \
        } \
        return inst.data(); \
    }

#endif // SINGLETONBASE_H
