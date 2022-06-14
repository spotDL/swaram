import 'dart:io';
import 'dart:convert';
import 'package:id3/id3.dart';

void main() {
  List<int> mp3Bytes = File('./.misc/testSong.mp3').readAsBytesSync();

  MP3Instance mp3instance = MP3Instance(mp3Bytes);

  if (mp3instance.parseTagsSync()) {
    File('./.misc/data.json').writeAsStringSync(json.encode(mp3instance.getMetaTags()));

    var coverBytes = base64Decode(mp3instance.metaTags['APIC']['base64']);

    File('./.misc/cover.jpg').writeAsBytesSync(coverBytes);
  }
}
