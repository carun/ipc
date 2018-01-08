module ipc.sync.named_mutex;

public import ipc.creation_tags;
import ipc.sync.posix.mutex;
import ipc.shared_memory;

struct NamedMutex
{
    @disable this(this);
    /// Declaration order matters here as the destruction happens in the reverse order of declaration
    SharedMemory _shm;      /// Shared memory object.
    MappedRegion _region;   /// Memory mapped region.
    Mutex* _mutex = null;

    alias _mutex this;

    this(string name, CreateMode createMode)
    {
        auto mutex = Mutex(true, false);

        _shm = SharedMemory(name, createMode, RWMode.read_write);

        if (createMode == CreateMode.create_only)
            _shm.resize(mutex.sizeof);

        _region = MappedRegion(_shm, RWMode.read_write);

        if (createMode == CreateMode.create_only)
        {
            import core.stdc.string: memcpy;
            memcpy(_region.getAddress(), &mutex, mutex.sizeof);
        }
        _mutex = cast(Mutex*) _region.getAddress();
    }
}
