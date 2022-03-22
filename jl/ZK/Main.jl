using ArgParse
using Base.Filesystem
using Base.Iterators
using Dates

# using PythonInterface

# https://argparsejl.readthedocs.io/en/latest/argparse.html
function parse_commandline()
  s = ArgParseSettings()

  @add_arg_table s begin
    "--print-config"
      help = "print configuration"
      action = :store_true
  end

  return parse_args(ARGS, s)
end

const UTC_DATE_TIME_FORMAT = "e u d H:M:S Z Y"

function main()
  install_packages()
  parsed_args = parse_commandline()
  parsed_args
  for (k, v) in parsed_args
    println("  $k => $v")
  end

  if parsed_args["print-config"]
    print_config()
  end

  load_notes()
  generate()

end
