using Base.Filesystem
using JSON
using Printf

"""
    pandoc_note(md_path::String, meta_html::String, html_path::String)

Pandocを用いてZettelkastenノート (`md_path`で指定) からHTMLページ (`html_path`で指定) を生成する。

# Arguments
- `meta_html`: ノートのメタ情報を抽出したJavaScriptのファイルへのパス。

See also [`pandoc_notes`](@ref).
"""
function pandoc_note(md_path, meta_html, html_path)
  C = CONFIG
  #NOTE_TEMPLATE = joinpath(C["SYSROOT"], C["NOTE_TEMPLATE"])

  cmdline = ["pandoc", "--from", C["DEFAULT_PANDOC_EXTENSIONS"], "--template", C["NOTE_TEMPLATE"], "--standalone",
             "--output", html_path, md_path]
  append!(cmdline, map(css -> "--css=$(css)", C["NOTE_CSS"]))
  push!(cmdline, "--include-before-body=$meta_html")
  append!(cmdline, map(html -> "--include-before-body=$(html)", C["NOTE_HTML"]))
  #println(join(cmdline, " "))
  run(Cmd(cmdline))
end


"""
    pandoc_notes(ids)

与えられたID群で指定されたノートのHTMLページ群を生成する。

See also [`pandoc_note`](@ref).
"""
function pandoc_notes(ids::Array{String})
  for id in ids                        # ノートのメタ情報を JavaScript のファイルとして生成
    meta_html = joinpath(CONFIG["DOCROOT"], ".meta", "$id.html")
    open(meta_html, "w") do html
      write(html, "<script type=\"text/javascript\">\nconst NOTE = ")
      JSON.print(html, Notes[id])
      write(html, ";\n</script>\n")
    end

    pandoc_note(Notes[id]["md_path"], meta_html, joinpath(CONFIG["SITE"], "notes", "$id.html"))
  end
end

function pandoc_index(md_path, html_path)
  cmdline = ["pandoc", "--from", CONFIG["DEFAULT_PANDOC_EXTENSIONS"], "--template", CONFIG["INDEX_TEMPLATE"], "--standalone",
             "--output", html_path, md_path]
  append!(cmdline, map(css -> "--css=$css", CONFIG["INDEX_CSS"]))
  append!(cmdline, map(html -> "--include-before-body=$html", CONFIG["INDEX_HTML"]))
  run(Cmd(cmdline))
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
  pandoc_index(md_path, html_path)
end

s = "わたしの名前は中野です。"

function pandoc_indices()
  Meta, Site = joinpath(CONFIG["DOCROOT"], ".meta"), CONFIG["SITE"]
  # index.html
  md_path = joinpath(Meta, "index.md")
  html_path = joinpath(Site, "index.html")
  println("$md_path, $html_path")
  pandoc_index(md_path, html_path, "Index", keys(Notes))

  # collections
  for (name, collection) in zip(split("tag,category,project", ","), [Tags, Categories, Projects])
    for (key, ids) in collection
      md_path = joinpath(Meta, "$name-$key.md")
      html_path = joinpath(Site, name, "$key.html")
      pandoc_index(md_path, html_path, key, ids)
    end
  end
end

function generate()
  pandoc_notes(collect(keys(Notes)))
  pandoc_indices()
end
