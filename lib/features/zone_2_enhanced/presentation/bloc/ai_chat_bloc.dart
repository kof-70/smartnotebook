import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/usecases/analyze_notes.dart';
import '../../domain/usecases/text_to_speech.dart';
import '../../domain/usecases/chat_with_ai.dart';
import '../../domain/usecases/generate_tags.dart';
import '../../../../shared/services/audio_service.dart';

// Events
abstract class AIChatEvent extends Equatable {
  const AIChatEvent();

  @override
  List<Object?> get props => [];
}

class SendMessageEvent extends AIChatEvent {
  final String message;

  const SendMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class AnalyzeNotesEvent extends AIChatEvent {
  final List<String> noteIds;
  final String notesContent;

  const AnalyzeNotesEvent(this.noteIds, this.notesContent);

  @override
  List<Object?> get props => [noteIds, notesContent];
}

class GenerateSpeechEvent extends AIChatEvent {
  final String text;

  const GenerateSpeechEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class GenerateTagsEvent extends AIChatEvent {
  final String content;

  const GenerateTagsEvent(this.content);

  @override
  List<Object?> get props => [content];
}

class ClearChatEvent extends AIChatEvent {}

class LoadChatHistoryEvent extends AIChatEvent {}

// States
abstract class AIChatState extends Equatable {
  const AIChatState();

  @override
  List<Object?> get props => [];
}

class AIChatInitial extends AIChatState {}

class AIChatLoading extends AIChatState {
  final String? operation;

  const AIChatLoading({this.operation});

  @override
  List<Object?> get props => [operation];
}

class AIChatLoaded extends AIChatState {
  final List<ChatMessage> messages;

  const AIChatLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class AIChatError extends AIChatState {
  final String message;

  const AIChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class AIAnalysisCompleted extends AIChatState {
  final AIAnalysis analysis;
  final List<ChatMessage> messages;

  const AIAnalysisCompleted(this.analysis, this.messages);

  @override
  List<Object?> get props => [analysis, messages];
}

class AITagsGenerated extends AIChatState {
  final List<String> tags;
  final List<ChatMessage> messages;

  const AITagsGenerated(this.tags, this.messages);

  @override
  List<Object?> get props => [tags, messages];
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageType type;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = ChatMessageType.text,
  });

  Map<String, String> toConversationEntry() {
    return {
      'role': isUser ? 'user' : 'assistant',
      'content': content,
    };
  }
}

enum ChatMessageType {
  text,
  analysis,
  tags,
  error,
  speech,
}

// Bloc
class AIChatBloc extends Bloc<AIChatEvent, AIChatState> {
  final AnalyzeNotes _analyzeNotes;
  final TextToSpeech _textToSpeech;
  final ChatWithAI _chatWithAI;
  final GenerateTags _generateTags;
  final AudioService _audioService;
  final List<ChatMessage> _messages = [];

  AIChatBloc({
    required AnalyzeNotes analyzeNotes,
    required TextToSpeech textToSpeech,
    required ChatWithAI chatWithAI,
    required GenerateTags generateTags,
    required AudioService audioService,
  })  : _analyzeNotes = analyzeNotes,
        _textToSpeech = textToSpeech,
        _chatWithAI = chatWithAI,
        _generateTags = generateTags,
        _audioService = audioService,
        super(AIChatInitial()) {
    on<SendMessageEvent>(_onSendMessage);
    on<AnalyzeNotesEvent>(_onAnalyzeNotes);
    on<GenerateSpeechEvent>(_onGenerateSpeech);
    on<GenerateTagsEvent>(_onGenerateTags);
    on<ClearChatEvent>(_onClearChat);
    on<LoadChatHistoryEvent>(_onLoadChatHistory);
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<AIChatState> emit,
  ) async {
    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    _messages.add(userMessage);
    emit(AIChatLoaded(List.from(_messages)));
    
    // Show loading state
    emit(const AIChatLoading(operation: 'Thinking...'));

    try {
      // Build conversation history for context
      final conversationHistory = _messages
          .where((msg) => msg.type == ChatMessageType.text)
          .map((msg) => msg.toConversationEntry())
          .toList();

      // Get AI response
      final result = await _chatWithAI(ChatWithAIParams(
        message: event.message,
        conversationHistory: conversationHistory.take(10).toList(), // Limit context
      ));

      result.fold(
        (failure) {
          final errorMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: 'Sorry, I encountered an error: ${failure.message}',
            isUser: false,
            timestamp: DateTime.now(),
            type: ChatMessageType.error,
          );
          _messages.add(errorMessage);
          emit(AIChatError(failure.message));
        },
        (response) {
          final aiMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: response,
            isUser: false,
            timestamp: DateTime.now(),
          );
          _messages.add(aiMessage);
          emit(AIChatLoaded(List.from(_messages)));
        },
      );
    } catch (e) {
      emit(AIChatError('Unexpected error: ${e.toString()}'));
    }
  }

  Future<void> _onAnalyzeNotes(
    AnalyzeNotesEvent event,
    Emitter<AIChatState> emit,
  ) async {
    emit(const AIChatLoading(operation: 'Analyzing notes...'));
    
    try {
      final result = await _analyzeNotes(AnalyzeNotesParams(event.noteIds, event.notesContent));
      
      result.fold(
        (failure) {
          final errorMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: 'Failed to analyze notes: ${failure.message}',
            isUser: false,
            timestamp: DateTime.now(),
            type: ChatMessageType.error,
          );
          _messages.add(errorMessage);
          emit(AIChatError(failure.message));
        },
        (analysis) {
          final analysisMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: 'Analysis complete! Here\'s what I found:\n\n${analysis.summary}\n\nKeywords: ${analysis.keywords.join(', ')}\n\nSuggestions:\n${analysis.suggestions.map((s) => '• $s').join('\n')}',
            isUser: false,
            timestamp: DateTime.now(),
            type: ChatMessageType.analysis,
          );
          _messages.add(analysisMessage);
          emit(AIAnalysisCompleted(analysis, List.from(_messages)));
        },
      );
    } catch (e) {
      emit(AIChatError('Unexpected error during analysis: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateTags(
    GenerateTagsEvent event,
    Emitter<AIChatState> emit,
  ) async {
    emit(const AIChatLoading(operation: 'Generating tags...'));
    
    try {
      final result = await _generateTags(GenerateTagsParams(event.content));
      
      result.fold(
        (failure) {
          final errorMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: 'Failed to generate tags: ${failure.message}',
            isUser: false,
            timestamp: DateTime.now(),
            type: ChatMessageType.error,
          );
          _messages.add(errorMessage);
          emit(AIChatError(failure.message));
        },
        (tags) {
          final tagsMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: 'I\'ve generated these tags for your content:\n\n${tags.join(', ')}',
            isUser: false,
            timestamp: DateTime.now(),
            type: ChatMessageType.tags,
          );
          _messages.add(tagsMessage);
          emit(AITagsGenerated(tags, List.from(_messages)));
        },
      );
    } catch (e) {
      emit(AIChatError('Unexpected error generating tags: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateSpeech(
    GenerateSpeechEvent event,
    Emitter<AIChatState> emit,
  ) async {
    emit(const AIChatLoading(operation: 'Generating speech...'));
    
    try {
      final result = await _textToSpeech(TextToSpeechParams(event.text));
      
      result.fold(
        (failure) {
          final errorMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: 'Failed to generate speech: ${failure.message}',
            isUser: false,
            timestamp: DateTime.now(),
            type: ChatMessageType.error,
          );
          _messages.add(errorMessage);
          emit(AIChatError(failure.message));
        },
        (audioPath) {
          final speechMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: 'Speech generated successfully! Playing audio...',
            isUser: false,
            timestamp: DateTime.now(),
            type: ChatMessageType.speech,
          );
          _messages.add(speechMessage);
          
          // Play the generated audio
          _audioService.playAudio(audioPath);
          
          emit(AIChatLoaded(List.from(_messages)));
        },
      );
    } catch (e) {
      emit(AIChatError('Unexpected error generating speech: ${e.toString()}'));
    }
  }

  void _onClearChat(
    ClearChatEvent event,
    Emitter<AIChatState> emit,
  ) {
    _messages.clear();
    emit(AIChatInitial());
  }

  void _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<AIChatState> emit,
  ) {
    if (_messages.isEmpty) {
      emit(AIChatInitial());
    } else {
      emit(AIChatLoaded(List.from(_messages)));
    }
  }
}