import 'package:flutter/material.dart';
import '../db/db_helper.dart';

class HistorySheet extends StatefulWidget {
  final String type;
  final Color accent;
  const HistorySheet({super.key, required this.type, required this.accent});

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet> {
  List<HistoryEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DBHelper().fetchAll(type: widget.type);
    if (mounted) setState(() { _entries = data; _loading = false; });
  }

  Future<void> _clearAll() async {
    await DBHelper().deleteAll(type: widget.type);
    _load();
  }

  Future<void> _deleteOne(int id) async {
    await DBHelper().deleteById(id);
    _load();
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: widget.accent, size: 22),
                const SizedBox(width: 8),
                const Text('History',
                    style: TextStyle(color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_entries.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF2D2D44),
                          title: const Text('Clear History',
                              style: TextStyle(color: Colors.white)),
                          content: const Text('Delete all entries?',
                              style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true),
                                child: Text('Clear',
                                    style: TextStyle(color: Colors.red.shade400))),
                          ],
                        ),
                      );
                      if (ok == true) _clearAll();
                    },
                    icon: Icon(Icons.delete_sweep, color: Colors.red.shade400, size: 18),
                    label: Text('Clear', style: TextStyle(color: Colors.red.shade400)),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // List
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: widget.accent))
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history_toggle_off,
                                color: Colors.white24, size: 56),
                            const SizedBox(height: 12),
                            const Text('No history yet',
                                style: TextStyle(color: Colors.white38, fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _entries.length,
                        itemBuilder: (_, i) {
                          final e = _entries[i];
                          return Dismissible(
                            key: ValueKey(e.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red.shade900,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => _deleteOne(e.id!),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: widget.accent.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e.expression,
                                            style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 12)),
                                        const SizedBox(height: 2),
                                        Text(e.result,
                                            style: TextStyle(
                                                color: widget.accent,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Text(_timeAgo(e.timestamp),
                                      style: const TextStyle(
                                          color: Colors.white30, fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
