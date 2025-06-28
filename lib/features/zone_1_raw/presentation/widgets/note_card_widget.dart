import 'package:flutter/material.dart';
import '../../domain/entities/note.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_utils.dart';

class NoteCardWidget extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteCardWidget({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacing12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title.isNotEmpty ? note.title : 'Untitled',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildNoteTypeIcon(theme),
                  const SizedBox(width: AppConstants.spacing8),
                  _buildSyncStatusIcon(theme),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacing8),
                Text(
                  note.content,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacing12),
                Wrap(
                  spacing: AppConstants.spacing8,
                  runSpacing: AppConstants.spacing4,
                  children: note.tags.take(3).map((tag) => _buildTag(theme, tag)).toList(),
                ),
              ],
              
              if (note.mediaFiles.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacing8),
                Row(
                  children: [
                    Icon(
                      Icons.attachment,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppConstants.spacing4),
                    Text(
                      '${note.mediaFiles.length} attachment${note.mediaFiles.length > 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: AppConstants.spacing12),
              Row(
                children: [
                  Text(
                    AppDateUtils.formatForDisplay(
                      AppDateUtils.fromIsoString(note.updatedAt),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (note.aiAnalysis != null)
                    Icon(
                      Icons.psychology,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTypeIcon(ThemeData theme) {
    IconData icon;
    switch (note.type) {
      case NoteType.audio:
        icon = Icons.mic;
        break;
      case NoteType.video:
        icon = Icons.videocam;
        break;
      case NoteType.image:
        icon = Icons.image;
        break;
      case NoteType.mixed:
        icon = Icons.collections;
        break;
      default:
        icon = Icons.text_snippet;
    }
    
    return Icon(
      icon,
      size: 16,
      color: theme.colorScheme.primary,
    );
  }

  Widget _buildSyncStatusIcon(ThemeData theme) {
    IconData icon;
    Color color;
    
    switch (note.syncStatus) {
      case 'synced':
        icon = Icons.cloud_done;
        color = theme.colorScheme.primary;
        break;
      case 'syncing':
        icon = Icons.cloud_sync;
        color = theme.colorScheme.secondary;
        break;
      case 'error':
        icon = Icons.cloud_off;
        color = theme.colorScheme.error;
        break;
      default:
        icon = Icons.cloud_queue;
        color = theme.colorScheme.onSurfaceVariant;
    }
    
    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  Widget _buildTag(ThemeData theme, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing8,
        vertical: AppConstants.spacing4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppConstants.spacing8),
      ),
      child: Text(
        tag,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}