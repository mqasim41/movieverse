import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/chat_message.dart';
import '../services/openai_service.dart';
import '../widgets/chat/chat_message_bubble.dart';
import '../config/theme.dart';

class ChatScreen extends StatefulWidget {
  final Movie movie;

  const ChatScreen({
    super.key,
    required this.movie,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add initial greeting
    if (OpenAIService.isInitialized) {
      _addAssistantMessage(
        'Hi! I\'m MovieVerse AI. Ask me anything about "${widget.movie.title}"!',
      );
    } else {
      _addAssistantMessage(
        'Hi! I\'m MovieVerse AI, but I\'m currently unavailable because the OpenAI API key is not configured. '
        'Please make sure the OPENAI_API_KEY is set in the .env file.',
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    // Clear input field
    _messageController.clear();

    // Keep focus on input
    _inputFocusNode.requestFocus();

    // Add user message to chat
    setState(() {
      _messages.add(ChatMessage.user(text));
      _isTyping = true;
      _messages.add(ChatMessage.loading());
    });

    // Scroll to bottom
    _scrollToBottom();

    // Convert messages to map format for API
    final chatHistory = _getChatHistory();

    // Call API
    try {
      final response = await OpenAIService.sendMessage(
        message: text,
        movie: widget.movie,
        chatHistory: chatHistory,
      );

      // Replace loading message with response
      if (mounted) {
        setState(() {
          // Remove loading message
          _messages.removeLast();
          _isTyping = false;

          // Add assistant response
          _addAssistantMessage(response);
        });
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        setState(() {
          // Remove loading message
          _messages.removeLast();
          _isTyping = false;

          // Add error message
          _addAssistantMessage(
            'Sorry, I encountered an error: ${e.toString()}',
          );
        });
      }
    }

    // Scroll to bottom again after response
    _scrollToBottom();
  }

  void _addAssistantMessage(String text) {
    setState(() {
      _messages.add(ChatMessage.assistant(text));
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    // Delayed to ensure the list is built
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Convert chat history to format needed for API
  List<Map<String, String>> _getChatHistory() {
    final List<Map<String, String>> chatHistory = [];

    // Filter out loading messages and convert to API format
    for (final message in _messages) {
      if (!message.isLoading) {
        chatHistory.add(message.toMap());
      }
    }

    return chatHistory;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool apiAvailable = OpenAIService.isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Movie Chat',
              style: theme.textTheme.titleMedium,
            ),
            Text(
              widget.movie.title,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show info dialog about this feature
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Movie Chat'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This chat uses AI to answer your questions about this movie. '
                        'The AI has access to general knowledge about movies, actors, '
                        'directors, and more.\n\n'
                        'Ask about the plot, characters, behind the scenes info, '
                        'or similar movies you might enjoy!',
                      ),
                      const SizedBox(height: 16),
                      if (!OpenAIService.isInitialized)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'The OpenAI API is not configured. '
                                  'Make sure OPENAI_API_KEY is set in your .env file.',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatMessageBubble(message: _messages[index]);
              },
            ),
          ),

          // Input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Message input field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _inputFocusNode,
                    decoration: InputDecoration(
                      hintText: apiAvailable
                          ? 'Ask about the movie...'
                          : 'Chat unavailable - API key not configured',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted:
                        (_isTyping || !apiAvailable) ? null : _handleSubmitted,
                    enabled: !_isTyping && apiAvailable,
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                Container(
                  decoration: BoxDecoration(
                    color: apiAvailable
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: theme.colorScheme.onPrimary,
                    ),
                    onPressed: (_isTyping || !apiAvailable)
                        ? null
                        : () => _handleSubmitted(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
