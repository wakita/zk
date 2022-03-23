# https://argparsejl.readthedocs.io/en/latest/argparse.html
function parse_commandline()
  s = ArgParseSettings()

  @add_arg_table s begin
    "--print-config"
    help = "print configuration"
    action = :store_true
  end

  @add_arg_table s begin
    "--interact"
    help = "Interactive mode; REPL runs"
    action = :store_true
  end

  parsed_args = parse_args(ARGS, s)

  if parsed_args["print-config"] print_config() end
  return parsed_args
end

parsed_args = parse_commandline()
