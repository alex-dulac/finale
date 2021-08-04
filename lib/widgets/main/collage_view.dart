import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:finale/services/generic.dart';
import 'package:finale/services/lastfm/lastfm.dart';
import 'package:finale/util/preferences.dart';
import 'package:finale/util/util.dart';
import 'package:finale/widgets/base/app_bar.dart';
import 'package:finale/widgets/entity/entity_display.dart';
import 'package:finale/widgets/main/collage_web_warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' show AnchorElement;

class CollageView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _CollageViewState();
}

class _CollageViewState extends State<CollageView> {
  var _isSettingsExpanded = true;
  final _usernameTextController =
      TextEditingController(text: Preferences().name ?? 'Enter username');
  var _type = EntityType.album;
  var _period = Period.overall;
  var _gridSize = 5;
  var _includeText = true;
  var _includeBranding = true;

  var _isDoingRequest = false;
  var _loadingProgress = 0;
  var _numItemsToLoad = 0;
  Uint8List? _image;
  final _screenshotController = ScreenshotController();

  int get _numGridItems => _gridSize * _gridSize;

  Future<void> _doRequest() async {
    setState(() {
      _loadingProgress = 0;
      _numItemsToLoad = _numGridItems;
      _isDoingRequest = true;
      _isSettingsExpanded = false;
      _image = null;
    });

    PagedRequest<Entity> request;

    if (_type == EntityType.album) {
      request = GetTopAlbumsRequest(_usernameTextController.text, _period);
    } else if (_type == EntityType.artist) {
      request = GetTopArtistsRequest(_usernameTextController.text, _period);
    } else {
      throw Exception('$_type is not supported for collages.');
    }

    final items = await request.doRequest(_numGridItems, 1);

    setState(() {
      _numItemsToLoad = items.length;
    });

    await Future.wait(items.map((item) async {
      await item.tryCacheImageId();
      setState(() {
        _loadingProgress++;
      });
    }));

    // On tall screens, the size of the grid tile will be constrained by the
    // width of the screen. On wide screens, the size of the grid will be
    // constrained by the height of the screen. We want to calculate both sizes
    // and take the smaller of the two to ensure that we don't overflow
    // regardless of the screen dimensions.
    final size = MediaQuery.of(context).size;
    final widthGridTileSize = size.width / _gridSize;
    final heightGridTileSize =
        (size.height - (_includeBranding ? 26 : 0)) / _gridSize;
    final gridTileSize = min(widthGridTileSize, heightGridTileSize);

    final image = await _screenshotController.captureFromWidget(
      Container(
        color: Colors.white,
        width: gridTileSize * _gridSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: EntityDisplay(
                items: items,
                displayType: DisplayType.grid,
                scrollable: false,
                showGridTileGradient: _includeText,
                gridTileSize: gridTileSize,
                fontSize: _includeText ? gridTileSize / 15 : 0,
                gridTileTextPadding: gridTileSize / 15,
              ),
            ),
            if (_includeBranding)
              Padding(
                padding: const EdgeInsets.all(3),
                child: Row(children: [
                  appIcon(size: gridTileSize / 8),
                  SizedBox(width: gridTileSize / 24),
                  Text(
                    'Created with Finale for Last.fm',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: gridTileSize / 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'https://finale.app',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: gridTileSize / 12,
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
      pixelRatio: 3,
      context: context,
    );

    setState(() {
      _image = image;
      _isDoingRequest = false;
    });
  }

  Future<File> get _imageFile async {
    final tempDir = (await getTemporaryDirectory()).path;
    final tempFile = File('$tempDir/collage.png');
    await tempFile.writeAsBytes(_image!);
    return tempFile;
  }

  Widget get _form => ExpansionPanelList(
          expandedHeaderPadding: EdgeInsets.zero,
          expansionCallback: (_, __) {
            setState(() {
              _isSettingsExpanded = !_isSettingsExpanded;
            });
          },
          children: [
            ExpansionPanel(
                headerBuilder: (_, __) =>
                    const ListTile(title: Text('Settings')),
                canTapOnHeader: true,
                isExpanded: _isSettingsExpanded,
                body: Column(
                  children: [
                    ListTile(
                      title: const Text('Username'),
                      trailing: IntrinsicWidth(
                          child:
                              TextField(controller: _usernameTextController)),
                    ),
                    ListTile(
                      title: const Text('Type'),
                      trailing: DropdownButton<EntityType>(
                        value: _type,
                        items: [
                          DropdownMenuItem(
                            value: EntityType.album,
                            child: Text('Top Albums'),
                          ),
                          DropdownMenuItem(
                            value: EntityType.artist,
                            child: Text('Top Artists'),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value != null) {
                            var shouldSet = true;

                            if (isWeb &&
                                value == EntityType.artist &&
                                !Preferences().isSpotifyLoggedIn) {
                              shouldSet = (await showDialog(
                                      context: context,
                                      builder: (_) =>
                                          CollageWebWarningDialog())) ??
                                  false;
                            }

                            if (shouldSet) {
                              setState(() {
                                _type = value;
                              });
                            }
                          }
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Period'),
                      trailing: DropdownButton<Period>(
                        value: _period,
                        items: [
                          for (final period in Period.values)
                            DropdownMenuItem(
                              value: period,
                              child: Text(period.display),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _period = value;
                            });
                          }
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Grid size'),
                      trailing: DropdownButton<int>(
                        value: _gridSize,
                        items: [
                          for (var i = 3; i <= 10; i++)
                            DropdownMenuItem(
                              value: i,
                              child: Text('${i}x$i'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _gridSize = value;
                            });
                          }
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Include text'),
                      trailing: Switch(
                        value: _includeText,
                        onChanged: (value) {
                          if (value != _includeText) {
                            setState(() {
                              _includeText = value;
                            });
                          }
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Include Finale branding'),
                      trailing: Switch(
                        value: _includeBranding,
                        onChanged: (value) {
                          if (value != _includeBranding) {
                            setState(() {
                              _includeBranding = value;
                            });
                          }
                        },
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _doRequest,
                      child: const Text('Generate'),
                    ),
                  ],
                )),
          ]);

  Widget get _loadingWidget => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: _loadingProgress / _numItemsToLoad,
              backgroundColor: Colors.grey.shade300,
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('$_loadingProgress / $_numItemsToLoad images loaded'),
              ],
            ),
          ],
        ),
      );

  Future<void> _saveImage() async {
    if (isMobile) {
      final tempFile = await _imageFile;
      await GallerySaver.saveImage(tempFile.path);
      await tempFile.delete();
    } else {
      AnchorElement()
        ..href = Uri.dataFromBytes(_image!).toString()
        ..download = 'collage.png'
        ..style.display = 'none'
        ..click()
        ..remove();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: createAppBar('Collage Generator'),
        body: Center(
          child: _isDoingRequest
              ? _loadingWidget
              : ListView(children: [
                  _form,
                  if (_image != null) ...[
                    Image.memory(_image!),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isMobile) ...[
                          OutlinedButton(
                            onPressed: () async {
                              final tempFile = await _imageFile;
                              await Share.shareFiles([tempFile.path]);
                            },
                            child: const Text('Share'),
                          ),
                          SizedBox(width: 10),
                        ],
                        OutlinedButton(
                          onPressed: _saveImage,
                          child: const Text(
                              isMobile ? 'Save to camera roll' : 'Download'),
                        ),
                      ],
                    ),
                  ],
                ]),
        ),
      );

  @override
  void dispose() {
    _usernameTextController.dispose();
    super.dispose();
  }
}
