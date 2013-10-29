# MathLink.jl

MathLink.jl provides bindings to the MathLink library, which is an interface for Mathematica. 

## Requirements

You'll need Mathematica installed (this was tested on version 9, but may work on earlier versions).

## Set up

By default, MathLink isn't installed into the library path. MathLink.jl will try to guess the default path (currently OS X only), otherwise you will need to set the environment variable `MATHLINK_LIB` pointing to the shared library. Similarly, `MATHEMATICA_EXEC` should point to the Mathematica executable, typically either `math` or `MathKernel` depending on OS (this isn't strictly required, as it can be specified in the `mlopen` function, but is required for the simple form used in the examples.

## Use

The interface is very similar to the C interface, though takes advantage of multiple dispatch to reduce the number of functions, e.g. various `MLGet...` functions are all handled by `mlget`. Error handling and memory management of arrays is handled automatically. 

Some sample programs are provided in the `examples` directory. For more information on how to use MathLink, I recommend ["A *MathLink* Tutorial"](http://library.wolfram.com/infocenter/Demos/174/), by Todd Gayley: it's a little bit out old (so some of the functions have been deprecated), but the second chapter provides a good overview of the various aspects, such as handling packets and blocking.

I do have a vague intention of making this easier to use: if you have any suggestions, please let me know

## Further reading

* [MathLink documentation](http://reference.wolfram.com/mathematica/tutorial/MathLinkAndExternalProgramCommunicationOverview.html)
* [A *MathLink* tutorial](http://library.wolfram.com/infocenter/Demos/174/)
