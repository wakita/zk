module ZK

include("ZK/Install.jl")

"""
using PythonInterface
config = PythonInterface.load_config()
if config == nothing
  println(stderr, "_config.yml not found.")
  exit(1)
end
"""

include("ZK/Config.jl")
include("ZK/Load.jl")
include("ZK/Generate.jl")
include("ZK/Main.jl")

end
