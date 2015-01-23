libjpeg-turbo-build-scripts
===========================

Build scripts for producing universal libjpeg-turbo libraries with 64 bit
support targeting iOS.

## Instructions

1. Run the `setup.sh` script to get some dependencies and prep the source tree
   for building.
2. Run `build.sh` to build a universal library for iOS and the simulator.
   Architectures are configured at the top of the build script. By default, it
   will include armv7, armv7s, arm64, i386 (iPhone simulator) and x86_64 (iPhone
   simulator).
