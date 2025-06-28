import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/api_config.dart';
import '../../../zone_1_raw/presentation/bloc/note_bloc.dart';
import '../../../zone_1_raw/domain/entities/note.dart';
import '../bloc/ai_chat_bloc.dart';
import 'ai_chat_page.dart';

class EnhancedZonePage extends StatefulWidget {
  const EnhancedZonePage({super.key});

  @override
  State<EnhancedZonePage> createState() => _EnhancedZonePageState();
}

class _EnhancedZonePageState extends State<EnhancedZonePage> {
  bool _isApiConfigured = false;
  List<Note> _availableNotes = [];

  @override
  void initState() {
    super.initState();
    _checkApiConfiguration();
    _loadNotes();
  }

  Future<void> _checkApiConfiguration() async {
    final isConfigured = await ApiConfig.isOpenAIConfigured();
    if (mounted) {
      setState(() {
        _isApiConfigured = isConfigured;
      });
    }
  }

  void _loadNotes() {
    context.read<NoteBloc>().add(LoadNotesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: BlocListener<NoteBloc, NoteState>(
        listener: (context, state) {
          if (state is NotesLoaded) {
            setState(() {
              _availableNotes = state.notes;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacing16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacing24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.psychology,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: AppConstants.spacing16),
                      Text(
                        'Enhanced Me',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppConstants.spacing8),
                      Text(
                        'AI-powered analysis and insights for your notes',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      
                      if (!_isApiConfigured) ...[
                        const SizedBox(height: AppConstants.spacing16),
                        Container(
                          padding: const EdgeInsets.all(AppConstants.spacing12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(AppConstants.spacing8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: theme.colorScheme.onErrorContainer,
                                size: 20,
                              ),
                              const SizedBox(width: AppConstants.spacing8),
                              Expanded(
                                child: Text(
                                  'OpenAI API key required for AI features',
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_availableNotes.isEmpty && _isApiConfigured) ...[
                        const SizedBox(height: AppConstants.spacing16),
                        Container(
                          padding: const EdgeInsets.all(AppConstants.spacing12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppConstants.spacing8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: AppConstants.spacing8),
                              Expanded(
                                child: Text(
                                  'Create some notes first to use AI analysis features',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.spacing24),
              
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppConstants.spacing16,
                  mainAxisSpacing: AppConstants.spacing16,
                  children: [
                    _buildFeatureCard(
                      context,
                      icon: Icons.chat,
                      title: 'AI Chat',
                      subtitle: 'Ask questions about your notes',
                      onTap: () => _openAIChat(context),
                      enabled: _isApiConfigured,
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.analytics,
                      title: 'Analysis',
                      subtitle: 'Get insights and summaries',
                      onTap: () => _openAnalysis(context),
                      enabled: _isApiConfigured && _availableNotes.isNotEmpty,
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.auto_awesome,
                      title: 'Smart Tags',
                      subtitle: 'AI-generated tags',
                      onTap: () => _openSmartTags(context),
                      enabled: _isApiConfigured && _availableNotes.isNotEmpty,
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.settings,
                      title: 'API Settings',
                      subtitle: 'Configure OpenAI API',
                      onTap: () => _openApiSettings(context),
                      enabled: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacing16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacing16),
                decoration: BoxDecoration(
                  color: enabled 
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppConstants.spacing16),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: enabled 
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: AppConstants.spacing12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: enabled 
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacing4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: enabled 
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAIChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AIChatPage(),
      ),
    );
  }

  void _openAnalysis(BuildContext context) {
    if (_availableNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No notes available for analysis')),
      );
      return;
    }

    _showNoteSelectionDialog(
      context,
      title: 'Analyze Notes',
      subtitle: 'Select notes to analyze with AI',
      onNotesSelected: (selectedNotes) {
        final notesContent = selectedNotes
            .map((note) => '${note.title}\n${note.content}')
            .join('\n\n---\n\n');
        
        final noteIds = selectedNotes.map((note) => note.id).toList();
        
        context.read<AIChatBloc>().add(AnalyzeNotesEvent(noteIds, notesContent));
        _openAIChat(context);
      },
    );
  }

  void _openSmartTags(BuildContext context) {
    if (_availableNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No notes available for tag generation')),
      );
      return;
    }

    _showNoteSelectionDialog(
      context,
      title: 'Generate Smart Tags',
      subtitle: 'Select a note to generate AI-powered tags',
      singleSelection: true,
      onNotesSelected: (selectedNotes) {
        if (selectedNotes.isNotEmpty) {
          final note = selectedNotes.first;
          final content = '${note.title}\n${note.content}';
          
          context.read<AIChatBloc>().add(GenerateTagsEvent(content));
          _openAIChat(context);
        }
      },
    );
  }

  void _showNoteSelectionDialog(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Function(List<Note>) onNotesSelected,
    bool singleSelection = false,
  }) {
    final selectedNotes = <Note>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle),
                const SizedBox(height: AppConstants.spacing16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _availableNotes.length,
                    itemBuilder: (context, index) {
                      final note = _availableNotes[index];
                      final isSelected = selectedNotes.contains(note);
                      
                      return CheckboxListTile(
                        title: Text(
                          note.title.isNotEmpty ? note.title : 'Untitled',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (singleSelection) {
                              selectedNotes.clear();
                              if (value == true) {
                                selectedNotes.add(note);
                              }
                            } else {
                              if (value == true) {
                                selectedNotes.add(note);
                              } else {
                                selectedNotes.remove(note);
                              }
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedNotes.isEmpty ? null : () {
                Navigator.of(context).pop();
                onNotesSelected(selectedNotes.toList());
              },
              child: Text(singleSelection ? 'Generate Tags' : 'Analyze'),
            ),
          ],
        ),
      ),
    );
  }

  void _openApiSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ApiConfigDialog(),
    ).then((_) {
      // Refresh API configuration status after dialog closes
      _checkApiConfiguration();
    });
  }
}

class ApiConfigDialog extends StatefulWidget {
  const ApiConfigDialog({super.key});

  @override
  State<ApiConfigDialog> createState() => _ApiConfigDialogState();
}

class _ApiConfigDialogState extends State<ApiConfigDialog> {
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  bool _isLoading = false;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfig() async {
    final apiKey = await ApiConfig.getOpenAIApiKey();
    final model = await ApiConfig.getOpenAIModel();
    
    if (mounted) {
      setState(() {
        _apiKeyController.text = apiKey ?? '';
        _modelController.text = model;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('OpenAI API Configuration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure your OpenAI API key to enable AI features.',
              style: theme.textTheme.bodyMedium,
            ),
            
            const SizedBox(height: AppConstants.spacing16),
            
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                ),
              ),
              obscureText: _obscureApiKey,
              enabled: !_isLoading,
            ),
            
            const SizedBox(height: AppConstants.spacing16),
            
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model (optional)',
                hintText: 'gpt-3.5-turbo',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),
            
            const SizedBox(height: AppConstants.spacing16),
            
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.spacing8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to get your API key:',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Go to platform.openai.com\n'
                    '2. Sign in or create an account\n'
                    '3. Navigate to API Keys section\n'
                    '4. Create a new secret key\n'
                    '5. Copy and paste it here',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.spacing8),
            
            Text(
              'Your API key is stored securely on your device and never shared.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        
        if (_apiKeyController.text.isNotEmpty)
          TextButton(
            onPressed: _isLoading ? null : _removeApiKey,
            child: Text(
              'Remove',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        
        ElevatedButton(
          onPressed: _isLoading ? null : _saveConfig,
          child: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveConfig() async {
    final apiKey = _apiKeyController.text.trim();
    final model = _modelController.text.trim();
    
    if (apiKey.isEmpty) {
      _showError('Please enter an API key');
      return;
    }
    
    if (!ApiConfig.isValidOpenAIApiKey(apiKey)) {
      _showError('Invalid API key format. Should start with "sk-"');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ApiConfig.setOpenAIApiKey(apiKey);
      if (model.isNotEmpty) {
        await ApiConfig.setOpenAIModel(model);
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API configuration saved successfully')),
        );
      }
    } catch (e) {
      _showError('Failed to save configuration: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeApiKey() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ApiConfig.removeOpenAIApiKey();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key removed successfully')),
        );
      }
    } catch (e) {
      _showError('Failed to remove API key: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}