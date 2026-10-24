import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:puzzle/data/models/game_streak.dart';
import 'package:puzzle/data/models/user_data.dart';
import 'package:puzzle/data/repositories/user_repository.dart';
import 'package:puzzle/main.dart';
import 'package:puzzle/providers/game_session_provider.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/ui/features/games/shared/game_storage.dart';
import 'package:puzzle/ui/features/home/widgets/continue_card.dart';
import 'package:puzzle/ui/features/games/black_box/black_box_engine.dart';
import 'package:puzzle/ui/features/games/common/campaign_level_bar.dart';
import 'package:puzzle/ui/features/games/common/campaign_progress.dart';
import 'package:puzzle/ui/features/games/common/game_kit.dart';
import 'package:puzzle/ui/features/games/inertia/inertia_engine.dart';
import 'package:puzzle/ui/features/games/peg_solitaire/peg_solitaire_screen.dart';
import 'package:puzzle/ui/features/games/sixteen/sixteen_screen.dart';
import 'package:puzzle/ui/features/games/tower_of_hanoi/tower_of_hanoi_screen.dart';

void main() {
  // In-memory boxes keep storage synchronous enough for widget tests.
  setUpAll(() async {
    await Hive.openBox(CampaignProgress.boxName, bytes: Uint8List(0));
  });
  tearDownAll(() => Hive.box(CampaignProgress.boxName).close());
  setUp(() => Hive.box(CampaignProgress.boxName).clear());

  group('Resuming an unfinished level', () {
    testWidgets('Sixteen restores the tiles and move count', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SixteenScreen()));
      await tester.tap(find.byIcon(Icons.arrow_forward).first);
      await tester.pump();
      expect(find.text('Moves: 1'), findsOneWidget);
      final saved = CampaignLevelBar.restoreActive('sixteen', 1)!;
      expect(saved.first, 1);

      // Leave and come back: the same position and move count.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const MaterialApp(home: SixteenScreen()));
      expect(find.text('Moves: 1'), findsOneWidget);

      // New game starts the level afresh.
      await tester.tap(find.byTooltip('New game'));
      await tester.pump();
      expect(find.text('Moves: 0'), findsOneWidget);
    });

    testWidgets('Peg Solitaire restores the board', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PegSolitaireScreen()));
      expect(find.text('6 pegs left'), findsOneWidget);
      // Level 1 (Cross): jump the centre peg left over its neighbour.
      await tester.tap(find.byKey(const ValueKey('peg_solitaire_cell_17')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('peg_solitaire_cell_15')));
      await tester.pump();
      expect(find.text('5 pegs left'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const MaterialApp(home: PegSolitaireScreen()));
      expect(find.text('5 pegs left'), findsOneWidget);
    });

    test('engine snapshots round-trip and reject stale data', () {
      final box = BlackBoxGame(n: 6, balls: 3)
        ..toggleGuess(0)
        ..fire(2);
      final copy = BlackBoxGame.fromSnapshot(6, 3, box.snapshot)!;
      expect(copy.hidden, box.hidden);
      expect(copy.guesses, box.guesses);
      expect(copy.lasersUsed, box.lasersUsed);
      expect(BlackBoxGame.fromSnapshot(6, 4, box.snapshot), isNull);

      final inertia = InertiaLevels.build(3);
      final fresh = InertiaLevels.build(3);
      expect(fresh.restore(inertia.snapshot), isTrue);
      final other = InertiaLevels.build(4).snapshot;
      expect(InertiaLevels.build(3).restore(other), isFalse);

      final hanoi = HanoiLevels.build(5);
      final again = HanoiLevels.build(5)..restore(hanoi.pegOfDiscs, 3);
      expect(again.pegOfDiscs, hanoi.pegOfDiscs);
      expect(again.moves, 3);
      expect(again.optimal, hanoi.optimal);
    });
  });

  group('Results and stars', () {
    test('keeps the best result per level', () {
      CampaignProgress.recordResult('t', 2, stars: 1, score: 30);
      CampaignProgress.recordResult('t', 2, stars: 3, score: 40);
      final r = CampaignProgress.recordResult('t', 2, stars: 2, score: 12);
      expect(r[2], (3, 12));
      expect(CampaignProgress.loadResults('t')[2], (3, 12));
      // Higher-is-better scores keep the maximum.
      CampaignProgress.recordResult('h', 1,
          stars: 1, score: 500, lowerIsBetter: false);
      expect(
          CampaignProgress.recordResult('h', 1,
              stars: 1, score: 200, lowerIsBetter: false)[1],
          (1, 500));
    });

    test('starsForPar', () {
      expect(starsForPar(5, 5), 3);
      expect(starsForPar(9, 5), 2);
      expect(starsForPar(11, 5), 1);
    });

    testWidgets('winning shows the level-complete card with stars',
        (tester) async {
      var solved = false;
      late StateSetter update;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(builder: (context, setState) {
            update = setState;
            return CampaignLevelBar(
              gameId: 'cardtest',
              level: 4,
              solved: solved,
              onLevel: (_) {},
              result:
                  CampaignResult(score: 9, stars: 2, label: (m) => '$m moves'),
            );
          }),
        ),
      ));
      expect(find.text('Level 4 complete!'), findsNothing);
      update(() => solved = true);
      await tester.pump();
      expect(find.text('Level 4 complete!'), findsOneWidget);
      expect(find.text('9 moves'), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('cardtest_level_complete')),
              matching: find.byIcon(Icons.star_rounded)),
          findsNWidgets(2));
      expect(find.byKey(const ValueKey('cardtest_next_level')), findsOneWidget);
      expect(CampaignProgress.loadResults('cardtest')[4], (2, 9));
      expect(CampaignLevelBar.restoreActive('cardtest', 4), isNull);
    });
  });

  testWidgets('a win sets off confetti', (tester) async {
    var done = false;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return GameScaffold(
          title: 'T',
          rules: '',
          onNewGame: () {},
          completed: done,
          children: const [Text('board')],
        );
      }),
    ));
    expect(find.byKey(const ValueKey('confetti')), findsNothing);
    update(() => done = true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('confetti')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('confetti')), findsNothing);
  });

  testWidgets('a sideways phone puts the board beside the controls',
      (tester) async {
    tester.view.physicalSize = const Size(780, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: GameScaffold(
        title: 'T',
        rules: '',
        onNewGame: () {},
        children: const [
          Text('controls'),
          LandscapeBoard(
            child: AspectRatio(aspectRatio: 1, child: Placeholder()),
          ),
        ],
      ),
    ));
    final board = tester.getRect(find.byType(Placeholder));
    final controls = tester.getRect(find.text('controls'));
    expect(board.left, greaterThan(controls.right));
    expect(board.bottom, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });

  group('Library', () {
    late Directory dir;
    late UserRepository repo;

    Future<void> openLibrary(WidgetTester tester) async {
      await tester.runAsync(() async {
        dir = await Directory.systemTemp.createTemp('library-test');
        Hive.init(dir.path);
        if (!Hive.isAdapterRegistered(0))
          Hive.registerAdapter(UserDataAdapter());
        if (!Hive.isAdapterRegistered(1))
          Hive.registerAdapter(GameStreakAdapter());
        if (!Hive.isBoxOpen('classic_games_v1')) {
          await Hive.openBox<String>('classic_games_v1', bytes: Uint8List(0));
        }
        repo = UserRepository();
        await repo.init();
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [userRepositoryProvider.overrideWithValue(repo)],
        child: const MyApp(),
      ));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    testWidgets('shows a search button, a dice button and the new name',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await openLibrary(tester);
      expect(find.text('PUZZLE MASTER'), findsOneWidget);
      expect(find.bySemanticsLabel('Search games'), findsOneWidget);
      expect(find.byKey(const ValueKey('random_game_button')), findsOneWidget);
      // Nothing played yet, so there is nothing to continue.
      expect(find.byKey(const ValueKey('continue_card')), findsNothing);
    });

    testWidgets('remembers the category and offers to continue a game',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await openLibrary(tester);

      await tester.ensureVisible(find.text('CARDS'));
      await tester.tap(find.text('CARDS'));
      await tester.pump();
      final saved =
          await tester.runAsync(() => GameStorage.load('library_category'));
      expect(saved?['category'], 'CARD');

      // Back on All, the last game played can be continued.
      await tester.ensureVisible(find.text('ALL'));
      await tester.tap(find.text('ALL'));
      await tester.pump();
      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      container
          .read(gameSessionNotifierProvider.notifier)
          .setSession(gameId: 'peg_solitaire', category: 'ALL', query: '');
      await tester.pump();
      // (Scrolled past by the category taps above, so look offstage too.)
      expect(find.byKey(const ValueKey('continue_card'), skipOffstage: false),
          findsOneWidget);
      expect(
          find.text('CONTINUE PLAYING', skipOffstage: false), findsOneWidget);
    });
  });
}
