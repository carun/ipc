module ipc.sync.posix.condition;

import core.sys.posix.pthread;
import ipc.sync.posix.mutex;

struct Condition
{
    @disable this(this);

    this(bool processShared)
    {
        pthread_condattr_t attr;
        pthread_condattr_init(&attr);
        if (processShared)
            pthread_condattr_setpshared(&attr, PTHREAD_PROCESS_SHARED);
        pthread_cond_init(&_condition, &attr);
        pthread_condattr_destroy(&attr);
    }

    ~this()
    {
        int rc = pthread_cond_destroy(&_condition);
        assert(rc == 0);
    }

    void notifyOne()
    {
        pthread_cond_signal(&_condition);
    }

    void notifyAll()
    {
        pthread_cond_broadcast(&_condition);
    }

    void wait(L)(ref L lock)
        if (!is(L == Mutex))
    {
        wait(lock.mutex());
    }

    void wait(ref Mutex mutex)
    {
        pthread_cond_wait(&_condition, &mutex._mutex);
    }

    pthread_cond_t _condition;
}
