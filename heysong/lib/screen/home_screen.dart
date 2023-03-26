import 'dart:developer';
import 'dart:ui';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

ButtonStyle buttonStyle = ElevatedButton.styleFrom(
  primary: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
);


class _CustomAppBar extends StatelessWidget with PreferredSizeWidget{
  const _CustomAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const Icon(Icons.grid_view_rounded),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}




class Songlist extends StatefulWidget{
  const Songlist({Key? key, required this.title}) : super(key: key);
  final String title;


  @override
  State<StatefulWidget> createState() => _SonglistState();

}

class _SonglistState extends State<Songlist>{
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _player = AudioPlayer();

  List<SongModel> songs = [];
  String currentSongTitle = '';
  int currentIndex = 0;
  bool isPlayerViewVisible = false;

  void _changePlayerView(){
    setState(() {
      isPlayerViewVisible = !isPlayerViewVisible;
    });
  }


  Stream<DurationState> get _durationStateStream =>
      Rx.combineLatest2<Duration, Duration?, DurationState >(
          _player.positionStream, _player.durationStream, (position,duration) => DurationState(
          position: position,total: duration?? Duration.zero
      ));


  @override
  void initState() {
    super.initState();
    requestPermission();
    _player.currentIndexStream.listen((index){
      if(index != null){
        _updateCurretPlayingList(index);
      }
    }
    );
  }

  @override
  Widget build(BuildContext context) {
    if(isPlayerViewVisible){
      return Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.pink.shade300,
                  Colors.pink.shade100
                ],
              )
          ),
          child: WillPopScope(
            onWillPop: () async {
              if(isPlayerViewVisible){
                _changePlayerView();
                return false;
              }else{
                Navigator.of(context).pop(); // navigate back to previous screen
                return true; // allow app to close if on the home screen
              }
              },
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Container(
                child:Column(
                  children: [Container(
                    width:400 ,
                    height: 400,
                    margin: EdgeInsets.only(top: 50, left: 10, right: 10),
                    child: Stack(
                      children: [Center(
                        child: QueryArtworkWidget(
                            id: songs[currentIndex].id,
                            type: ArtworkType.AUDIO,
                            artworkBorder: BorderRadius.circular(10),
                            artworkHeight: 400,
                            artworkWidth: 400,
                            artworkQuality: FilterQuality.high)),
                        Positioned(
                          bottom: 10,
                          left: 0,
                          child: Container(
                            width: 250,
                            margin: EdgeInsets.only(left: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Color.fromRGBO(255, 86, 139, 0.5)
                                    ),
                                    child: Column(
                                      children: [
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              Container(
                                              margin: EdgeInsets.all(5),
                                                  child: Text(songs[currentIndex].title,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 20
                                                  ))),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )),
                                Container(
                                    margin: EdgeInsets.only(left: 5            ,bottom: 10),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Color.fromRGBO(255, 86, 139, 0.5)
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                            margin: EdgeInsets.all(5),
                                            child: Text(songs[currentIndex].artist ?? '',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                ))),
                                      ],
                                    ))
                              ],
                            ),
                          ),
                        ),
                        ],
                    ),
                  ),
                      Container(
                        padding: EdgeInsets.only(left: 10, top: 5),
                        child: Row(
                          children: [
                            ElevatedButton(
                              style: buttonStyle,
                              onPressed: (){
                                if (_player.loopMode == LoopMode.all){
                                _player.setLoopMode(LoopMode.one);
                                log("Loop mode is${_player.loopMode}");
                                }else {if (_player.loopMode == LoopMode.one){
                                  _player.setLoopMode(LoopMode.off);
                                  log("Loop mode is${_player.loopMode}");}
                                else{
                                  _player.setLoopMode(LoopMode.all);
                                  log("Loop mode is${_player.loopMode}");
                                }}
                              },
                              child: StreamBuilder<LoopMode>(
                                stream: _player.loopModeStream,
                                builder: (context, snapshot){
                                  if (_player.loopMode == LoopMode.all){
                                    return Icon(Icons.repeat_outlined,color: Colors.pink,);
                                  } else if (_player.loopMode == LoopMode.one){
                                    return Icon(Icons.repeat_one,color: Colors.pink,);}
                                  else{
                                    return Icon(Icons.highlight_off_outlined,color: Colors.pink,);
                                  }
                                },
                              )),
                            const SizedBox(width: 5,),
                            ElevatedButton(
                              onPressed: (){
                                if(!_player.shuffleModeEnabled){
                                  _player.setShuffleModeEnabled(true);
                                  log("Loop mode is${_player.shuffleModeEnabled}");
                                }else{
                                  _player.setShuffleModeEnabled(false);
                                  log("Loop mode is${_player.shuffleModeEnabled}");
                                }
                              },
                              style: buttonStyle,
                              child: StreamBuilder<bool>(
                                stream: _player.shuffleModeEnabledStream,
                                builder: (context, snapshot) {
                                  if (!_player.shuffleModeEnabled) {
                                    return Icon(
                                      Icons.arrow_forward_outlined, color: Colors.pink,);
                                  } else {
                                    return Icon(Icons.shuffle,
                                      color: Colors.pink,);
                                  }
                                })),
                          ],
                        ),
                      ),
                  Center(
                      child: StreamBuilder<DurationState> (
                        stream: _durationStateStream,
                        builder: (context, snapshot){
                          final durationState = snapshot.data;
                          final process  = durationState?.position ?? Duration.zero;
                          final total = durationState?.total ?? Duration.zero;
                          final positionString = "${process.inMinutes.remainder(60).toString().padLeft(2, '0')}:${process.inSeconds.remainder(60).toString().padLeft(2, '0')}";
                          final totalString = "${total.inMinutes.remainder(60).toString().padLeft(2, '0')}:${total.inSeconds.remainder(60).toString().padLeft(2, '0')}";
                          return Center(
                            child: Column(
                              children: [
                                Container(
                                padding: EdgeInsets.only(left: 10,right: 10,top: 5),
                                child: ProgressBar(
                                  progress: process,
                                  total: total,
                                  barHeight: 10,
                                  progressBarColor: Colors.white,
                                  thumbColor: Colors.pink.shade100,
                                  timeLabelTextStyle: const TextStyle(
                                    fontSize: 0,
                                  ),
                                  onSeek: (duration){
                                    _player.seek(duration);
                                  },
                                ),
                              ),
                                Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Text(positionString),
                                      Text(totalString
                                      )
                                    ],
                                  ),
                                )
                              ],
                            )
                            ,);
                        },
                      )),
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: ButtonBar(
                        alignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            child: ElevatedButton(onPressed: (){ _player.seekToPrevious();},style: ElevatedButton.styleFrom(backgroundColor: Colors.white,shape: CircleBorder()), child: Icon(Icons.skip_previous_rounded,color: Colors.pink,),),),
                          Container(
                            width: 90,
                            height: 90,
                            child: ElevatedButton(
                              onPressed: () {
                                if(_player.playing){
                                  _player.pause();
                                }else if(_player != null){
                                  _player.play();
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white,shape: CircleBorder()),
                              child: StreamBuilder<bool>(
                                stream: _player.playingStream,
                                builder: (context, snapshot){
                                  bool? playing = snapshot.data;
                                  if(playing != null && playing){
                                    return const Icon(Icons.pause,color: Colors.pink,);
                                  }
                                  return const Icon(Icons.play_arrow,color: Colors.pink,);
                                },
                              ),
                            )),
                          Container(
                            width: 60,
                            height: 60,
                            child: ElevatedButton(onPressed: (){_player.seekToNext();},style: ElevatedButton.styleFrom(backgroundColor: Colors.white,shape: CircleBorder()), child: Icon(Icons.skip_next_rounded,color: Colors.pink,),),),
                        ],
                      ),
                    )
                    ],
                ),),
            ),
          ));}
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade300,
              Colors.pink.shade100
            ],
          )
      ),
      child: Scaffold(
          appBar: _CustomAppBar(),
          backgroundColor: Colors.transparent,
          body: Container(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng',
                  style: Theme.of(context)
                      .textTheme.headline6),
                Text(
                  'Tận hưởng âm nhạc yêu thích',
                  style: Theme.of(context)
                      .textTheme
                      .headline5!
                      .copyWith(fontWeight: FontWeight.bold),),
                const SizedBox(height: 20.0,),
                TextFormField(
                  maxLength: 50,
                  style: Theme
                      .of(context)
                      .textTheme.bodyMedium!.copyWith(color : Colors.grey.shade700),
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Nhập tên bài hát',
                      hintStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: Colors.grey.shade700),
                      prefixIcon: Icon(Icons.search,color: Colors.grey.shade700),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide.none
                      ),
                      counterText:''
                  ),
                ),
                const SizedBox(height: 10.0,),
                ButtonBar(
                  alignment: MainAxisAlignment.start,
                  buttonPadding: EdgeInsets.zero,
                  children: [
                    ElevatedButton (
                      onPressed: () {
                      _changePlayerView();
                      // String? uri = snapshot.data![index].uri;
                      _player.setAudioSource(
                      createPlaylist(songs),
                      );
                      _player.setShuffleModeEnabled(true);
                      _player.play();
                    },
                      style: buttonStyle,
                      child: Icon(Icons.shuffle_sharp,color: Colors.pink,),
                    ),
                    const SizedBox(width: 10.0,),
                    ElevatedButton (onPressed: (){
                      _changePlayerView();
                      // String? uri = snapshot.data![index].uri;
                      _player.setAudioSource(
                        createPlaylist(songs),
                      );
                      _player.setShuffleModeEnabled(false);
                      _player.play();
                    },
                      style: buttonStyle,
                      child: Icon(Icons.play_arrow,color : Colors.pink,),),
                  ],
                ),
                const SizedBox(height: 10.0,),
                Text('Danh sách nhạc',
                  style: Theme.of(context)
                      .textTheme
                      .headline6!
                      .copyWith(fontWeight: FontWeight.bold),),
                showlistSong()
                ],
            )
          )));
  }

  void requestPermission() async {
    if(!kIsWeb){
      bool permissionStatus = await _audioQuery.permissionsStatus();
      if(!permissionStatus) {
        await _audioQuery.permissionsRequest();
      }
      setState(() {
      });
    }
  }

  Widget showlistSong() {
    return FutureBuilder<List<SongModel>>(
      future: _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data!.isNotEmpty ) {
          songs.clear();
          songs = snapshot.data!.where((song) => song.duration! > 60000).toList();
          return Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                Duration? duration = songs[index].duration != null
                    ? Duration(milliseconds: songs[index].duration!)
                    : null;
                String durationString = duration != null
                    ? '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
                    : '';
                return GestureDetector(
                  onTap: () async{
                    _changePlayerView();
                    await _player.setAudioSource(
                      createPlaylist(songs),
                      initialIndex: index
                    );
                    _player.play();
                  },
                  child: Container(
                    height:90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    margin: EdgeInsets.all(1),
                    child: Row(
                      children: [Container(
                        margin: EdgeInsets.all(5.0),
                          height:80,
                          width: 80,
                          child:QueryArtworkWidget(
                            artworkBorder: BorderRadius.circular(10.0),
                            id: songs[index].id,
                            type: ArtworkType.AUDIO,
                          )
                      ),
                        Flexible(child:
                        Container(
                          margin: EdgeInsets.only(top: 15,right: 10,left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(songs[index].title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                                )),
                              Text(songs[index].artist ?? "No Artist",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18
                                  )
                              ),
                              Text("$durationString | ${songs[index].fileExtension}",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15
                                  )
                              )
                            ,],
                          ),
                        ))
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return const Center(child: Text('No songs found.'));
        }
      },
    );
  }
  ConcatenatingAudioSource createPlaylist(List<SongModel>? song) {
    List<AudioSource> source = [];
    for (var song in songs){
      source.add(AudioSource.uri(Uri.parse(song.uri!)));
    }
    return ConcatenatingAudioSource(children: source);
  }

  void _updateCurretPlayingList(int index) {
    if(isPlayerViewVisible) {
      setState(() {
        if (songs.isNotEmpty) {
          currentSongTitle = songs[index].title;
          currentIndex = index;
        }
      });
    }
  }
}

class DurationState{
  DurationState({this.position = Duration.zero, this.total = Duration.zero});
  Duration position, total;
}
