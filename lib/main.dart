import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/utils/permission_utils.dart';
import 'injection_container.dart' as di;
import 'shared/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await di.init();
  
  // Request necessary permissions
  await PermissionUtils.requestInitialPermissions();
  
  // Initialize background services
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  
  runApp(const SmartNotebookApp());
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await di.init();
    final backgroundService = di.sl<BackgroundService>();
    
    switch (task) {
      case 'syncData':
        await backgroundService.performSync();
        break;
      case 'processAIQueue':
        await backgroundService.processAIQueue();
        break;
      default:
        break;
    }
    
    return Future.value(true);
  });
}