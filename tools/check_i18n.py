#!/usr/bin/env python3
"""Small build-time guard for fixed Academy Welsh UI text.

It checks literal I18nText strings and fixed course/trophy wording against the
Welsh dictionary. Dynamic user data is intentionally excluded.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
I18N = ROOT / 'lib' / 'i18n.dart'

source = I18N.read_text(encoding='utf-8')
keys = {
    m.group(1).replace(r"\'", "'").replace(r'\\', '\\')
    for m in re.finditer(r"^\s*'((?:\\.|[^'])*)'\s*:\s*'", source, re.M)
}

ignore = {'007', '1-to-1', '?', '⛵'}
missing = []

for path in (ROOT / 'lib').rglob('*.dart'):
    text = path.read_text(encoding='utf-8')
    for match in re.finditer(r"I18nText\(\s*(['\"])((?:\\.|(?!\1).)*)\1", text, re.S):
        value = match.group(2).replace(r"\'", "'").replace(r'\"', '"')
        if '$' in value or value in ignore:
            continue
        if value not in keys:
            line = text[:match.start()].count('\n') + 1
            missing.append(f'{path.relative_to(ROOT)}:{line}: {value}')

course = (ROOT / 'lib' / 'course_data.dart').read_text(encoding='utf-8')
for match in re.finditer(r"(?:title|summary|stage|trophyTitle|assessmentText|category|description):\s*'((?:\\'|[^'])*)'", course):
    value = match.group(1).replace(r"\'", "'")
    if value not in keys:
        missing.append(f'lib/course_data.dart: fixed course text: {value}')

# Fixed Flutter Text widgets bypass the Academy translator. There should be no
# literal Text('...') UI; dynamic Text(data) is fine.
raw_text = []
for path in (ROOT / 'lib').rglob('*.dart'):
    text = path.read_text(encoding='utf-8')
    for match in re.finditer(r"(?<!I18n)(?<!Selectable)\bText\(\s*(['\"])", text):
        line = text[:match.start()].count('\n') + 1
        raw_text.append(f'{path.relative_to(ROOT)}:{line}')

if missing or raw_text:
    if missing:
        print('Missing Welsh dictionary entries:')
        print('\n'.join(f'  - {item}' for item in sorted(set(missing))))
    if raw_text:
        print('Fixed Text(...) widgets bypassing I18nText:')
        print('\n'.join(f'  - {item}' for item in sorted(set(raw_text))))
    sys.exit(1)

print(f'Welsh UI audit passed: {len(keys)} dictionary entries checked.')
