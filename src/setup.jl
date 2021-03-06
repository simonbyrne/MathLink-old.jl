macro getoption(name,default)
    quote
        if isdefined(Main,$(QuoteNode(name)))  
            const $(esc(name)) = Main.$name
        else
            const $(esc(name)) = $default
        end
    end
end        


@osx_only begin
    @getoption MATHEMATICA_HOME "/Applications/Mathematica.app"
    @getoption MATHEMATICA_EXEC joinpath(MATHEMATICA_HOME,"Contents/MacOS/MathKernel")
    @getoption MATHLINK_LIB joinpath(MATHEMATICA_HOME,"SystemFiles/Links/MathLink/DeveloperKit/MacOSX-x86-64/CompilerAdditions/mathlink.framework/mathlink")
end

@linux_only begin
    @getoption MATHEMATICA_HOME "/usr/local/Wolfram/Mathematica"
    @getoption MATHEMATICA_EXEC "math"
    @getoption MATHLINK_LIB if WORD_SIZE == 32 
        joinpath(MATHEMATICA_HOME,"SystemFiles/Links/MathLink/DeveloperKit/linux/CompilerAdditions/libML32i3.so")
    else
        joinpath(MATHEMATICA_HOME,"SystemFiles/Links/MathLink/DeveloperKit/linux-x86-64/CompilerAdditions/libML64i3.so")
    end
end


l = dlopen_e(MATHLINK_LIB)
if l != C_NULL
    dlclose(l)
else
    error("Could not find MathLink library: set either MATHEMATICA_HOME or MATHLINK_LIB before loading package.")
end
