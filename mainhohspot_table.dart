import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:walkscreen/models/hotspot_element.dart';
import 'package:path/path.dart' as p;

class MainHotspotDBProvider {
  MainHotspotDBProvider._();
  static final MainHotspotDBProvider db = MainHotspotDBProvider._();

  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;

    // if _database is null we instantiate it
    _database = await initDB();
    return _database;
  }

  initDB() async {
    var databasesPath = await getDatabasesPath();
    String path = p.join(databasesPath, "MainHotspotDB.db");
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE MainHotspot ("
          "name TEXT PRIMARY KEY,"
          "password TEXT,"
          "condition INTEGER"
          ")");
    });
  }

  newHotspot(HotspotElement hotspotElement) async {
    final db = await database;
    final contains = getHotspots(hotspotElement.name);
    if (contains != null) await db.insert("MainHotspot", hotspotElement.toMap());
  }

  getHotspots(String filepath) async {
    final db = await database;
    var res =
        await db.query("MainHotspot", where: "name= ?", whereArgs: [filepath]);
    return res.isNotEmpty ? HotspotElement.fromMap(res.first) : Null;
  }

  getAllHotspots() async {
    final db = await database;
    var res = await db.query("MainHotspot");
    List<HotspotElement> list = res.isNotEmpty
        ? res.map((c) => HotspotElement.fromMap(c)).toList()
        : [];
    return list;
  }

  updateHotspots(HotspotElement newHotspotsElement) async {
    final db = await database;
    var res = await db.update("MainHotspot", newHotspotsElement.toMap(),
        where: "name = ?", whereArgs: [newHotspotsElement.name]);
    return res;
  }

  deleteHotspots(HotspotElement hotspotsElement) async {
    final db = await database;
    db.delete("MainHotspot",
        where: "name = ?", whereArgs: [hotspotsElement.name]);
  }

  deleteAll() async {
    final db = await database;
    db.rawDelete("Delete * from MainHotspot");
  }
}
