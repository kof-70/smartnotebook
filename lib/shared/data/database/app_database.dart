import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../../../features/zone_1_raw/data/models/note_model.dart';
import '../../../features/zone_1_raw/data/models/media_model.dart';
import '../../../features/zone_1_raw/data/models/tag_model.dart';
import 'daos/note_dao.dart';
import 'daos/media_dao.dart';
import 'daos/tag_dao.dart';

part 'app_database.g.dart';

@Database(
  version: 1,
  entities: [
    NoteModel,
    MediaModel,
    TagModel,
  ],
)
abstract class AppDatabase extends FloorDatabase {
  NoteDao get noteDao;
  MediaDao get mediaDao;
  TagDao get tagDao;
}