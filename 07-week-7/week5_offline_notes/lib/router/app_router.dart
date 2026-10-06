import 'package:go_router/go_router.dart';

import '../pages/note_detail_page.dart';
import '../pages/notes_page.dart';
import '../pages/posts_page.dart';
import '../pages/settings_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const NotesPage(),
      routes: [
        GoRoute(
          path: 'note/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return NoteDetailPage(id: id);
          },
        ),
        GoRoute(
          path: 'posts',
          builder: (context, state) => const PostsPage(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);
