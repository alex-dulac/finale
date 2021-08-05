import 'dart:async';

import 'package:finale/services/generic.dart';
import 'package:finale/services/image_id.dart';
import 'package:finale/widgets/base/loading_component.dart';
import 'package:finale/widgets/entity/entity_image.dart';
import 'package:finale/widgets/scrobble/scrobble_button.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

enum DisplayType { list, grid }

typedef EntityWidgetBuilder<T extends Entity> = Widget Function(T item);

typedef EntityAndItemsWidgetBuilder<T extends Entity> = Widget Function(
    T item, List<T> items);

class EntityDisplay<T extends Entity> extends StatefulWidget {
  final List<T>? items;
  final PagedRequest<T>? request;
  final Stream<PagedRequest<T>>? requestStream;

  final EntityWidgetBuilder<T>? detailWidgetBuilder;
  final EntityAndItemsWidgetBuilder<T>? subtitleWidgetBuilder;
  final EntityWidgetBuilder<T>? leadingWidgetBuilder;
  final FutureOr<Entity> Function(T item)? scrobbleableEntity;

  final DisplayType displayType;
  final bool scrollable;
  final bool displayNumbers;
  final bool displayImages;
  final bool displayCircularImages;
  final bool showNoResultsMessage;
  final bool showGridTileGradient;
  final double gridTileSize;
  final double gridTileTextPadding;
  final double fontSize;

  const EntityDisplay(
      {Key? key,
      this.items,
      this.request,
      this.requestStream,
      this.detailWidgetBuilder,
      this.subtitleWidgetBuilder,
      this.leadingWidgetBuilder,
      this.scrobbleableEntity,
      this.displayType = DisplayType.list,
      this.scrollable = true,
      this.displayNumbers = false,
      this.displayImages = true,
      this.displayCircularImages = false,
      this.showNoResultsMessage = true,
      this.showGridTileGradient = true,
      this.gridTileSize = 250,
      this.gridTileTextPadding = 16,
      this.fontSize = 14})
      : assert(items != null || request != null || requestStream != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() => EntityDisplayState<T>();
}

class EntityDisplayState<T extends Entity> extends State<EntityDisplay<T>>
    with AutomaticKeepAliveClientMixin {
  var items = <T>[];
  var page = 1;
  var didInitialRequest = false;
  var isDoingRequest = false;
  var hasMorePages = true;

  PagedRequest<T>? _request;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    if (widget.items != null) {
      items = widget.items!;
      didInitialRequest = true;
      return;
    }

    if (widget.request != null) {
      _request = widget.request;
      getInitialItems();
    } else {
      _subscription = widget.requestStream?.listen((newRequest) {
        setState(() {
          _request = newRequest;
          getInitialItems();
        });
      });
    }
  }

  Future<void> getInitialItems() async {
    didInitialRequest = false;
    items = [];

    try {
      final initialItems = await _request!.doRequest(20, 1);
      setState(() {
        items = initialItems;
        hasMorePages = initialItems.length >= 20;
        didInitialRequest = true;

        if (hasMorePages) {
          page = 2;
        }
      });
    } on Exception catch (error, stackTrace) {
      assert(() {
        print('$error\n$stackTrace');
        return true;
      }());

      setState(() {
        hasMorePages = false;
      });
    }
  }

  Future<void> _getMoreItems() async {
    if (isDoingRequest || !hasMorePages) return;

    setState(() {
      isDoingRequest = true;
    });

    try {
      final moreItems = await _request!.doRequest(20, page);
      setState(() {
        items.addAll(moreItems);
        hasMorePages = moreItems.length >= 20;

        if (hasMorePages) {
          page += 1;
        }
      });
    } on Exception catch (error, stackTrace) {
      assert(() {
        print('$error\n$stackTrace');
        return true;
      }());

      setState(() {
        hasMorePages = false;
      });
    } finally {
      setState(() {
        isDoingRequest = false;
      });
    }
  }

  void _onTap(T item) {
    assert(widget.detailWidgetBuilder != null);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => widget.detailWidgetBuilder!(item)));
  }

  Widget _listItemBuilder(BuildContext context, int index) {
    final item = items[index];
    return ListTile(
      visualDensity: VisualDensity.compact,
      title: Text(
          (widget.displayNumbers ? '${index + 1}. ' : '') + item.displayTitle),
      onTap: widget.detailWidgetBuilder != null
          ? () {
              _onTap(item);
            }
          : null,
      subtitle: item.displaySubtitle != null ||
              widget.subtitleWidgetBuilder != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.displaySubtitle != null) Text(item.displaySubtitle!),
                if (widget.subtitleWidgetBuilder != null)
                  widget.subtitleWidgetBuilder!(item, items),
              ],
            )
          : null,
      leading: widget.leadingWidgetBuilder != null
          ? widget.leadingWidgetBuilder!(item)
          : widget.displayImages
              ? EntityImage(
                  entity: item,
                  quality: ImageQuality.low,
                  isCircular: widget.displayCircularImages,
                )
              : null,
      trailing: IntrinsicWidth(
          child: Row(
        children: [
          if (item.displayTrailing != null)
            Text(item.displayTrailing!,
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          if (widget.scrobbleableEntity != null)
            ScrobbleButton(entity: widget.scrobbleableEntity!(item)),
        ],
      )),
    );
  }

  Widget _gridTileBuilder(BuildContext context, int index) {
    final item = items[index];
    return GridTile(
      header: widget.scrobbleableEntity != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ScrobbleButton(
                    entity: widget.scrobbleableEntity!(item),
                    color: Colors.white),
              ],
            )
          : null,
      footer: Container(
          margin: EdgeInsets.all(widget.gridTileTextPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.fontSize > 0)
                Text(
                  item.displayTitle,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (item.displaySubtitle != null)
                Text(
                  item.displaySubtitle!,
                  style: TextStyle(
                    fontSize: widget.fontSize - 1,
                    color: Colors.white,
                  ),
                ),
              if (item.displayTrailing != null)
                Text(
                  item.displayTrailing!,
                  style: TextStyle(
                    fontSize: widget.fontSize - 1,
                    color: Colors.white,
                  ),
                ),
            ],
          )),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.displayImages)
            EntityImage(entity: item, fit: BoxFit.cover),
          if (widget.showGridTileGradient)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: FractionalOffset.topCenter,
                  end: FractionalOffset.bottomCenter,
                  colors: [
                    Colors.grey.withOpacity(0),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _gridItemBuilder(BuildContext context, int index) {
    if (widget.detailWidgetBuilder != null) {
      return InkWell(
          onTap: () {
            _onTap(items[index]);
          },
          child: _gridTileBuilder(context, index));
    }

    return _gridTileBuilder(context, index);
  }

  Widget _mainBuilder(BuildContext context) {
    if (items.isEmpty) {
      // The Stack is a hack to make the RefreshIndicator work.
      return Stack(children: [
        ListView(),
        widget.showNoResultsMessage
            ? Center(child: Text("No results."))
            : SizedBox()
      ]);
    }

    return CustomScrollView(
        physics: widget.scrollable
            ? AlwaysScrollableScrollPhysics()
            : NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        slivers: [
          if (widget.displayType == DisplayType.list)
            SliverList(
                delegate: SliverChildBuilderDelegate(_listItemBuilder,
                    childCount: items.length)),
          if (widget.displayType == DisplayType.grid)
            SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: widget.gridTileSize),
                delegate: SliverChildBuilderDelegate(_gridItemBuilder,
                    childCount: items.length)),
          if (_request != null && hasMorePages)
            SliverVisibilityDetector(
              key: UniqueKey(),
              sliver: SliverToBoxAdapter(
                child: SafeArea(
                  child: isDoingRequest
                      ? const ListTile(
                          leading: CircularProgressIndicator(),
                          title: Text('Loading...'),
                        )
                      : const ListTile(
                          leading: Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.arrow_upward, size: 36),
                          ),
                          title: Text('Scroll to load more items'),
                        ),
                ),
              ),
              onVisibilityChanged: (visibilityInfo) {
                if (visibilityInfo.visibleFraction > 0.95) {
                  _getMoreItems();
                }
              },
            )
        ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!didInitialRequest) {
      return LoadingComponent();
    }

    if (widget.items != null) {
      return _mainBuilder(context);
    }

    return RefreshIndicator(
      onRefresh: getInitialItems,
      child: _mainBuilder(context),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  @override
  bool get wantKeepAlive => true;
}
