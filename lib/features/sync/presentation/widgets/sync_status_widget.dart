import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/sync_bloc.dart';
import '../../../../core/utils/date_utils.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        return IconButton(
          icon: _buildIcon(context, state),
          onPressed: () => _onPressed(context, state),
          tooltip: _getTooltip(state),
        );
      },
    );
  }

  Widget _buildIcon(BuildContext context, SyncState state) {
    final theme = Theme.of(context);
    
    if (state is SyncInProgress) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: state.progress,
          color: theme.colorScheme.primary,
        ),
      );
    }
    
    if (state is SyncCompleted) {
      return Icon(
        Icons.cloud_done,
        color: theme.colorScheme.primary,
      );
    }
    
    if (state is SyncError) {
      return Icon(
        Icons.cloud_off,
        color: theme.colorScheme.error,
      );
    }
    
    if (state is SyncIdle) {
      if (state.hasChanges) {
        return Icon(
          Icons.cloud_queue,
          color: theme.colorScheme.secondary,
        );
      }
      
      if (state.isRealtimeEnabled) {
        return Icon(
          Icons.cloud_sync,
          color: theme.colorScheme.primary,
        );
      }
    }
    
    return Icon(
      Icons.cloud_outlined,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  void _onPressed(BuildContext context, SyncState state) {
    if (state is SyncError || (state is SyncIdle && state.hasChanges)) {
      context.read<SyncBloc>().add(StartSyncEvent());
    } else if (state is! SyncInProgress) {
      _showSyncStatus(context, state);
    }
  }

  String _getTooltip(SyncState state) {
    if (state is SyncInProgress) {
      final percentage = (state.progress * 100).toInt();
      return state.currentOperation ?? 'Syncing... $percentage%';
    }
    
    if (state is SyncCompleted) {
      return 'Last synced: ${AppDateUtils.formatForDisplay(state.lastSyncTime)}';
    }
    
    if (state is SyncError) {
      return 'Sync failed - tap to retry';
    }
    
    if (state is SyncIdle) {
      if (state.hasChanges) {
        return 'Changes pending - tap to sync';
      }
      
      if (state.isRealtimeEnabled) {
        return 'Real-time sync enabled';
      }
      
      if (state.lastSyncTime != null) {
        return 'Last synced: ${AppDateUtils.formatForDisplay(state.lastSyncTime!)}';
      }
    }
    
    return 'Tap to view sync status';
  }

  void _showSyncStatus(BuildContext context, SyncState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('Status', _getStatusText(state)),
            
            if (state is SyncCompleted) ...[
              _buildStatusRow(
                'Last Sync',
                AppDateUtils.formatForDisplay(state.lastSyncTime),
              ),
              if (state.syncedItems > 0)
                _buildStatusRow('Items Synced', '${state.syncedItems}'),
            ],
            
            if (state is SyncIdle) ...[
              if (state.lastSyncTime != null)
                _buildStatusRow(
                  'Last Sync',
                  AppDateUtils.formatForDisplay(state.lastSyncTime!),
                ),
              _buildStatusRow(
                'Real-time Sync',
                state.isRealtimeEnabled ? 'Enabled' : 'Disabled',
              ),
              _buildStatusRow(
                'Pending Changes',
                state.hasChanges ? 'Yes' : 'No',
              ),
            ],
            
            if (state is SyncError) ...[
              _buildStatusRow('Error', state.message),
              _buildStatusRow('Retryable', state.isRetryable ? 'Yes' : 'No'),
            ],
            
            if (state is SyncInProgress) ...[
              _buildStatusRow('Progress', '${(state.progress * 100).toInt()}%'),
              if (state.currentOperation != null)
                _buildStatusRow('Operation', state.currentOperation!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          
          if (state is SyncIdle && !state.isRealtimeEnabled)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<SyncBloc>().add(EnableRealtimeSyncEvent());
              },
              child: const Text('Enable Real-time'),
            ),
          
          if (state is SyncIdle && state.isRealtimeEnabled)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<SyncBloc>().add(DisableRealtimeSyncEvent());
              },
              child: const Text('Disable Real-time'),
            ),
          
          if (state is SyncError || (state is SyncIdle && state.hasChanges))
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<SyncBloc>().add(StartSyncEvent());
              },
              child: const Text('Sync Now'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStatusText(SyncState state) {
    if (state is SyncInProgress) return 'Syncing...';
    if (state is SyncCompleted) return 'Completed';
    if (state is SyncError) return 'Failed';
    if (state is SyncIdle) {
      if (state.hasChanges) return 'Changes pending';
      if (state.isRealtimeEnabled) return 'Real-time enabled';
      return 'Up to date';
    }
    return 'Unknown';
  }
}