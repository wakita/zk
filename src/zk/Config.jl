# Load the configuration,
# - replacing occurrences of environment variable names with their values
const CONFIG = try
  YAML.load(replace(YAML.yaml(YAML.load_file("_config.yml"; dicttype=OrderedDict{String,Any})),
                    r"\$[A-Z]+" => (x -> ENV[x[2:end]]));
            dicttype=OrderedDict{String,Any})
catch
  println("Configuration file not found.") #Dict([])
end

# SYSTEM SECTION
const TZ = TimeZones.TimeZone(CONFIG["TIME_ZONE"])
const LIBDIR = joinpath(SYSROOT, "etc")

for key in split("NOTE_TEMPLATE INDEX_TEMPLATE")
  CONFIG[key] = joinpath(LIBDIR, CONFIG[key])
end

for key in split("NOTE_HTML INDEX_HTML")
  CONFIG[key] = map(path -> joinpath(LIBDIR, path), CONFIG[key])
end

CONFIG["DEFAULT_PANDOC_EXTENSIONS"] = join(CONFIG["DEFAULT_PANDOC_EXTENSIONS"], "+")


# NOTES SECTION
CONFIG["DOCROOT"] = abspath(CONFIG["DOCROOT"])
CONFIG["NOTEDIRS"] = map(path -> joinpath(CONFIG["DOCROOT"], path), CONFIG["NOTEDIRS"])
mkpath(joinpath(CONFIG["DOCROOT"], ".meta"))


# SITE SECTION
BASEURL = CONFIG["BASEURL"]
for key in split("NOTE_CSS INDEX_CSS")
  CONFIG[key] = map(path -> "$BASEURL/$path", CONFIG[key])
end

function print_config()
  print(YAML.yaml(CONFIG))
end
