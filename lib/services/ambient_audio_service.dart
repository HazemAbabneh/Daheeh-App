import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Manages ambient focus sounds (Rain, Library, Nature).
/// Uses audio streaming to avoid bundling large asset files.
/// Developers can swap [_streams] URLs for local assets at any time.
class AmbientAudioService extends ChangeNotifier {
  static const _streams = {
    'rain':    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    'library': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    'nature':  'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
  };

  static const Map<String, String> ambientLabels = {
    'rain':    '🌧️  مطر',
    'library': '📚  مكتبة',
    'nature':  '🌿  طبيعة',
  };

  final AudioPlayer _player = AudioPlayer();

  String? _activeKey;
  bool    _isPlaying = false;
  double  _volume    = 0.5;

  String? get activeKey => _activeKey;
  bool    get isPlaying => _isPlaying;
  double  get volume    => _volume;

  Future<void> play(String key) async {
    if (_activeKey == key && _isPlaying) return;
    _activeKey = key;
    await _player.stop();
    final url = _streams[key];
    if (url == null) return;
    await _player.setVolume(_volume);
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(UrlSource(url));
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _activeKey  = null;
    _isPlaying  = false;
    notifyListeners();
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
