#!/Users/wakita/.venvs/zk/bin/python3

import glob
import io
import json
import logging
import os
from pathlib import Path
import re
import subprocess

import dateutil
from dateutil.parser import parse as parsedate
import frontmatter
import yaml
from yaml import CLoader

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler())

config = None

def load_config():
  global config
  proc = subprocess.run(['envsubst < _config.yml'], shell=True, capture_output=True)
  config = yaml.load(proc.stdout, Loader=CLoader)
  config['SYSROOT'] = SYSROOT = Path(config['SYSROOT'])
  config['SITE'] = Path(config['SITE'])

  config['PANDOC_EXTENSION'] = '+'.join(config['PANDOC_EXTENSION'])
  for key in 'NOTE_TEMPLATE,INDEX_TEMPLATE'.split(','):
    config[key] = SYSROOT.joinpath(config[key]).as_posix()
  for key in 'NOTE_HTML,INDEX_HTML'.split(','):
    config[key] = [SYSROOT.joinpath(path).as_posix() for path in config[key]]
  for k, v in config.items():
    logger.info(f'{k}: {v}')

notes = dict()
# Collections
tags, categories, projects = dict(), dict(), dict()

def load_notes():
  tz = dateutil.tz.gettz(config['TIME_ZONE'])

  paths = []
  for dir in config['NOTEDIRS']:
    paths += glob.glob(dir + '/**/*.md', recursive=True)
  logger.info(f'paths: {paths}')
  for path in paths:
    note = frontmatter.load(path)
    note['md_path'] = path
    created = parsedate(note['created']).astimezone(tz)
    note['_created'] = created.timestamp()
    note['created'] = created.strftime(f'%a %b %d %H:%M %Y')
    notes[note['id']] = note

    # Collect information of collections
    for field, collection in [('tags', tags), ('category', categories), ('project', projects)]:
      val = note.get(field, default=[])
      if type(val) == str: val = [val]
      for key in val:
        if not collection.get(key, False): collection[key] = set()
        collection[key].add(note['id'])
  for field, collection in [('tags', tags), ('category', categories), ('project', projects)]:
    logger.info(f'{field}: {collection}')

def id2html_path(id):
  return config['SITE'].joinpath('notes', f'{id}.html').as_posix()

def html_path(note):
  return id2html_path(note['id'])

def find_dirty_notes():
  dirty = set([])
  for id, note in notes.items():
    md_path = note['md_path']
    '''
    以下のいずれの条件に合致するノートは HTML の（再）生成を要する (dirty):
    - 対応する HTML が存在しない
    - 対応する HTML の生成時刻が古い
    '''
    if (not os.path.exists(html_path(note)) or
        os.stat(html_path(note)).st_mtime < os.stat(md_path).st_mtime):
      dirty.add(id)
  return dirty

def pandoc(cmdline):
  logger.info(cmdline)
  subprocess.run(cmdline)

def pandoc_note(md_path, meta_html, html_path):
  pandoc(['pandoc', '--from', config['PANDOC_EXTENSION'], '--template', config['NOTE_TEMPLATE'], '--standalone',
          '--output', html_path, md_path ] +
         [f'--css={config["SITEBASE"]}/{css}' for css in config['NOTE_CSS']] +
         [f'--include-before-body={html}' for html in [meta_html] + config['NOTE_HTML']])

def process_notes(ids):
  SITE, SITEBASE = config['SITE'], config['SITEBASE']
  os.makedirs(f'.meta', exist_ok=True)
  meta = Path('.meta')
  for id in ids:
    note = notes[id]
    meta_html = meta.joinpath(f'{id}.html').as_posix()
    with open(meta_html, 'w') as html:
      d = note.to_dict()
      del d['content']
      data = json.dumps(d, ensure_ascii=False)
      html.write(f'<script type="text/javascript">\nconst NOTE={data};\n</script>\n')

    pandoc_note(note['md_path'], meta_html, html_path(note))

def pandoc_index(md_path, html_path):
  pandoc(['pandoc', '--from', config['PANDOC_EXTENSION'], '--template', config['INDEX_TEMPLATE'], '--standalone',
          '--output', html_path, md_path ] +
         [f'--css={config["SITEBASE"]}/{css}' for css in config['INDEX_CSS']] +
         [f'--include-before-body={html}' for html in config['INDEX_HTML']])

def make_index():
  SITE, SITEBASE = config['SITE'], config['SITEBASE']
  meta = Path('.meta')

  def generate_md(md_path, html_path, title, note_ids):
    with open(md_path, 'w') as index:
      index.write(f'''---
title: {title}
---

''')
      index.write('::: links\n')
      for note in sorted([notes[id] for id in note_ids], key=lambda note: note['_created'], reverse=True):
        date = note['created']
        title = note['title']
        if len(title) > 20: title = title[:30] + '...'
        index.write(f'- {date} &middot; [{title}]({SITEBASE}/notes/{note["id"]}.html)\n\n')
      index.write(':::\n')
    pandoc_index(md_path, html_path)

  # /index.html
  generate_md(meta.joinpath('index.md').as_posix(), SITE.joinpath('index.html').as_posix(),
              'Zettelkasten', notes.keys())

  # /category/draft.html
  for collection_name, collection in zip('tag,category,project'.split(','), [tags, categories, projects]):
    for key, note_ids in collection.items():
      generate_md(meta.joinpath(f'{collection_name}-{key}.md').as_posix(), SITE.joinpath(collection_name, key + '.html').as_posix(), key, note_ids)

    # /category/index.html

def main():
  load_config()
  load_notes()
  dirty_notes = find_dirty_notes()
  logger.info('dirty notes: ' + str(dirty_notes))
  process_notes(dirty_notes)
  make_index()

if __name__ == '__main__':
  main()
