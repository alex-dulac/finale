import 'dart:math';

import 'package:finale/components/display_component.dart';
import 'package:finale/components/error_component.dart';
import 'package:finale/components/image_component.dart';
import 'package:finale/components/loading_component.dart';
import 'package:finale/components/tags_component.dart';
import 'package:finale/components/wiki_component.dart';
import 'package:finale/lastfm.dart';
import 'package:finale/types/generic.dart';
import 'package:finale/types/lartist.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';

class ArtistView extends StatefulWidget {
  final BasicArtist artist;

  ArtistView({Key key, @required this.artist}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ArtistViewState();
}

class _ArtistViewState extends State<ArtistView>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  var selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LArtist>(
      future: Lastfm.getArtist(widget.artist),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorComponent(error: snapshot.error);
        } else if (!snapshot.hasData) {
          return LoadingComponent();
        }

        final artist = snapshot.data;

        return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text(artist.name),
              actions: [
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    Share.share(artist.url);
                  },
                ),
              ],
            ),
            body: ListView(
              children: [
                Center(
                    child: ImageComponent(
                        displayable: artist,
                        quality: ImageQuality.high,
                        fit: BoxFit.cover,
                        width: min(MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height / 2))),
                SizedBox(height: 10),
                IntrinsicHeight(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Scrobbles'),
                        Text(formatNumber(artist.stats.playCount))
                      ],
                    ),
                    VerticalDivider(),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Listeners'),
                        Text(formatNumber(artist.stats.listeners))
                      ],
                    ),
                    VerticalDivider(),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Your scrobbles'),
                        Text(formatNumber(artist.stats.userPlayCount))
                      ],
                    ),
                  ],
                )),
                if (artist.topTags.tags.isNotEmpty) Divider(),
                if (artist.topTags.tags.isNotEmpty)
                  TagsComponent(topTags: artist.topTags),
                if (artist.bio != null) Divider(),
                if (artist.bio != null) WikiComponent(wiki: artist.bio),
                Divider(),
                TabBar(
                    labelColor: Colors.red,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.red,
                    controller: _tabController,
                    tabs: [
                      Tab(icon: Icon(Icons.album)),
                      Tab(icon: Icon(Icons.audiotrack)),
                    ],
                    onTap: (index) {
                      setState(() {
                        selectedIndex = index;
                        _tabController.animateTo(index);
                      });
                    }),
                IndexedStack(index: selectedIndex, children: [
                  Visibility(
                    visible: selectedIndex == 0,
                    maintainState: true,
                    child: DisplayComponent(
                        scrollable: false,
                        request: ArtistGetTopAlbumsRequest(artist.name)),
                  ),
                  Visibility(
                    visible: selectedIndex == 1,
                    maintainState: true,
                    child: DisplayComponent(
                        scrollable: false,
                        request: ArtistGetTopTracksRequest(artist.name)),
                  ),
                ])
              ],
            ));
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }
}
