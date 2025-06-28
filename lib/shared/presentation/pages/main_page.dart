import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/zone_1_raw/presentation/pages/raw_zone_page.dart';
import '../../../features/zone_2_enhanced/presentation/pages/enhanced_zone_page.dart';
import '../../../features/zone_1_raw/presentation/bloc/search_bloc.dart';
import '../../../features/sync/presentation/bloc/sync_bloc.dart';
import '../../../features/sync/presentation/widgets/sync_status_widget.dart';
import '../../../features/zone_1_raw/domain/entities/note.dart';
import '../../../features/zone_1_raw/presentation/widgets/note_card_widget.dart';
import '../../../features/zone_1_raw/presentation/pages/note_detail_page.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/data/preferences/app_preferences.dart';
import '../../../injection_container.dart' as di;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const RawZonePage(),
    const EnhancedZonePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize sync status check
    context.read<SyncBloc>().add(CheckSyncStatusEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle()),
        actions: [
          const SyncStatusWidget(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.note_outlined),
            activeIcon: Icon(Icons.note),
            label: 'Raw Me',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_outlined),
            activeIcon: Icon(Icons.psychology),
            label: 'Enhanced Me',
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Raw Me';
      case 1:
        return 'Enhanced Me';
      default:
        return 'Smart Notebook';
    }
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: NotesSearchDelegate(),
    );
  }

  void _showSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }
}

class NotesSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text('Enter a search term to find notes'),
      );
    }

    // Trigger search when query changes
    context.read<SearchBloc>().add(SearchNotesEvent(query));

    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is SearchLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (state is SearchError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppConstants.spacing16),
                Text(
                  'Search Error',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppConstants.spacing8),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        if (state is SearchLoaded) {
          if (state.notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppConstants.spacing16),
                  Text(
                    'No notes found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  Text(
                    'Try searching with different keywords',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacing16),
            itemCount: state.notes.length,
            itemBuilder: (context, index) {
              final note = state.notes[index];
              return NoteCardWidget(
                note: note,
                onTap: () => _openNote(context, note),
                onDelete: () => _deleteNote(context, note.id),
              );
            },
          );
        }
        
        return const Center(
          child: Text('Start typing to search notes'),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppConstants.spacing16),
            Text(
              'Search your notes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spacing8),
            Text(
              'Find notes by title, content, or tags',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show search suggestions based on partial query
    final suggestions = _getSearchSuggestions(query);
    
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(suggestion),
          onTap: () {
            query = suggestion;
            showResults(context);
          },
        );
      },
    );
  }

  List<String> _getSearchSuggestions(String query) {
    // This would typically come from search history or popular searches
    // For now, we'll provide some basic suggestions
    final suggestions = <String>[
      'meeting notes',
      'project ideas',
      'voice recordings',
      'photos',
      'important',
      'todo',
      'work',
      'personal',
    ];
    
    return suggestions
        .where((suggestion) => 
            suggestion.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();
  }

  void _openNote(BuildContext context, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteDetailPage(note: note),
      ),
    );
  }

  void _deleteNote(BuildContext context, String noteId) {
    // This would typically show a confirmation dialog
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete functionality not implemented in search')),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppPreferences _preferences = di.sl<AppPreferences>();
  
  String _themeMode = 'system';
  bool _biometricEnabled = false;
  bool _autoSyncEnabled = true;
  bool _aiAnalysisEnabled = true;
  bool _encryptionEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final themeMode = await _preferences.getThemeMode();
    final biometricEnabled = await _preferences.getBiometricEnabled();
    final autoSyncEnabled = await _preferences.getAutoSyncEnabled();
    final aiAnalysisEnabled = await _preferences.getAIAnalysisEnabled();
    final encryptionEnabled = await _preferences.getEncryptionEnabled();

    setState(() {
      _themeMode = themeMode;
      _biometricEnabled = biometricEnabled;
      _autoSyncEnabled = autoSyncEnabled;
      _aiAnalysisEnabled = aiAnalysisEnabled;
      _encryptionEnabled = encryptionEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        children: [
          _buildSettingsSection(
            context,
            title: 'Appearance',
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: _getThemeDisplayName(_themeMode),
                onTap: () => _showThemeDialog(context),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacing24),
          
          _buildSettingsSection(
            context,
            title: 'Security',
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.fingerprint,
                title: 'Biometric Authentication',
                subtitle: 'Use fingerprint or face unlock',
                trailing: Switch(
                  value: _biometricEnabled,
                  onChanged: (value) async {
                    await _preferences.setBiometricEnabled(value);
                    setState(() {
                      _biometricEnabled = value;
                    });
                  },
                ),
              ),
              _buildSettingsTile(
                context,
                icon: Icons.lock_outline,
                title: 'Encryption',
                subtitle: 'Encrypt notes locally',
                trailing: Switch(
                  value: _encryptionEnabled,
                  onChanged: (value) async {
                    await _preferences.setEncryptionEnabled(value);
                    setState(() {
                      _encryptionEnabled = value;
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacing24),
          
          _buildSettingsSection(
            context,
            title: 'Sync & Backup',
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.sync,
                title: 'Auto Sync',
                subtitle: 'Automatically sync notes',
                trailing: Switch(
                  value: _autoSyncEnabled,
                  onChanged: (value) async {
                    await _preferences.setAutoSyncEnabled(value);
                    setState(() {
                      _autoSyncEnabled = value;
                    });
                  },
                ),
              ),
              _buildSettingsTile(
                context,
                icon: Icons.cloud_upload_outlined,
                title: 'Backup Settings',
                subtitle: 'Configure backup options',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup settings coming soon')),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacing24),
          
          _buildSettingsSection(
            context,
            title: 'AI Features',
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.psychology_outlined,
                title: 'AI Analysis',
                subtitle: 'Enable AI-powered insights',
                trailing: Switch(
                  value: _aiAnalysisEnabled,
                  onChanged: (value) async {
                    await _preferences.setAIAnalysisEnabled(value);
                    setState(() {
                      _aiAnalysisEnabled = value;
                    });
                  },
                ),
              ),
              _buildSettingsTile(
                context,
                icon: Icons.auto_awesome,
                title: 'Smart Tags',
                subtitle: 'Auto-generate tags for notes',
                trailing: Switch(
                  value: _aiAnalysisEnabled, // Using same setting for now
                  onChanged: (value) async {
                    await _preferences.setAIAnalysisEnabled(value);
                    setState(() {
                      _aiAnalysisEnabled = value;
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacing24),
          
          _buildSettingsSection(
            context,
            title: 'About',
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.info_outline,
                title: 'App Version',
                subtitle: AppConstants.appVersion,
              ),
              _buildSettingsTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy policy coming soon')),
                  );
                },
              ),
              _buildSettingsTile(
                context,
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Terms of service coming soon')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppConstants.spacing16, bottom: AppConstants.spacing8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  String _getThemeDisplayName(String themeMode) {
    switch (themeMode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System Default';
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('System Default'),
              value: 'system',
              groupValue: _themeMode,
              onChanged: (value) async {
                if (value != null) {
                  await _preferences.setThemeMode(value);
                  setState(() {
                    _themeMode = value;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: _themeMode,
              onChanged: (value) async {
                if (value != null) {
                  await _preferences.setThemeMode(value);
                  setState(() {
                    _themeMode = value;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: _themeMode,
              onChanged: (value) async {
                if (value != null) {
                  await _preferences.setThemeMode(value);
                  setState(() {
                    _themeMode = value;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}