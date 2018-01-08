module ipc.sync.named_condition;

public import ipc.creation_tags;
import ipc.sync.posix.mutex;
import ipc.sync.posix.condition;
import ipc.shared_memory;

struct NamedCondition
{
    @disable this(this);
    /// Declaration order matters here as the destruction happens in the reverse order of declaration
    SharedMemory _shm;      /// Shared memory object.
    MappedRegion _region;   /// Memory mapped region.

    NamedCondvarMemoryLayout* _layout = null;

    alias _layout this;

    private struct NamedCondvarMemoryLayout
    {
        Mutex _mutex;
        Condition _condition;

        void notifyOne()
        {
            _condition.notifyOne();
        }

        void notifyAll()
        {
            _condition.notifyAll();
        }

        void wait()
        {
            _condition.wait(_mutex);
        }
    }

    this(string name, CreateMode createMode)
    {
        NamedCondvarMemoryLayout ipcCondition;
        ipcCondition._mutex = Mutex(true, false);
        ipcCondition._condition = Condition(true);

        _shm = SharedMemory(name, createMode, RWMode.read_write);

        if (createMode == CreateMode.create_only)
            _shm.resize(ipcCondition.sizeof);

        _region = MappedRegion(_shm, RWMode.read_write);

        if (createMode == CreateMode.create_only)
        {
            import core.stdc.string: memcpy;
            auto addr = _region.getAddress();
            memcpy(addr, &ipcCondition, ipcCondition.sizeof);
        }

        _layout = cast(NamedCondvarMemoryLayout*) _region.getAddress();
    }
}
