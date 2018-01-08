void main(string[] args)
{
    import std.stdio: writefln;
    import ipc.sync.named_condition;
    import ipc.shared_memory: SharedMemory;

    if (args.length != 2)
    {
        writefln("Usage: %s <shm-name>", args[0]);
        return;
    }
    // remove if the shared memory region already exists
    SharedMemory.remove(args[1]);
    {
        auto condvar = NamedCondition(args[1], CreateMode.create_only);
        writefln("Waiting for notification on %s.", args[1]);
        condvar.wait();
        writefln("Notification received on %s.", args[1]);
    }
}
