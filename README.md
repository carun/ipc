# Introduction #

This is just a simple project to build an interprocess communications library for DLang similar to what [Boost.Interprocess](http://boost.org/libs/interprocess) offers for C++.

### Setup ###

* Download and install DMD or/and LDC2 compilers
* Download and install DUB.

### Example ###

* Run `dub build`
* Run `dub build -c example-process1`
* Run `dub build -c example-process2`
* Run `./process1 test` in one terminal and `./process2 test` in the other terminal.
