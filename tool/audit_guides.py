"""Audit whether every registered game has a meaningful, openable guide."""
from pathlib import Path
import re

root = Path(__file__).resolve().parent.parent
registry = (root / 'lib/data/game_registry.dart').read_text(encoding='utf-8-sig')
entries = re.findall(r"^    (\w+Metadata),$", registry, re.M)
catalog = {}
for path in re.findall(r"^import '([^']+)'", registry, re.M):
    file = (root / 'lib/data' / path).resolve()
    content = file.read_text(encoding='utf-8-sig')
    matches = re.findall(
        r"""(?:final|const)\s+(\w+Metadata)\s*=\s*GameMetadata\(\s*id:\s*(['"])(.*?)\2""",
        content, re.S)
    for symbol, _, game_id in matches:
        catalog[symbol] = (game_id, file)
guides = (root / 'lib/data/game_guides.dart').read_text(encoding='utf-8-sig')
guided = set(re.findall(r'^\s*["\']([^"\']+)["\']:\s*GameGuide\(', guides, re.M))
added_text = (root / 'lib/data/game_guides_added.dart').read_text(encoding='utf-8-sig')
added = set(re.findall(r'^\s*["\']([^"\']+)["\']:\s*GameGuide\(', added_text, re.M))
covered = guided | added
missing = [catalog[name] for name in entries if catalog[name][0] not in covered]
print('REGISTERED', len(entries), 'ORIGINAL', len(guided),
      'ADDED', len(added), 'UNCOVERED', len(missing))
if guided & added:
    raise SystemExit('Duplicate guide IDs across original and added maps')
for game_id, path in missing:
    folder = path.parent
    with_rules = [f.name for f in folder.rglob('*.dart')
                  if 'rules:' in f.read_text(encoding='utf-8-sig')]
    print(f'{game_id:26} {"/".join(with_rules) if with_rules else "NO-RULES-EXTRACT"}')
if missing:
    raise SystemExit('Every catalog game must have a guide before release')
