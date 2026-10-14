"""Check catalog imports, metadata registration and game IDs."""
from collections import Counter
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent.parent
registry = root / 'lib/data/game_registry.dart'
source = registry.read_text(encoding='utf-8')
imports = re.findall(r"^import '([^']+)'(?: show ([^;]+))?;", source, re.M)
registered = re.findall(r'^    (\w+Metadata),$', source, re.M)
declared, errors = {}, []
for name, only in imports:
    path = (registry.parent / name).resolve()
    if not path.is_file():
        errors.append(f'Missing import: {name}')
        continue
    definitions = re.findall(
        r"""(?:final|const)\s+(\w+Metadata)\s*=\s*GameMetadata\(\s*id:\s*(['"])(.*?)\2""",
        path.read_text(encoding='utf-8'), re.S)
    for symbol, _, game_id in definitions:
        if only and symbol not in [x.strip() for x in only.split(',')]:
            continue
        if symbol in declared:
            errors.append(f'Ambiguous metadata: {symbol}')
        declared[symbol] = game_id
dups = [x for x, n in Counter(registered).items() if n > 1]
if dups:
    errors.append(f'Duplicate registrations: {dups}')
unknown = [x for x in registered if x not in declared]
if unknown:
    errors.append(f'Unresolved metadata definitions: {unknown}')
ids = [declared[x] for x in registered if x in declared]
dup_ids = [x for x, n in Counter(ids).items() if n > 1]
if dup_ids:
    errors.append(f'Duplicate game IDs: {dup_ids}')
print(f'Catalog: {len(registered)} entries, {len(ids)} parsed, {len(set(ids))} unique IDs')
for message in errors:
    print('ERROR:', message, file=sys.stderr)
sys.exit(bool(errors))
