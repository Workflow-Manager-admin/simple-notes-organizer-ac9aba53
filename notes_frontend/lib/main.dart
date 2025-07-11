import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// SUPABASE_URL and SUPABASE_KEY must be set for your project. For security, these would usually
// be loaded from environment or secrets. For simplicity, they are in-code here.
const String supabaseUrl = 'https://mzxyorlnbfdkneiezgjz.supabase.co';
const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im16eHlvcmxuYmZka25laWV6Z2p6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNDUxMDksImV4cCI6MjA2NzYyMTEwOX0.URYpbwtC2u5ORBlUzpWPNspXMWq_cLBOKWMOgGbilyQ';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const NotesApp());
}

// Colors from instructions
const Color kPrimaryColor = Color(0xFF1976D2);
const Color kSecondaryColor = Color(0xFF424242);
const Color kAccentColor = Color(0xFFFFCA28);

final notesTable = 'notes';

// PUBLIC_INTERFACE
class NotesApp extends StatelessWidget {
  /// Root widget with global theme
  const NotesApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
          error: Colors.red[700]!,
          onError: Colors.white,
        ),
        primaryColor: kPrimaryColor,
        primaryColorLight: kPrimaryColor.withAlpha(204), // 0.8 * 255 ≈ 204
        secondaryHeaderColor: kSecondaryColor,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kAccentColor,
          foregroundColor: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.white,
          scrimColor: Colors.black.withAlpha(15), // ~6% opacity ≈ 0.06 * 255 = 15
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: kSecondaryColor),
          bodyMedium: TextStyle(),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const NotesListPage(),
    );
  }
}

class Note {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({required this.id, required this.title, required this.content, required this.createdAt, this.updatedAt});

  // PUBLIC_INTERFACE
  static Note fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int,
      title: map['title'] as String,
      content: map['content'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] ?? '') : null,
    );
  }

  // PUBLIC_INTERFACE
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// NotesListPage: main listing with search, FAB for new, and drawer for navigation.
class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  List<Note> _notes = [];
  bool _loading = true;
  String? _error;

  // Called on page (re)load or after deletion/edit
  Future<void> _fetchNotes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await Supabase.instance.client
          .from(notesTable)
          .select()
          .order('created_at', ascending: false);
      final notesRaw = resp as List<dynamic>;
      setState(() => _notes = notesRaw.map((e) => Note.fromMap(e as Map<String, dynamic>)).toList());
    } catch (e) {
      setState(() => _error = 'Error fetching notes: $e');
    }
    setState(() => _loading = false);
  }

  // PUBLIC_INTERFACE
  void _searchNotes(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final filterPattern = '%${query.replaceAll('%', '\\%')}%';
      final notesRaw = await Supabase.instance.client
          .from(notesTable)
          .select()
          .or('title.ilike.$filterPattern,content.ilike.$filterPattern')
          .order('created_at', ascending: false);
      setState(() => _notes = (notesRaw as List<dynamic>).map((e) => Note.fromMap(e as Map<String, dynamic>)).toList());
    } catch (e) {
      setState(() => _error = 'Error searching notes: $e');
    }
    setState(() => _loading = false);
  }

  // Called on back from detail or on FAB add
  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _deleteNote(int noteId) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kAccentColor, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await Supabase.instance.client.from(notesTable).delete().eq('id', noteId);
        await _fetchNotes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note deleted.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
        }
      }
    }
  }

  void _openNoteDetail({Note? note, bool isEdit = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailPage(note: note, isEdit: isEdit),
      ),
    );
    _fetchNotes();
  }

  @override
  Widget build(BuildContext context) {
    // Simple AppDrawer with About, actions extendable
    final drawer = Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: kPrimaryColor,
              ),
              child: Text(
                'Notes Organizer',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: kSecondaryColor),
              title: const Text('About'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Simple Notes',
                applicationVersion: '1.0.0',
                applicationLegalese: 'A simple app for notes. Powered by Supabase.',
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchNotes,
          ),
        ],
      ),
      drawer: drawer,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Note',
        onPressed: () => _openNoteDetail(isEdit: true),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onChanged: (q) {
                if (q.trim().isEmpty) {
                  _fetchNotes();
                } else {
                  _searchNotes(q);
                }
              },
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 64.0),
              child: CircularProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (!_loading && _error == null && _notes.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No notes. Add one!', style: TextStyle(fontSize: 18)),
              ),
            ),
          if (!_loading && _notes.isNotEmpty)
            Expanded(
              child: ListView.separated(
                itemCount: _notes.length,
                separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                itemBuilder: (context, index) {
                  final n = _notes[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(
                      n.title,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: n.content.isNotEmpty
                        ? Text(
                            n.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _deleteNote(n.id),
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                    onTap: () => _openNoteDetail(note: n),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// NoteDetailPage: view, create, or edit a note.
/// If no note provided and isEdit=true, creates new.
/// If note provided and isEdit=true, edits.
/// If note provided, isEdit=false, view only. User can toggle to edit.
class NoteDetailPage extends StatefulWidget {
  final Note? note;
  final bool isEdit;

  // PUBLIC_INTERFACE
  const NoteDetailPage({super.key, this.note, required this.isEdit});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late bool _editing;
  late String _title;
  late String _content;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _editing = widget.isEdit;
    _title = widget.note?.title ?? '';
    _content = widget.note?.content ?? '';
  }

  // PUBLIC_INTERFACE
  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.note == null) {
        // Creating new note
        final insert = await Supabase.instance.client.from(notesTable).insert({
          'title': _title,
          'content': _content,
        }).select();
        // insert returns list
        if (insert.isEmpty) throw Exception("Note creation failed.");
      } else {
        // Updating note
        await Supabase.instance.client.from(notesTable).update({
          'title': _title,
          'content': _content,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.note!.id);
      }
      if (mounted) {
        Navigator.pop(context); // Return to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving note: $e')));
      }
    }
    setState(() => _saving = false);
  }

  Widget _buildView() {
    // Read-only view with edit button, timestamp, title/content
    final dt = widget.note?.updatedAt ?? widget.note?.createdAt;
    final timeString = dt != null ? 'Last updated: ${dt.toLocal().toString().substring(0, 16)}' : '';
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (timeString.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(timeString, style: const TextStyle(color: Colors.black54, fontSize: 14)),
            ),
          Text(widget.note?.title ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Text(widget.note?.content ?? '', style: const TextStyle(fontSize: 17)),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: kAccentColor, foregroundColor: Colors.black),
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEdit() {
    // Editing or creating form
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              initialValue: _title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              maxLength: 60,
              validator: (v) => v == null || v.trim().isEmpty ? 'Title required.' : null,
              onChanged: (v) => setState(() => _title = v),
              enabled: !_saving,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: TextFormField(
                initialValue: _content,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                minLines: 12,
                expands: false,
                validator: (v) => null,
                onChanged: (v) => setState(() => _content = v),
                enabled: !_saving,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.note != null)
                  TextButton(
                    onPressed: _saving ? null : () => setState(() => _editing = false),
                    child: const Text('Cancel'),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _saving ? null : _saveNote,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.note == null ? 'Create' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.note == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew
            ? 'Add Note'
            : _editing
                ? 'Edit Note'
                : 'Note'),
      ),
      body: SizedBox.expand(
        child: _editing ? _buildEdit() : _buildView(),
      ),
    );
  }
}
