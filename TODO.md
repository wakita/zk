---
title: 'TODO'
author: 'Ken Wakita'
date: '2022-03-23'
---

# TODO (Ken Wakita, 2022-03-23)

- Collections (`categories`, `projects`, `tags`) にリンクを張ること。（一瞬でできそう）
- Collections ごとに一覧のページ (`$SITE/{categories|projects|tags}.html`) を作成すること。
- Collections 一覧へのリンクをツールバーに追加すること。
- ノートの置き場所に応じて `category` に分類すること。

# 要検討

- `$DOCROOT/.meta/{id}.html` を `$SITE/.meta/{id}.js` にして HTML から読み込むようにしたらよさそう。

    ~~~ {$tmpdir/meta.html}
    <script type="text/javascript" src="$BASEURL/.meta/$id.js"></script>
    ~~~

    `--include-before_body=$tmpdir/meta.html`
