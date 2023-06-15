#!/bin/sh
rm -rf build
mkdir build
cl65 intro.s --verbose --target nes -o build/intro.nes
