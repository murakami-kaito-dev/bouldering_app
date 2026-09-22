import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_datasource.dart';

/// お知らせリポジトリ実装
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final AnnouncementDataSource _dataSource;

  AnnouncementRepositoryImpl(this._dataSource);

  @override
  Future<List<Announcement>> getAnnouncements({int limit = 20, String? cursor}) {
    return _dataSource.getAnnouncements(limit: limit, cursor: cursor);
  }
}
