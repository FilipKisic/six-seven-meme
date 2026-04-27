import 'package:audioplayers/audioplayers.dart';
import 'package:six_seven/core/constants/app_assets.dart';

class StartSoundPlayer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play() async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.stop();
    await _player.play(
      AssetSource(AppAssets.sixSevenSoundSource, mimeType: 'audio/mp4'),
    );
  }

  Future<void> dispose() {
    return _player.dispose();
  }
}
