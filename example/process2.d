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
    {
        auto condvar = NamedCondition(args[1], CreateMode.open_only);
        writefln("Notifying %s.", args[1]);
        condvar.notifyOne();
    }
}
