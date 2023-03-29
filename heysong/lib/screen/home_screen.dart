import 'dart:developer';
import 'dart:ui';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gif/gif.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:just_audio_background/just_audio_background.dart';

ButtonStyle buttonStyle = ElevatedButton.styleFrom(
  primary: Color.fromRGBO(255,222,169,1),
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
      leading: Container(
        padding: EdgeInsets.all(5),
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(Color.fromRGBO(255,222,169,1), BlendMode.modulate),
          child: const Image(image: AssetImage("assets/kleeIcon2.png")),
        ),
      )
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

class _SonglistState extends State<Songlist> with TickerProviderStateMixin{
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _player = AudioPlayer();
  late final GifController controller;


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
    controller = GifController(vsync: this);
    super.initState();
    requestPermission();
    _player.currentIndexStream.listen((index){
      if(index != null){
        _updateCurretPlayingList(index);
      }
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ));
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
                  Colors.red.shade700,
                  Colors.red.shade100
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
                            artworkQuality: FilterQuality.high,
                            nullArtworkWidget: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                              child: Image(
                                image: AssetImage('assets/kleeSticker1.png'),
                                fit: BoxFit.fill,
                              ),
                            ))),
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
                                      color: Color.fromRGBO(192, 44, 34, 0.5)
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
                                    margin: EdgeInsets.only(left: 5  ,bottom: 10),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Color.fromRGBO(192, 44, 34, 0.5)
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
                                    return Icon(Icons.repeat_outlined,color: Colors.redAccent,);
                                  } else if (_player.loopMode == LoopMode.one){
                                    return Icon(Icons.repeat_one,color: Colors.redAccent,);}
                                  else{
                                    return Icon(Icons.highlight_off_outlined,color: Colors.redAccent,);
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
                                      Icons.arrow_forward_outlined, color: Colors.redAccent,);
                                  } else {
                                    return Icon(Icons.shuffle,
                                      color: Colors.redAccent,);
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
                                  thumbColor: Color.fromRGBO(255,222,169,1),
                                  timeLabelTextStyle: const TextStyle(
                                    fontSize: 0,
                                  ),
                                  onSeek: (duration){
                                    _player.seek(duration);
                                  },
                                ),
                              ),
                                Padding(
                                  padding: EdgeInsets.only(left: 10,right: 10),
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
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 327.2,
                      padding: EdgeInsets.all(0),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 110,
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              child: Image(image: AssetImage(
                                  'assets/gif.gif'
                                )),
                            ),
                          ),
                          Positioned(
                            child:Container(
                              margin: EdgeInsets.only(top: 40),
                              child: ButtonBar(
                              alignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  child: ElevatedButton(onPressed: (){ _player.seekToPrevious();},style: ElevatedButton.styleFrom(backgroundColor: Color.fromRGBO(255,222,169,1),shape: CircleBorder()), child: Icon(Icons.skip_previous_rounded,color: Colors.redAccent,),),),
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
                                      style: ElevatedButton.styleFrom(backgroundColor: Color.fromRGBO(255,222,169,1),shape: CircleBorder()),
                                      child: StreamBuilder<bool>(
                                        stream: _player.playingStream,
                                        builder: (context, snapshot){
                                          bool? playing = snapshot.data;
                                          if(playing != null && playing){
                                            return const Icon(Icons.pause,color: Colors.redAccent,);
                                          }
                                          return const Icon(Icons.play_arrow,color: Colors.redAccent,);
                                        },
                                      ),
                                    )),
                                Container(
                                  width: 60,
                                  height: 60,
                                  child: ElevatedButton(onPressed: (){_player.seekToNext();},style: ElevatedButton.styleFrom(backgroundColor: Color.fromRGBO(255,222,169,1),shape: CircleBorder()), child: Icon(Icons.skip_next_rounded,color: Colors.redAccent,),),),
                              ],
                          ),
                            ),)
                        ],
                      ),
                    ),
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
              Colors.red.shade700,
              Colors.red.shade100
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
                      child: Icon(Icons.shuffle_sharp,color: Colors.redAccent,),
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
                      child: Icon(Icons.play_arrow,color : Colors.redAccent,),),
                  ],
                ),
                const SizedBox(height: 10.0,),
                Text('Danh sách nhạc',
                  style: Theme.of(context)
                      .textTheme
                      .headline6!
                      .copyWith(fontWeight: FontWeight.bold),),
                Expanded(
                  child: Stack(
                      children : [
                        Container(
                          child: showlistSong()),
                        Positioned(
                          bottom: 5,
                            child:StreamBuilder<int?>(
                              stream: _player.currentIndexStream,
                              builder: (context, snapshot) {
                                print("curret: " + snapshot.data.toString());
                                if (snapshot.data != null) {
                                  return GestureDetector(
                                      onTap: () async{
                                        _changePlayerView();
                                      },
                                    child: Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Color.fromRGBO(
                                              178, 72, 40, 1.0),
                                        ),
                                        width: MediaQuery
                                            .of(context)
                                            .size
                                            .width-20,
                                        height: 110,
                                        child: Container(
                                          child: Row(
                                              children: [
                                                Container(
                                                  width:80,
                                                  height: 80,
                                                  margin: EdgeInsets.all(10),
                                                  child: QueryArtworkWidget(
                                                      id: songs[currentIndex].id,
                                                      type: ArtworkType.AUDIO,
                                                      artworkWidth: 80,
                                                      artworkHeight: 80,
                                                      artworkBorder: BorderRadius.circular(10),
                                                      artworkQuality: FilterQuality.high,
                                                      nullArtworkWidget: ClipRRect(
                                                        borderRadius: BorderRadius.circular(10),
                                                        child: Image(
                                                          image: AssetImage('assets/kleeSticker1.png'),
                                                          fit: BoxFit.fill,
                                                        ),
                                                      )),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.only(top: 5),
                                                  child: Flexible(
                                                    child: Container(
                                                      width: MediaQuery.of(context).size.width/2 + 60,
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                        Container(
                                                          height: 25,
                                                          child: Text(songs[currentIndex].title,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 18)),
                                                        ),
                                                        Text(songs[currentIndex].artist ?? " ",
                                                              overflow: TextOverflow.ellipsis,
                                                              style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 15)),
                                                          StreamBuilder<DurationState> (
                                                            stream: _durationStateStream,
                                                            builder: (context, snapshot){
                                                              final durationState = snapshot.data;
                                                              final process  = durationState?.position ?? Duration.zero;
                                                              final total = durationState?.total ?? Duration.zero;
                                                              return Center(
                                                                child: Column(
                                                                  children: [
                                                                    Container(
                                                                      padding: EdgeInsets.only(top: 2),
                                                                      child: ProgressBar(
                                                                        progress: process,
                                                                        total: total,
                                                                        barHeight: 5,
                                                                        thumbRadius: 5,
                                                                        progressBarColor: Colors.white,
                                                                        thumbColor: Color.fromRGBO(255,222,169,1),
                                                                        timeLabelTextStyle: const TextStyle(
                                                                          fontSize: 0,
                                                                        ),
                                                                        onSeek: (duration){
                                                                          _player.seek(duration);
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ],
                                                                )
                                                                ,);
                                                            },
                                                          ),
                                                          ButtonBar(
                                                            alignment: MainAxisAlignment.spaceEvenly,
                                                            buttonPadding: EdgeInsets.zero,
                                                            children: [
                                                              Container(
                                                                child: ElevatedButton(onPressed: (){ _player.seekToPrevious();},style: buttonStyle, child: Icon(Icons.skip_previous_rounded,color: Colors.redAccent,),),),
                                                              Container(
                                                                  child: ElevatedButton(
                                                                    onPressed: () {
                                                                      if(_player.playing){
                                                                        _player.pause();
                                                                      }else if(_player != null){
                                                                        _player.play();
                                                                      }
                                                                    },
                                                                    style: buttonStyle,
                                                                    child: StreamBuilder<bool>(
                                                                      stream: _player.playingStream,
                                                                      builder: (context, snapshot){
                                                                        bool? playing = snapshot.data;
                                                                        if(playing != null && playing){
                                                                          return const Icon(Icons.pause,color: Colors.redAccent,);
                                                                        }
                                                                        return const Icon(Icons.play_arrow,color: Colors.redAccent,);
                                                                      },
                                                                    ),
                                                                  )),
                                                              Container(
                                                                child: ElevatedButton(onPressed: (){_player.seekToNext();},style: buttonStyle, child: Icon(Icons.skip_next_rounded,color: Colors.redAccent,),),),
                                                            ],
                                                          )
                                                      ]),
                                                    ),
                                                  ),
                                                )
                                              ]
                                          ),
                                        ),
                                      ),
                                    ),);
                                  }else return Container();
                              }))
                      ],
                  ),
                ),
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
                            nullArtworkWidget: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image(
                                  image: AssetImage('assets/kleeSticker1.png'),
                                  fit: BoxFit.fill,
                                )),
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
      source.add(AudioSource.uri(Uri.parse(song.uri!),
          tag: MediaItem(
            // Specify a unique ID for each media item:
            id: song.id.toString(),
            // Metadata to display in the notification:
            artist: song.artist,
            title: song.title,
          ),
      ));
    }
    return ConcatenatingAudioSource(children: source);
  }

  void _updateCurretPlayingList(int index) {
      if(isPlayerViewVisible){
        setState(() {
        });
      }
      if (songs.isNotEmpty) {
        currentSongTitle = songs[index].title;
        currentIndex = index;
      }
  }
}

class DurationState{
  DurationState({this.position = Duration.zero, this.total = Duration.zero});
  Duration position, total;
}
