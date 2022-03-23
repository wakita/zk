module ZK

using Pkg
include("zk/install.jl")

using Printf

using Base.Filesystem
using Base.Iterators

using Dates

using ArgParse              # https://github.com/carlobaldassi/ArgParse.jl
using JSON                  # https://github.com/JuliaIO/JSON.jl
using OrderedCollections    # https://github.com/JuliaCollections/OrderedCollections.jl
using TimeZones             # https://github.com/JuliaTime/TimeZones.jl
import YAML                 # https://github.com/JuliaData/YAML.jl


SYSROOT = ENV["SYSROOT"]

include("zk/args.jl")
include("zk/config.jl")
include("zk/load.jl")
include("zk/generate.jl")

end
