#!/usr/bin/env python3
"""Convert frein-*.md (Org-mode) files to freins.json."""
import re
import json
import uuid
from pathlib import Path

CORPUS_DIR = Path("/Users/olie/Documents/Corpus")
OUTPUT = Path("/Users/olie/Projects/dev/AnnuaireCIP/AnnuaireCIP/Resources/freins.json")


def clean(text):
    text = text.replace("\\'", "'").replace('\\"', '"')
    text = re.sub(r'\*\*\*\*(.*?)\*\*\*\*', r'\1', text)          # ****bold****
    text = re.sub(r'\[\[id:[^\]]*\]\[([^\]]*)\]\]', r'\1', text)  # [[id:x][label]]
    text = re.sub(r'\[([^\]]*)\]\(id:[^\)]*\)', r'\1', text)       # [label](id:x)
    text = re.sub(r'\[([^\]]*)\]\(https?://[^\)]*\)', r'\1', text) # [label](url)
    text = re.sub(r'https?://\S+', '', text)
    text = re.sub(r' --- ', ' — ', text)
    text = re.sub(r'---', '—', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def split_sections(content):
    """Return dict of {header_text: body_text} for top-level # sections."""
    result = {}
    for block in re.split(r'\n(?=# )', content):
        m = re.match(r'# (.+?)\n(.*)', block, re.DOTALL)
        if m:
            result[m.group(1).strip()] = m.group(2).strip()
    return result


def find_section(sections, keyword):
    kw = keyword.lower()
    for k, v in sections.items():
        # Strip Métadonnées attributes (after "{") and subtitles (after " --- ")
        header = k.split('{')[0].split(' --- ')[0].strip().lower()
        if header.startswith(kw) or kw in header:
            return v
    return None


def extract_titre(content):
    m = re.search(r'# D[eé]finition\s*---\s*(.+)', content)
    return clean(m.group(1)) if m else None


def extract_meta_attr(content, attr):
    m = re.search(rf'{attr}="([^"]*)"', content)
    return m.group(1).strip() if m else None


def join_wrapped_bullets(section_text):
    """Join continuation lines (indented) with their preceding bullet."""
    if not section_text:
        return []
    items = []
    current = None
    for line in section_text.splitlines():
        stripped = line.strip()
        if stripped.startswith(('- ', '* ')):
            if current is not None:
                items.append(current)
            current = stripped[2:]
        elif current is not None and stripped and not stripped.startswith('#'):
            current += ' ' + stripped  # continuation line
        else:
            if current is not None:
                items.append(current)
                current = None
    if current is not None:
        items.append(current)
    return items


def extract_bullets(section_text):
    return [clean(raw) for raw in join_wrapped_bullets(section_text) if clean(raw)]


def extract_freins_associes(section_text):
    if not section_text:
        return []
    seen, result = set(), []
    for pattern in [r'\(id:(frein-[a-z0-9-]+)\)', r'\[\[id:(frein-[a-z0-9-]+)\]']:
        for fid in re.findall(pattern, section_text):
            if fid not in seen:
                seen.add(fid)
                result.append(fid)
    return result


def extract_ressources(section_text):
    if not section_text:
        return []
    ressources = []
    for raw in join_wrapped_bullets(section_text):
        raw = raw.strip()
        bold = re.match(r'\*\*\*\*(.+?)\*\*\*\*\s*(?:---\s*)?(.*)$', raw)
        if bold:
            nom = clean(bold.group(1))
            desc = clean(bold.group(2)) or None
        else:
            nom = clean(raw)
            desc = None
        if nom:
            ressources.append({
                "id": str(uuid.uuid4()),
                "nom": nom,
                "description": desc,
                "contact": None,
                "adresse": None,
                "site_web": None,
                "source": "corpus"
            })
    return ressources


def extract_description(section_text):
    if not section_text:
        return ""
    parts = []
    for line in section_text.splitlines():
        line = line.strip()
        if line.startswith('#') or not line:
            continue
        t = clean(line)
        if t:
            parts.append(t)
    return ' '.join(parts)


def extract_notes(section_text):
    if not section_text:
        return None
    lines = []
    for raw in join_wrapped_bullets(section_text):
        t = clean(raw)
        if t:
            lines.append(f"• {t}")
    return '\n'.join(lines) or None


def parse(filepath):
    content = filepath.read_text(encoding='utf-8')
    frein_id = filepath.stem

    sections = split_sections(content)

    titre = extract_titre(content) or frein_id.replace('frein-', '').replace('-', ' ').title()
    description = extract_description(find_section(sections, 'Définition') or find_section(sections, 'Definition'))
    signaux = extract_bullets(find_section(sections, 'Signaux'))
    freins_associes = extract_freins_associes(find_section(sections, 'Liens'))
    ressources = extract_ressources(find_section(sections, 'Dispositifs'))
    notes = extract_notes(find_section(sections, 'Notes CIP'))

    publics_raw = extract_meta_attr(content, 'publics')
    publics_clean = clean(re.sub(r'\[\[id:[^\]]*\]\[([^\]]*)\]\]', r'\1', publics_raw)) if publics_raw else None

    return {
        "id": frein_id,
        "titre": titre,
        "description": description,
        "signaux_reperage": signaux,
        "thematiques_api": [],          # à remplir manuellement
        "publics_api": [publics_clean] if publics_clean else None,
        "freins_associes": freins_associes,
        "ressources_terrain": ressources,
        "notes_cip": notes
    }


def main():
    files = sorted(CORPUS_DIR.glob("frein-*.md"))
    print(f"{len(files)} fichiers trouvés\n")
    freins = []
    for f in files:
        frein = parse(f)
        nb_res = len(frein['ressources_terrain'])
        nb_sig = len(frein['signaux_reperage'])
        print(f"  {f.name:<45} titre={frein['titre'][:35]!r}  signaux={nb_sig}  ressources={nb_res}")
        freins.append(frein)
    OUTPUT.write_text(json.dumps(freins, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"\n✓ {len(freins)} freins écrits dans {OUTPUT}")


if __name__ == "__main__":
    main()
