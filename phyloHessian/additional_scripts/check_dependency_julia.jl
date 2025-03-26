#! /bin/env julia


############################################################
using Pkg

# Function to check if a package is installed
function check_package_installed(pkg_name)
	installed_packages = Vector()
	#installed_packages = keys(Pkg.TOML.parsefile(Pkg.project().path)["deps"])
	redirect_stderr(devnull) do
		installed_packages = keys(Pkg.installed())
	end
	#println(installed_packages)
    return pkg_name in installed_packages
end


############################################################
try
    @assert VERSION >= v"1.0.0-dev" "Julia version must be greater than 1.0.0-dev"
catch e
    if e isa AssertionError
        println("Assertion failed: ", e)
    else
        rethrow(e)
    end
end


############################################################
# List of package names to check
package_names = [
    "ArgParse",
    "ConcurrentCollections",
    "CSV",
    "DataFrames",
    "DelimitedFiles",
    "FiniteDiff",
    "Folds",
    "StaticArrays",
    "StatsFuns"
]

# Check each package
for pkg in package_names
    if ! check_package_installed(pkg)
        println("Julia package $pkg not found! Try 'using Pkg; Pkg.add($pkg)' to install it.")
    end
end


