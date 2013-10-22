# MathLink.jl

MathLink.jl provides an interface to Mathematica from Julia via the MathLink library.

## Requirements

You'll need Mathematica installed (this was tested on version 9, but may work
on earlier versions).

## Set up

At the moment, you need to put the MathLink library in the library path. On OS X, I was able to do this by
```
ln -s /Applications/Mathematica.app/SystemFiles/Links/MathLink/DeveloperKit/MacOSX-x86-64/CompilerAdditions/mathlink.framework/Versions/Current/mathlink /usr/local/lib/mathlink.dylib
```

On OS X, you also need to put the executable in the path
```
ln -s /Applications/Mathematica.app/Contents/MacOS/MathKernel /usr/local/bin/MathKernel
```

## Use
See the examples directory. You may need to modify the `mlopen` call by
replacing `MathKernel` by the mathematica executable.

I do have a vague intention of making this easier to use: if you have any
suggestions, please let me know.
