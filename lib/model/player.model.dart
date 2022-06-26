/// {@category backend}
///
/// [Player] is a wrapper over [AudioPlayer] that makes it easy to update the UI
///
/// ## Playing audio:
/// ```dart
/// var musicPlayer = Player();
///
/// // load up a song
/// await musicPlayer.load(SongReprObject);
///
/// // play the song
/// await musicPlayer.play();
///
/// // pause the song
/// await musicPlayer.pause();
///
/// // free up used resources
/// await musicPlayer.done();
/// ```
///
/// ## Updating UI:
///
/// ```dart
/// // live update current played seconds & total seconds
/// SomeWidgetTree(
///   child: Text('played ${musicPlayer.cProgress} seconds of ${musicPlayer.cDuration} seconds');
/// )
///
/// // seek based on slider
/// SomeWidgetTree(
///   child: Slider(
///     onChanged: (double positionOutOfHundred) {
///       musicPlayer.seek(positionOutOfHundred.toInt());
///     }
///   )
/// )
/// ```
///

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:audioplayers/audioplayers.dart';

// Project imports:
import 'package:swaram/model/song.model.dart';

// TODO: implement queue

/// A wrapper around [AudioPlayer] to ease updating UI
///
class Player extends ChangeNotifier {
  /// Internal [AudioPlayer] reference
  ///
  final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  /// total length of the current song in milliseconds
  ///
  late Duration _duration;

  /// duration of current song in milliseconds
  ///
  int get cDuration => _duration.inMilliseconds;

  /// duration of current song formatted as text
  ///
  String get cDurationAsText => _formatDuration(_duration);

  /// current playback progress in milliseconds
  ///
  late Duration _progress;

  /// playback progress of the current song in milliseconds
  ///
  int get cProgress => _progress.inMilliseconds;

  /// the song currently loaded up
  ///
  late Song _song;

  /// the song currently loaded up
  ///
  Song get song => _song;

  /// playback progress of the current song formatted as text
  ///
  String get cProgressAsText => _formatDuration(_progress);

  /// true if audio playback is currently active
  ///
  bool get playing => _player.state == PlayerState.playing;

  /// true if audio playback is currently paused
  ///
  bool get paused => _player.state == PlayerState.paused;

  /// true if the playback has reached the last millisecond
  ///
  bool _playbackFinished = false;

  /// true if the playback has reached the last millisecond
  ///
  bool get playbackFinishd => _playbackFinished;

  /// create a `Player` object
  ///
  Player() {
    _player.onDurationChanged.listen((Duration totalDuration) async {
      _duration = totalDuration;
      notifyListeners();
    });

    _player.onPositionChanged.listen((Duration currentPosition) {
      _progress = currentPosition;

      if (cProgress == cDuration) _playbackFinished = true;

      notifyListeners();
    });
  }

  /// load up the song at the given path, and prepare it to be played
  ///
  Future<void> load({required Song song}) async {
    _song = song;
    _playbackFinished = false;
    _duration = const Duration(milliseconds: 0);
    _progress = const Duration(milliseconds: 0);

    await _player.setSource(DeviceFileSource(song.filePath));
  }

  /// play/resume the loaded up song
  ///
  Future<void> play() async {
    await _player.resume();
  }

  /// pause audio playback
  ///
  Future<void> pause() async {
    await _player.pause();
  }

  /// playback from the point where `playbackInMilliseconds`ms of the song has been played
  ///
  Future<void> setPosition({required int playbackInMilliseconds}) async {
    await _player.seek(Duration(milliseconds: playbackInMilliseconds));
  }

  /// internal magic, get rid of unused resources
  ///
  Future<void> done() async {
    await _player.dispose();
  }

  /// convert duration to mm:ss
  String _formatDuration(Duration duration) =>
      duration.toString().split('.').first.split(':').sublist(1).join(':');
}
