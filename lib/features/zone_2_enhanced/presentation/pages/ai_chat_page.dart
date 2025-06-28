import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/ai_chat_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/config/api_config.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isApiConfigured = false;

  @override
  void initState() {
    super.initState();
    _checkApiConfiguration();
    context.read<AIChatBloc>().add(LoadChatHistoryEvent());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkApiConfiguration() async {
    final isConfigured = await ApiConfig.isOpenAIConfigured();
    setState(() {
      _isApiConfigured = isConfigured;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showApiConfigDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  context.read<AIChatBloc>().add(ClearChatEvent());
                  break;
                case 'config':
                  _showApiConfigDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Chat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'config',
                child: Row(
                  children: [
                    Icon(Icons.api),
                    SizedBox(width: 8),
                    Text('API Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isApiConfigured) _buildApiWarning(theme),
          Expanded(child: _buildChatArea()),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildApiWarning(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacing16),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: AppConstants.spacing8),
          Expanded(
            child: Text(
              'OpenAI API key not configured. Tap settings to configure.',
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _showApiConfigDialog,
            child: Text(
              'Configure',
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return BlocBuilder<AIChatBloc, AIChatState>(
      builder: (context, state) {
        if (state is AIChatInitial) {
          return _buildWelcomeScreen();
        }
        
        if (state is AIChatLoading) {
          return _buildLoadingScreen(state.operation);
        }
        
        if (state is AIChatLoaded || 
            state is AIAnalysisCompleted || 
            state is AITagsGenerated) {
          List<ChatMessage> messages = [];
          
          if (state is AIChatLoaded) {
            messages = state.messages;
          } else if (state is AIAnalysisCompleted) {
            messages = state.messages;
          } else if (state is AITagsGenerated) {
            messages = state.messages;
          }
          
          return _buildMessagesList(messages);
        }
        
        if (state is AIChatError) {
          return _buildErrorScreen(state.message);
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWelcomeScreen() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology,
                size: 64,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            
            const SizedBox(height: AppConstants.spacing24),
            
            Text(
              'AI Assistant',
              style: theme.textTheme.headlineSmall,
            ),
            
            const SizedBox(height: AppConstants.spacing16),
            
            Text(
              'Ask me anything about your notes, get insights, or just have a conversation!',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppConstants.spacing32),
            
            Wrap(
              spacing: AppConstants.spacing8,
              runSpacing: AppConstants.spacing8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Analyze my notes'),
                _buildSuggestionChip('Generate tags'),
                _buildSuggestionChip('Summarize content'),
                _buildSuggestionChip('Help me organize'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    final theme = Theme.of(context);
    
    return ActionChip(
      label: Text(text),
      onPressed: _isApiConfigured ? () {
        _messageController.text = text;
        _sendMessage();
      } : null,
      backgroundColor: theme.colorScheme.surfaceVariant,
      labelStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildLoadingScreen(String? operation) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppConstants.spacing16),
          Text(
            operation ?? 'Processing...',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppConstants.spacing16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spacing8),
            Text(
              error,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacing24),
            ElevatedButton(
              onPressed: () {
                context.read<AIChatBloc>().add(LoadChatHistoryEvent());
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<ChatMessage> messages) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppConstants.spacing16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacing12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing16),
              decoration: BoxDecoration(
                color: isUser 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.spacing16).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == ChatMessageType.analysis) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          size: 16,
                          color: isUser 
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Analysis',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isUser 
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  if (message.type == ChatMessageType.tags) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.label,
                          size: 16,
                          color: isUser 
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tags',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isUser 
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (message.type == ChatMessageType.speech) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.volume_up,
                          size: 16,
                          color: isUser 
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Speech',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isUser 
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser 
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 4),
            
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppDateUtils.formatForDisplay(message.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
                
                // Add TTS button for AI messages
                if (!isUser && message.type != ChatMessageType.speech) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      context.read<AIChatBloc>().add(GenerateSpeechEvent(message.content));
                    },
                    icon: Icon(
                      Icons.volume_up,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: _isApiConfigured 
                    ? 'Ask me anything...'
                    : 'Configure API key first',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacing16,
                  vertical: AppConstants.spacing12,
                ),
              ),
              enabled: _isApiConfigured,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _isApiConfigured ? (_) => _sendMessage() : null,
            ),
          ),
          
          const SizedBox(width: AppConstants.spacing8),
          
          BlocBuilder<AIChatBloc, AIChatState>(
            builder: (context, state) {
              final isLoading = state is AIChatLoading;
              
              return IconButton(
                onPressed: _isApiConfigured && !isLoading ? _sendMessage : null,
                icon: isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      context.read<AIChatBloc>().add(SendMessageEvent(message));
      _messageController.clear();
    }
  }

  void _showApiConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => const ApiConfigDialog(),
    ).then((_) {
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
    
    setState(() {
      _apiKeyController.text = apiKey ?? '';
      _modelController.text = model;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('OpenAI API Configuration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              labelText: 'Model',
              hintText: 'gpt-3.5-turbo',
              border: OutlineInputBorder(),
            ),
            enabled: !_isLoading,
          ),
          
          const SizedBox(height: AppConstants.spacing16),
          
          Text(
            'Get your API key from OpenAI Dashboard. Keep it secure and never share it.',
            style: theme.textTheme.bodySmall,
          ),
        ],
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
      _showError('Invalid API key format');
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
          const SnackBar(content: Text('API configuration saved')),
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
          const SnackBar(content: Text('API key removed')),
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