
Notes = Dict{String,Dict{String,Any}}()

Tags = Dict{String,Set{String}}()
Categories = Dict{String,Set{String}}()
Projects = Dict{String,Set{String}}()

function glob_md(path)
  paths = collect(flatten(map(x -> map(path -> Filesystem.joinpath(x[1], path), x[3]),
                              Filesystem.walkdir(path))))
  filter(endswith(".md"), paths)
end


function load_notes()
  for md_path in  collect(flatten(map(glob_md, CONFIG["NOTEDIRS"])))
    note = YAML.load_file(md_path)
    note["md_path"] = md_path
    note["_created"] = astimezone(ZonedDateTime(replace(note["created"], r" +" => " "),
                                                UTC_DATE_TIME_FORMAT), TZ)
    note["created"] = Dates.format(note["_created"], "e u mm HH:MM yyyy")
    Notes[note["id"]] = note

    function bind(bag::Dict{String,Set{String}}, key::String)
      bag[key] = get(bag, key, Set())
      push!(bag[key], note["id"])
    end

    for tag in get(note, "tags", [])
      bind(Tags, tag)
    end

    bind(Categories, get(note, "category", ""))
    bind(Projects, get(note, "project", ""))
  end

  delete!(Categories, "")
  delete!(Projects, "")
end
