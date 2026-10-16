"""Ensure the game menu does not promise an absent how-to-play guide."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent.parent
registry = root / 'lib/data/game_registry.dart'
source = registry.read_text(encoding='utf-8')
imports = re.findall(r"^import '([^']+)'(?: show [^;]+)?;", source, re.M)
ids = {}
for name in imports:
    path = (registry.parent / name).resolve()
    if not path.is_file():
        continue
    content = path.read_text(encoding='utf-8')
    for symbol, game_id in re.findall(
        r"""(?:final|const)\s+(\w+Metadata)\s*=\s*GameMetadata\(\s*id:\s*['"]([^'"]+)['"]""", content, re.S
    ):
        ids[symbol] = game_id
names = re.findall(r'^    (\w+Metadata),$', source, re.M)
catalog = {ids[n] for n in names if n in ids}
guide_ids = set()
for path in (root / 'lib/data/game_guides.dart',
             root / 'lib/data/game_guides_added.dart'):
    content = path.read_text(encoding='utf-8')
    guide_ids.update(re.findall(r"""(?m)^\s*['"]([^'"]+)['"]:\s*GameGuide\(""", content))
fallback = (root / 'lib/ui/features/home/widgets/game_guide_fallback.dart').read_text(encoding='utf-8')
guide_ids.update(re.findall(r"if \(game.id == '([^']+)'\)", fallback))
missing = sorted(catalog - guide_ids)
print(f'Catalog: {len(catalog)}; game-specific guides: '
      f'{len(catalog - set(missing))}; missing: {len(missing)}')
if missing:
    print('Missing:', ', '.join(missing))
sys.exit(bool(missing))
