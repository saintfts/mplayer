import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:mplayer/common.dart';
import 'package:mplayer/listItem.dart';
import 'package:rxdart/rxdart.dart';

const defaultTracksPath = "/home/saintfts/Music/";
const acceptedAudioFormats = "wav|flac|mp3";
void main() {
  JustAudioMediaKit.ensureInitialized();
  runApp(const MPlayerApp());
}

class MPlayerApp extends StatelessWidget {
  const MPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MPlayer());
  }
}

class MPlayer extends StatefulWidget {
  const MPlayer({super.key});
  @override
  State<MPlayer> createState() => _MPlayerState();
}

class _MPlayerState extends State<MPlayer> {


  int _pageIndex = 0;

  List<Track> _tracksFiles = [];

  var tracksPath = defaultTracksPath;
  final _player = AudioPlayer();
  final ValueNotifier<bool> _isPaused = ValueNotifier(true);
  ProcessingState? playerState;
  Track? currentTrack;
  TextEditingController? _settingPathToTracksController;
  final ValueNotifier<int> _tracksIter = ValueNotifier(-1);

  Widget? _tracksPage;
  Widget? _settingsPage;

  void _refreshTracksPage(){
    _tracksPage = _buildTrackList();
  }
  @override
  void initState() {
    super.initState();

    _tracksFiles = _getTrackFiles(tracksPath);
    _settingPathToTracksController = TextEditingController(text: tracksPath);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playerState = state;
        _isPaused.value = true;
        _nextTrack();
        _playMusic(currentTrack!);
      }
    });
    _tracksPage = _buildTrackList();
    _settingsPage = _buildSettingsPage();
  }
  
  void _defaultThePlayerBackend(){
    _tracksIter.value = -1;
    _player.setAudioSource(AudioSource.file(""));
    tracksPath = defaultTracksPath;
    _isPaused.value = true;
    _tracksFiles = _getTrackFiles(tracksPath);
  }

  void _togglePause() {
    if (_player.playing && !_isPaused.value) {
      _isPaused.value = true;
      _player.pause();
    } else {
      _isPaused.value = false;
      _player.play();
    }
  }

  void _prevTrack() {
    _tracksIter.value--;
    if (_tracksIter.value < 0) {
      _tracksIter.value = _tracksFiles.length - 1;
    }
    currentTrack = _tracksFiles[_tracksIter.value];
  }

  void _nextTrack() {
    if (_tracksIter.value == -1){
      return;
    }
    _tracksIter.value++;
    if (_tracksIter.value >= _tracksFiles.length) {
      _tracksIter.value = 0;
    }
    currentTrack = _tracksFiles[_tracksIter.value];
  }

  void _playMusic(Track track) async {
    if (currentTrack != track) {
      currentTrack = track;
    }
    _isPaused.value = false;
    var audioSource = AudioSource.file(track.path);
    await _player.setAudioSource(audioSource);
    await _player.play();
  }

  List<Track> _getTrackFiles(String path) {
    final scanDir = io.Directory(path);
    if (!scanDir.existsSync()) {
      return [];
    }
    final tracks = scanDir
        .listSync()
        .where(
          (file) => RegExp(
            '\\.($acceptedAudioFormats)',
            caseSensitive: false,
          ).hasMatch(file.path),
        )
        .map((file) => Track(path: file.path))
        .toList();
    return tracks;
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  backgroundColor: Colors.black,
                  selectedIndex: _pageIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _pageIndex = index;
                    });
                  },
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.music_note),
                      label: Text('Tracks'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                Expanded(
                  child: switch (_pageIndex) {
                    0 => _tracksPage ?? Text("No tracks found"),
                    1 => _settingsPage ?? Text("You managed to break the settings page..."),
                    _ => const Text("Error in _pageIndex"),
                  },
                ),
              ],
            ),
          ),
          _buildBottomPlayBar(),
        ],
      ),
    );
  }

  Widget _buildTrackList() {
  //_defaultThePlayerBackend();
    if (_tracksFiles.isEmpty) {
      return const Center(child: Text("No music found."));
    }
    return ListView.builder(
      itemCount: _tracksFiles.length,
      itemBuilder: (context, index) {
        final track = _tracksFiles[index];

        return ValueListenableBuilder<int>(
          valueListenable: _tracksIter,
          builder: (_, playingIndex, _){
              return TrackTile(
                track: track,
                isPlaying: index == playingIndex,
                onPlay: (track) {
                  _tracksIter.value = index;
                  print(_tracksIter.value);
                  _playMusic(track);
                },
              );
          },
        );
      },
    );
  }

  Widget _buildSettingsPage() {
    return Container(
      child: Center(
        child: Column(
          children: [
            const Text("Settings page"),
            TextFormField(controller: _settingPathToTracksController),
            ElevatedButton(
              child: Text("Refresh tracks path"),
              onPressed: () {
                _defaultThePlayerBackend();
                tracksPath = _settingPathToTracksController!.text;
                _tracksFiles = _getTrackFiles(tracksPath);
                _refreshTracksPage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPlayBar() {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double barHeight = 100;
    return Container(
      child: Column(
        children: [
          StreamBuilder(
            stream: _positionDataStream,
            builder: (context, snapshot) {
              final positionData = snapshot.data;
              return SeekBar(
                divisions:
                    (positionData?.duration ?? Duration.zero).inSeconds > 0
                    ? positionData?.duration.inSeconds
                    : 1,
                duration: positionData?.duration ?? Duration.zero,
                position: positionData?.position ?? Duration.zero,
                bufferedPosition:
                    positionData?.bufferedPosition ?? Duration.zero,
                onChanged: (_) {
                  _player.pause();
                },
                onChangeEnd: (d) {
                  _player.seek(d);
                  if ((_player.duration! - _player.position) < Duration(milliseconds: 1)) {
                      _player.stop();
                  }
                  if (!_isPaused.value) {
                    _player.play();
                  }
                },
              );
            },
          ),
          Stack(
            children: [
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.fast_rewind),
                      onPressed: () {
                        _prevTrack();
                        _playMusic(currentTrack!);
                      },
                    ),
                    ValueListenableBuilder(
                      valueListenable: _isPaused,
                      builder: (_, isPaused, _){
                        return IconButton(
                          icon: Icon(isPaused? Icons.play_arrow : Icons.pause),
                          onPressed: _togglePause,
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.fast_forward),
                      onPressed: () {
                        _nextTrack();
                        _playMusic(currentTrack!);
                      },
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 150,
                  child: Tooltip(
                    message: "Volume",
                    preferBelow: false,
                    verticalOffset: 12,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        overlayShape: RoundSliderOverlayShape(
                          overlayRadius: 15,
                        ),
                      ),
                      child: Slider(
                        value: _player.volume,
                        min: 0,
                        max: 1,
                        onChanged: (volumeLevel) {
                          setState(() {
                            _player.setVolume(volumeLevel);
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
