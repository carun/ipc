module ipc.creation_tags;

import core.sys.posix.fcntl;

enum CreateMode
{
    create_only,
    open_only,
    open_or_create
}

enum RWMode
{
    read_only = O_RDONLY,
    read_write = O_RDWR,
    copy_on_write,
    read_private,
    invalid = 0xffff,
}

enum UnixPermission
{
     default_ = 420, // equivalent of 0644
}
