module ipc.sync.posix.mutex;

import core.sys.posix.pthread;

struct Mutex
{
    @disable this(this);

    this(bool processShared, bool recursive)
    {
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);

        if (processShared)
            pthread_mutexattr_setpshared(&attr, PTHREAD_PROCESS_SHARED);
        if (recursive)
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);

        pthread_mutex_init(&_mutex, &attr);
        pthread_mutexattr_destroy(&attr);
    }

    ~this()
    {
        int rc = pthread_mutex_destroy(&_mutex);
        assert(rc == 0);
    }

    void lock()
    {
        int rc = pthread_mutex_lock(&_mutex);
        assert(rc == 0);
    }

    void unlock()
    {
        int rc = pthread_mutex_unlock(&_mutex);
        assert(rc == 0);
    }

    alias _mutex this;

    pthread_mutex_t _mutex;
}
