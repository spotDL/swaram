/// {@category backend}
///
/// [Player] is a wrapper over [AudioPlayer] that makes it easy to update the UI
///
/// ## Playing audio:
/// ```dart
/// var musicPlayer = Player();
///
/// // load up a song
/// await musicPlayer.load('./someSong.mp3');
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
///   child: Text('played ${musicPlayer.progress}% of ${musicPlayer.duration} seconds');
/// )
///
/// // seek based on slider
/// SomeWidgetTree(
///   child: Slider(
///     onChanged: (double positionOutOfHundred) {
///       musicPlayer.seek(positionOutOfHundred);
///     }
///   )
/// )
/// ```
///

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:audioplayers/audioplayers.dart';

/// A wrapper around [AudioPlayer] to ease updating UI
///
class Player extends ChangeNotifier {
  /// Internal [AudioPlayer] reference
  ///
  final AudioPlayer _player = AudioPlayer();

  /// total length of the current song in seconds
  ///
  int _duration = 0;

  /// duration of current song in seconds
  ///
  int get duration => _duration;

  /// current player position as percentage
  ///
  double _progress = 0;

  /// how much of the song has been played as a percentage
  ///
  double get progress => _progress;

  /// true if audio playback is still active
  bool get isPlaying => _player.state == PlayerState.playing;

  /// true if audio playback is still paused
  bool get isPaused => _player.state == PlayerState.paused;

  /// true if currently loaded song has been played from start to end
  bool get isComplete => _player.state == PlayerState.completed;

  /// create a `Player` object
  ///
  Player() {
    _player.onDurationChanged.listen((Duration totalDuration) async {
      _duration = totalDuration.inSeconds;
      notifyListeners();
    });

    _player.onPositionChanged.listen((Duration currentPosition) {
      _progress = (currentPosition.inSeconds / _duration) * 100;
      notifyListeners();
    });
  }

  /// load up the song at the given path, and prepare it to be played
  ///
  Future<void> load({required String mp3Path}) async {
    _duration = 0;
    _progress = 0;

    await _player.setSource(DeviceFileSource(mp3Path));
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

  /// playback from the point where `positionPercentage` percent of the song has been played
  ///
  Future<void> setPosition({required double positionPercentage}) async {
    while (_duration == 0) {
      await Future.delayed(const Duration(milliseconds: 250));
    }

    var pos = Duration(seconds: ((positionPercentage / 100) * _duration).toInt());
    await _player.seek(pos);
  }

  /// internal magic, get rid of unused resources
  ///
  Future<void> done() async {
    await _player.dispose();
  }
}
