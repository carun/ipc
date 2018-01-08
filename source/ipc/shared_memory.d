module ipc.shared_memory;

import core.sys.posix.sys.mman;
import core.sys.posix.fcntl;
import core.sys.posix.unistd;
public import ipc.creation_tags;

import core.stdc.errno;

struct SharedMemory
{
    @disable this(this);
    int _handle = -1;

    this(in string name, CreateMode createMode, RWMode rwMode)
    out
    {
        assert(_handle >= 0);
    }
    do
    {
        int oflag = 0;
        if (rwMode == RWMode.read_only)
            oflag |= RWMode.read_only;
        else if (rwMode == RWMode.read_write)
            oflag |= RWMode.read_write;

        enum unixPerm = UnixPermission.default_;
        import std.string: toStringz;
        auto p = toStringz(name);
        switch(createMode)
        {
        case CreateMode.open_only:
            {
                _handle = shm_open(p, oflag, unixPerm);
                validateHandle(_handle, __MODULE__, __LINE__);
                break;
            }
        case CreateMode.create_only:
            {
                oflag |= (O_CREAT | O_EXCL);
                _handle = shm_open(p, oflag, unixPerm);
                if (_handle >= 0)
                    fchmod(_handle, UnixPermission.default_);
                else
                    validateHandle(_handle, __MODULE__, __LINE__);
                break;
            }
        case CreateMode.open_or_create:
            {
                // We need a create/open loop to change permissions correctly using fchmod, since
                // with "O_CREAT" only we don't know if we've created or opened the shm.
                while(1)
                {
                    // Try to create shared memory
                    _handle = shm_open(p, oflag | (O_CREAT | O_EXCL), unixPerm);
                    validateHandle(_handle, __MODULE__, __LINE__);
                    // If successful change real permissions
                    if (_handle >= 0)
                    {
                         fchmod(_handle, unixPerm);
                    }
                    // If already exists, try to open
                    else if(errno == EEXIST)
                    {
                        _handle = shm_open(p, oflag, unixPerm);
                        // If open fails and errno tells the file does not exist
                        // (shm was removed between creation and opening tries), just retry
                        if (_handle < 0 && errno == ENOENT)
                        {
                            continue;
                        }
                    }
                    // Exit retries
                    break;
                }
                break;
            }
        default:
            assert(0, "Unexpected CreateMode");
        }
    }

    void resize(ulong length)
    {
        int rc = ftruncate(_handle, length);
        validateReturnCode(rc, __MODULE__, __LINE__);
    }

    static bool remove(in string name)
    {
        import std.string: toStringz;
        auto p = toStringz(name);
        return (shm_unlink(p) == 0);
    }
}

private void validateReturnCode(int rc, string module_, int line)
{
    import std.stdio: writeln;
    import core.stdc.string: strerror;
    import std.string: fromStringz;

    if (rc != 0)
        writeln(module_, ":", line, " ERROR: ", fromStringz(strerror(errno)));
}

private void validateHandle(int handle, string module_, int line)
{
    import std.stdio: writeln;
    import core.stdc.string: strerror;
    import std.string: fromStringz;

    if (handle == -1)
        writeln(module_, ":", line, " ERROR: ", fromStringz(strerror(errno)));
}

struct RemoveSharedMemoryOnDestroy
{
    string _name;

    this(string name)
    {
        _name = name;
    }

    ~this()
    {
        SharedMemory.remove(_name);
    }
}

struct MappedRegion
{
    void* _base;
    ulong _size;

    this(in ref SharedMemory shm, RWMode mode, ulong size = 0, int mapOptions = -1)
    {
        //Create new mapping
        int prot = 0;
        int flags = (mapOptions == -1) ? 0 : mapOptions;

        switch(mode)
        {
        case RWMode.read_only:
            prot  |= PROT_READ;
            flags |= MAP_SHARED;
            break;

        case RWMode.read_private:
            prot  |= (PROT_READ);
            flags |= MAP_PRIVATE;
            break;

        case RWMode.read_write:
            prot  |= (PROT_WRITE | PROT_READ);
            flags |= MAP_SHARED;
            break;

        case RWMode.copy_on_write:
            prot  |= (PROT_WRITE | PROT_READ);
            flags |= MAP_PRIVATE;
            break;

        default:
            assert(0);
        }
        if (size == 0)
        {
            stat_t buf;
            fstat(shm._handle, &buf);
            size = buf.st_size;
        }
        _base = mmap(null, size, prot, flags, shm._handle, 0);
        if (_base == MAP_FAILED)
        {
            assert(0);
        }
        _size = size;
    }

    ~this()
    {
        munmap(_base, _size);
    }

    auto getAddress()
    {
        return _base;
    }
}
