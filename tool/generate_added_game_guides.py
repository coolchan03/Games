"""Generate licensed game guides from the in-app rules text.

The original Puzzle guide map is generated upstream and not edited here.
Games' new screens already contain their own authoritative rules; this script
reuses those strings for the catalog's detailed how-to-play menu.
"""
from __future__ import annotations
import ast
from pathlib import Path
import re

root = Path(__file__).resolve().parent.parent
source_registry = (root / 'lib/data/game_registry.dart').read_text(encoding='utf-8-sig')
registry = re.findall(r'^    (\w+Metadata),$', source_registry, re.M)
guided_source = (root / 'lib/data/game_guides.dart').read_text(encoding='utf-8-sig')
guided = set(re.findall(r'^\s*["\']([^"\']+)["\']:\s*GameGuide\(', guided_source, re.M))
metadata: dict[str, tuple[str, str, Path]] = {}
for relative in re.findall(r"^import '([^']+)'", source_registry, re.M):
    path = (root / 'lib/data' / relative).resolve()
    src = path.read_text(encoding='utf-8-sig')
    for symbol, _, game_id in re.findall(
            r"""(?:final|const)\s+(\w+Metadata)\s*=\s*GameMetadata\(\s*id:\s*(['"])(.*?)\2""", src, re.S):
        category = re.search(r"""category:\s*['"]([^'"]+)['"]""", src)
        metadata[symbol] = (game_id, category.group(1) if category else 'LOGIC', path)

manual = {
    'connect_four': 'Drop colored discs into a column. Connect four of your color horizontally, vertically, or diagonally before your opponent. Take turns on the same device or play against the computer.',
    'reversi': 'Place a disc so that one or more straight lines of opposing discs are trapped between the new disc and your existing discs. Trapped discs flip to your color. When no legal moves remain, the player with more discs wins.',
    'mancala': 'Choose a pit on your side and distribute its stones one at a time around the board. Landing the last stone in your store earns another move. Capture across an empty pit where allowed. Have more stones in your store at the end.',
    'checkers': 'Move diagonally on dark squares. Capture by jumping over enemy pieces into an empty square, taking another jump when required. Reach the far edge to crown a king. Win by capturing or blocking all opponent pieces.',
    'detective_casebook': 'Read the clues, inspect alibis and timelines, and determine who committed the crime. Mark deductions before accusing a suspect; use hints when stuck. Each generated case is checked for a unique solution.',
    'tic_tac_toe': 'Players alternate placing X and O on a three-by-three board. Place three of your symbols in a row, column or diagonal to win. If the board fills with no line, it is a draw.',
    'blackjack': 'Beat the dealer without going over 21. Number cards score their value, face cards count ten and an ace counts one or eleven. Hit, stand, double or split when available; dealer actions are automatic. Chips are virtual.',
}

def dart_literal_sequence(text: str, position: int) -> str:
    parts = []
    while True:
        while position < len(text) and text[position].isspace():
            position += 1
        if position >= len(text) or text[position] not in ('"', "'"):
            break
        quote = text[position]
        end = position + 1
        while end < len(text):
            if text[end] == '\\':
                end += 2
            elif text[end] == quote:
                end += 1
                break
            else:
                end += 1
        token = text[position:end]
        try:
            parts.append(ast.literal_eval(token))
        except (SyntaxError, ValueError):
            break
        position = end
    return ''.join(parts).strip()

def rules_for(folder: Path) -> str:
    candidates = []
    for file in folder.glob('*_screen.dart'):
        src = file.read_text(encoding='utf-8-sig')
        for match in re.finditer(r'\brules:\s*', src):
            raw = dart_literal_sequence(src, match.end())
            if len(raw) > 25:
                candidates.append(raw)
    return max(candidates, key=len, default='')

def dart(value: str) -> str:
    return "'" + value.replace('\\', '\\\\').replace("'", "\\'").replace(
        '$', '\\$').replace('\n', '\\n') + "'"

def control_text(objective: str, category: str) -> str:
    sentences = re.split(r'(?<=[.!?])\s+', objective.replace('\n', ' '))
    action = re.compile(r'\b(tap|click|press|choose|drag|select|hold|roll|swipe)\b', re.I)
    selected = [sentence.strip() for sentence in sentences if action.search(sentence)]
    if selected:
        return ' '.join(selected[:2])
    if category == 'CARD':
        return 'Tap a card or pile, then use the available action buttons to play a legal move.'
    if category == 'BOARD':
        return 'Tap a piece or board location and then its destination, or use the game action buttons.'
    return 'Use the on-screen puzzle controls to enter an answer or select a move.'

lines = [
    '// Generated from game-specific in-app rules. Edit source rules, not this file.',
    "import 'game_guides.dart';",
    '',
    'const Map<String, GameGuide> addedGameGuides = {',
]
unresolved = []
for symbol in registry:
    game_id, category, meta_file = metadata[symbol]
    if game_id in guided:
        continue
    title = game_id.replace('_', ' ').title()
    src = meta_file.read_text(encoding='utf-8-sig')
    match = re.search(r"""titleGetter:\s*\([^)]*\)\s*=>\s*(['"])(.*?)\1""", src, re.S)
    if match and '$' not in match.group(2):
        title = match.group(2)
    objective = rules_for(meta_file.parent) or manual.get(game_id, '')
    objective = re.sub(r'\$\{[^}]+\}', 'the current value', objective)
    objective = re.sub(r'\$[A-Za-z_]\w*', 'the current value', objective)
    if len(objective) < 35:
        unresolved.append(game_id)
        continue
    control = control_text(objective, category)
    sentences = [x.strip() for x in re.split(r'(?<=[.!?])\s+', objective.replace('\n', ' '))
                 if len(x.strip()) > 15]
    steps = sentences[:3]
    if len(steps) < 2:
        steps.append('Take turns and use the on-screen controls to follow these rules.')
    strategy = ['Check the possible moves or options before committing.',
                'Reopen this guide or the in-game Rules button whenever needed.']
    lines.extend([
        f'  {dart(game_id)}: GameGuide(',
        f'    title: {dart(title)},',
        f'    category: {dart(category)},',
        f'    objective: {dart(objective)},',
        f'    controls: {dart(control)},',
        f'    walkthrough: [{", ".join(dart(s) for s in steps)}],',
        f'    strategies: [{", ".join(dart(s) for s in strategy)}],',
        '  ),',
    ])
lines.append('};')
if unresolved:
    raise SystemExit('Missing sufficient rules: ' + ', '.join(unresolved))
target = root / 'lib/data/game_guides_added.dart'
target.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(f'Generated {sum(1 for line in lines if ": GameGuide(" in line)} guide entries at {target}')
