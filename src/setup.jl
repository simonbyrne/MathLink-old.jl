
mathematica_home_path = get(ENV, "MATHEMATICA_HOME", "")
mathematica_exec_path = get(ENV, "MATHEMATICA_EXEC", "")
mathlink_lib_path = get(ENV, "MATHLINK_LIB", "")

if mathematica_home_path == ""
    if OS_NAME == :Darwin
        mathematica_home_path = "/Applications/Mathematica.app"
        # TODO: check for other OS paths
    end
end

if mathematica_exec_path == ""
    if OS_NAME == :Darwin
        mathematica_exec_path = joinpath(mathematica_home_path,"Contents/MacOS/MathKernel")
    end
end

if mathlink_lib_path == ""
    if OS_NAME == :Darwin
        mathlink_lib_path = joinpath(mathematica_home_path,"SystemFiles/Links/MathLink/DeveloperKit/MacOSX-x86-64/CompilerAdditions/mathlink.framework/mathlink")
    end
end


mathlink_lib_ptr = dlopen(mathlink_lib_path)

mathlink_fn(name) = dlsym(mathlink_lib_ptr, name)