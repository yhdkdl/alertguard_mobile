import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../contacts/presentation/screens/contact_screen.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../widgets/setup_checklist.dart';
import '_sos_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTab = 0;

  void switchTab(int index) {
    setState(() => _currentTab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          // SOS tab gets the bottom sheet treatment
          _SosTabWithChecklist(onSwitchTab: switchTab),
          const ContactsScreen(),
          const HistoryScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'SOS',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Wraps SosTab with a persistent bottom sheet checklist
class _SosTabWithChecklist extends ConsumerStatefulWidget {
  final Function(int) onSwitchTab;
  const _SosTabWithChecklist({required this.onSwitchTab});

  @override
  ConsumerState<_SosTabWithChecklist> createState() =>
      _SosTabWithChecklistState();
}

class _SosTabWithChecklistState extends ConsumerState<_SosTabWithChecklist> {
  static const double _collapsedSize = 0.1;
  static const double _expandedSize = 0.55;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  Future<void> _toggleSheet() async {
    if (!_sheetController.isAttached) return;

    final isExpanded = _sheetController.size > 0.2;
    final target = isExpanded ? _collapsedSize : _expandedSize;

    await _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusState = ref.watch(setupStatusProvider);

    final isComplete = statusState.when(
      data: (s) => s.isComplete,
      loading: () => false,
      error: (_, __) => false,
    );

    // Once setup is complete — just the SOS tab, no sheet
    if (isComplete) {
      return SosTab(onSwitchTab: widget.onSwitchTab);
    }

    // Setup incomplete — wrap with persistent bottom sheet
    return Stack(
      children: [
        // Full SOS tab — never pushed or shrunk
        SosTab(onSwitchTab: widget.onSwitchTab),

        // Draggable sheet at the bottom
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: _collapsedSize, // collapsed — just the handle visible
          minChildSize: _collapsedSize, // minimum: handle only
          maxChildSize: _expandedSize, // maximum: half screen
          snap: true,
          snapSizes: const [_collapsedSize, _expandedSize],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // Drag handle + summary row
                  _SheetHandle(statusState: statusState, onTap: _toggleSheet),

                  // Full checklist content
                  // Only rendered when sheet is expanded
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: SetupChecklist(onSwitchTab: widget.onSwitchTab),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  final AsyncValue<SetupStatus> statusState;
  final VoidCallback onTap;
  const _SheetHandle({required this.statusState, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = statusState.maybeWhen(
      data: (s) => _completedCount(s),
      orElse: () => 0,
    );

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          // Visual drag handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Summary row — visible even when collapsed
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.checklist_rounded,
                    color: Colors.orange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Setup checklist',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$count of 3 steps complete — tap to expand/collapse',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Progress indicator
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: count / 3,
                        strokeWidth: 3,
                        backgroundColor: Colors.orange.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                      ),
                      Text(
                        '$count/3',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  int _completedCount(SetupStatus s) {
    int c = 0;
    if (s.hasContact) c++;
    if (s.hasVerifiedContact) c++;
    if (s.hasTelegramConnected) c++;
    return c;
  }
}
