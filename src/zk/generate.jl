"""
    pandoc_notes(ids)

与えられたID群で指定されたノートのHTMLページ群を生成する。
"""
function pandoc_notes(ids::Array{String})
  for id in ids                        # ノートのメタ情報を JavaScript のファイルとして生成
    meta_js = 
    open(joinpath(CONFIG["SITE"], ".meta", "$id.js"), "w") do js
      write(js, "const NOTE = ")
      JSON.print(js, Notes[id])
      write(js, ";\n")
    end

  run(Cmd(["pandoc", "--defaults=lib/note.yaml",
           "--output", joinpath(CONFIG["SITE"], "notes", "$id.html"),
           Notes[id]["md_path"]]))
  end
end

function pandoc_index(md_path, html_path, title, note_ids)
  println("Generating $title")
  open(md_path, "w") do md
    write(md, """---
title: $title
---

::: links
""")
    for note in sort(map(id -> Notes[id], collect(note_ids)), by=note -> note["_created"], rev=true)
      id, date, _title = note["id"], note["created"], note["title"]
      if sizeof(_title) > 40            # Multibyte char に対応
        title = _title[1:prevind(_title, nextind(_title, 40))] * "..."
      else
        title = _title
      end
      write(md, "- $date &middot; [$title]($BASEURL/notes/$id.html)\n\n")
    end
    write(md, ":::\n")
  end
  run(Cmd(["pandoc", "--defaults=lib/index.yaml", "--output", html_path, md_path]))
end

function pandoc_indices()
  Meta, Site = joinpath(CONFIG["DOCROOT"], ".meta"), CONFIG["SITE"]
  # index.html
  md_path = joinpath(Meta, "index.md")
  html_path = joinpath(Site, "index.html")
  pandoc_index(md_path, html_path, "Index", keys(Notes))

  # collections
  for (name, collection) in zip(split("tag,category,project", ","), [Tags, Categories, Projects])
    for (key, ids) in collection
      md_path = joinpath(Meta, "$name-$key.md")
      html_path = joinpath(Site, name, "$key.html")
      pandoc_index(md_path, html_path, "$name-$key", ids)
    end
  end
end

function generate()
  pandoc_notes(collect(keys(Notes)))
  pandoc_indices()
end

generate()
