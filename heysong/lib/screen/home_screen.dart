
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';

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
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 20),
          child: CircleAvatar(
            backgroundImage: NetworkImage('https://scontent.fsgn5-2.fna.fbcdn.net/v/t39.30808-6/301390543_1679740612395259_9175438976720458869_n.jpg?_nc_cat=105&ccb=1-7&_nc_sid=09cbfe&_nc_ohc=R_wdQ2DGu48AX9AYYlP&_nc_ht=scontent.fsgn5-2.fna&oh=00_AfDcWC-M4Ucxa94z2ylWbX2zCSzQFpqDSSlCEP6mtwTUTg&oe=641D4479'),
          ),
        )
      ],
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

  @override
  void initState() {
    super.initState();
    requestPermission();

    _player.currentIndexStream.listen((index){
      if(index != null){
        _updateCurretPlayingList(index);
      }
    }
    )
  }



  @override
  Widget build(BuildContext context) {
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
                    ElevatedButton (onPressed: () {  },
                      style: buttonStyle,
                      child: Icon(Icons.shuffle_sharp,color: Colors.pink,),
                    ),
                    const SizedBox(width: 10.0,),
                    ElevatedButton (onPressed: () {  },
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
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          songs.clear();
          songs = snapshot.data!;
          return Expanded(
            child: ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Duration? duration = snapshot.data![index].duration != null
                    ? Duration(milliseconds: snapshot.data![index].duration!)
                    : null;
                String durationString = duration != null
                    ? '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
                    : '';
                return GestureDetector(
                  onTap: () async{

                    _changePlayerView();
                    String? uri = snapshot.data![index].uri;
                    await _player.setAudioSource(
                      createPlaylist(snapshot.data),
                      initialIndex: index
                    );
                    await _player.play();
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
                            id: snapshot.data![index].id,
                            type: ArtworkType.AUDIO,
                          )
                      ),
                        Flexible(child:
                        Container(
                          margin: EdgeInsets.only(top: 15,right: 10,left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(snapshot.data![index].title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                                )),
                              Text(snapshot.data![index].artist ?? "No Artist",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18
                                  )
                              ),
                              Text(durationString + " | " + snapshot.data![index].fileExtension,
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
    setState(() {
      if(songs.isNotEmpty){
        currentSongTitle = songs[index].title;
        currentIndex = index;
      }
    });
  }
}

class DurationState{
  DurationState({this.position = Duration.zero, this.total = Duration.zero});
  Duration position, total;
}
