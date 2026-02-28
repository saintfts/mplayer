import 'package:flutter/material.dart';

abstract class ListItem {
  Widget build(BuildContext context, Function onTap);
}

class Track {
  final String path;
  final String name;
  final String? artist;
  Track({required this.path})
    : name = path.split(RegExp('[\\\\\/]')).last,
      artist = "None";
}

class TrackTile extends StatelessWidget {
  final Track track;
  final ValueChanged onPlay;
  final bool isPlaying;
  const TrackTile({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        track.name,
        style: Theme.of(context).textTheme.titleMedium,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(track.artist ?? "Unknown artist"),
      trailing: isPlaying
          ? Icon(Icons.pause)
          : const Icon(Icons.play_arrow_outlined),
      onTap: () => onPlay(track),
    );
  }
}

class HeadingItem implements ListItem {
  final String heading;
  HeadingItem(this.heading);
  @override
  @override
  Widget build(BuildContext context, Function onTap) => const SizedBox.shrink();
}

class TrackBox implements ListItem {
  final String trackPath;
  final String trackName;
  TrackBox(this.trackPath, this.trackName);

  @override
  Widget build(BuildContext context, Function playLambda) => InkWell(
    child: SizedBox(
      width: double.infinity,
      child: Text(trackName, style: Theme.of(context).textTheme.headlineSmall),
    ),
    onTap: () {
      playLambda(trackPath);
    },
  );
}
