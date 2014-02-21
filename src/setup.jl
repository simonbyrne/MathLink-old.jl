# we need 


mathematica_home_path = get(ENV, "MATHEMATICA_HOME", "")
mathematica_exec_path = get(ENV, "MATHEMATICA_EXEC", "")
mathlink_lib_path = get(ENV, "MATHLINK_LIB", "")

@osx_only begin
    if mathematica_home_path == ""    
        mathematica_home_path = "/Applications/Mathematica.app"
    end
    if mathematica_exec_path == ""
        mathematica_exec_path = joinpath(mathematica_home_path,"Contents/MacOS/MathKernel")
    end
    if mathlink_lib_path == ""
        mathlink_lib_path = joinpath(mathematica_home_path,"SystemFiles/Links/MathLink/DeveloperKit/MacOSX-x86-64/CompilerAdditions/mathlink.framework")
    end
end


push!(DL_LOAD_PATH, mathlink_lib_path)
l = dlopen_e("mathlink")
if l != C_NULL
    dlclose(l)
else
    error("could not find mathlink library")
end
