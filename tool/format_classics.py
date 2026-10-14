"""Format the classics batch on the CI runner and export the verified sources."""
from pathlib import Path
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
patterns = [
    'lib/ui/features/games/chess/*.dart',
    'lib/ui/features/games/poker/poker_*.dart',
    'lib/ui/features/games/shared/*.dart',
    'lib/ui/features/games/detective_casebook/*.dart',
    'lib/ui/features/games/mahjong_solitaire/engine/mahjong_board.dart',
    'lib/ui/features/games/mahjong_solitaire/mahjong_screen.dart',
    'lib/providers/library_style_provider.dart',
    'lib/utils/library_theme.dart', 'lib/utils/game_licenses.dart',
    'lib/widgets/library_style_selector.dart', 'test/games/*.dart',
]
files = sorted({str(p.relative_to(ROOT)) for pattern in patterns for p in ROOT.glob(pattern)})
if not files or 'lib/ui/features/games/chess/chess_session.dart' not in files:
    raise SystemExit('Classics source files were not found')
subprocess.run(['dart', 'format', *files], cwd=ROOT, check=True)
output = ROOT / 'build' / 'verified-classics-sources.zip'
output.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for name in [*files, 'pubspec.lock']:
        archive.write(ROOT / name, name)
print(f'Exported {len(files)} formatted Dart files and the dependency lockfile')
