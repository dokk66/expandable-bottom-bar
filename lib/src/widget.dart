import 'package:expandable_bottom_bar/src/controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BottomExpandableAppBar extends StatefulWidget {
  final Widget expandedBody;
  final double expandedHeight;
  final Widget bottomAppBarBody;
  final BottomBarController controller;

  final double appBarHeight;
  // TODO: Get max available height
  final bool useMax;

  final BoxConstraints constraints;

  final NotchedShape shape;
  final Color expandedBackColor;
  final Color bottomAppBarColor;
  final double horizontalMargin;
  final double bottomOffset;

  final Decoration expandedDecoration;
  final Decoration appBarDecoration;

  BottomExpandableAppBar({
    Key key,
    this.expandedBody,
    this.horizontalMargin: 16,
    this.bottomOffset: 10,
    this.shape,
    this.expandedHeight: 150,
    this.appBarHeight: 50,
    this.constraints,
    this.bottomAppBarColor,
    this.appBarDecoration,
    this.bottomAppBarBody,
    this.expandedBackColor,
    this.expandedDecoration,
    this.controller,
    this.useMax: false,
  })  : assert(!(expandedBackColor != null && expandedDecoration != null)),
        super(key: key);

  @override
  _BottomExpandableAppBarState createState() => _BottomExpandableAppBarState();
}

class _BottomExpandableAppBarState extends State<BottomExpandableAppBar> {
  BottomBarController _controller;
  double panelState;

  void _handleBottomBarControllerAnimationTick() {
    if (_controller.animation.value == panelState) return;
    panelState = _controller.animation.value;
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTabController();
    panelState = _controller?.animation?.value ?? panelState;
  }

  @override
  void didUpdateWidget(BottomExpandableAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) _updateTabController();
  }

  @override
  void dispose() {
    if (_controller != null)
      _controller.animation
          .removeListener(_handleBottomBarControllerAnimationTick);
    // We don't own the _controller Animation, so it's not disposed here.
    super.dispose();
  }

  void _updateTabController() {
    final BottomBarController newController =
        widget.controller ?? DefaultBottomBarController.of(context);
    assert(() {
      if (newController == null) {
        throw FlutterError('No BottomBarController for ${widget.runtimeType}.\n'
            'When creating a ${widget.runtimeType}, you must either provide an explicit '
            'BottomBarController using the "controller" property, or you must ensure that there '
            'is a DefaultBottomBarController above the ${widget.runtimeType}.\n'
            'In this case, there was neither an explicit controller nor a default controller.');
      }
      return true;
    }());

    if (newController == _controller) return;

    if (_controller != null) {
      _controller.animation
          .removeListener(_handleBottomBarControllerAnimationTick);
    }
    _controller = newController;
    if (_controller != null) {
      _controller.animation
          .addListener(_handleBottomBarControllerAnimationTick);
    }
  }

  @override
  Widget build(BuildContext context) {
    final finalHeight = (widget.useMax && widget.constraints != null)
        ? widget.constraints.biggest.height
        : widget.expandedHeight;

    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: widget.horizontalMargin ?? 0),
            child: Stack(
              children: [
                Container(
                  height: panelState * finalHeight +
                      widget.appBarHeight +
                      widget.bottomOffset,
                  decoration: widget.expandedDecoration ??
                      BoxDecoration(
                        color: widget.expandedBackColor ??
                            Theme.of(context).backgroundColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                  child: Opacity(
                      opacity: panelState > 0.25 ? 1 : panelState * 4,
                      child: widget.expandedBody),
                ),
              ],
            ),
          ),
          // * Mask content of bottom container in notch
          Container(
            // some mask code
            height: widget.appBarHeight,
          ),
          ClipPath(
            child: Container(
              color: widget.bottomAppBarColor ??
                  Theme.of(context).bottomAppBarColor,
              height: widget.appBarHeight,
              child: widget.bottomAppBarBody,
            ),
            clipper: _BottomAppBarClipper(
              geometry: Scaffold.geometryOf(context),
              shape: widget.shape,
              notchMargin: 5,
              buttonOffset: widget.bottomOffset,
            ),
          ),
        ],
      ),
    );
  }
}

//Copied from flutter sdk
class _BottomAppBarClipper extends CustomClipper<Path> {
  const _BottomAppBarClipper(
      {@required this.geometry,
      @required this.shape,
      @required this.notchMargin,
      @required this.buttonOffset})
      : assert(geometry != null),
        assert(shape != null),
        assert(notchMargin != null),
        super(reclip: geometry);

  final ValueListenable<ScaffoldGeometry> geometry;
  final NotchedShape shape;
  final double notchMargin;
  final double buttonOffset;

  @override
  Path getClip(Size size) {
    // button is the floating action button's bounding rectangle in the
    // coordinate system whose origin is at the appBar's top left corner,
    // or null if there is no floating action button.
    final Rect button = geometry.value.floatingActionButtonArea?.translate(
      0.0,
      geometry.value.bottomNavigationBarTop * -1.0 - buttonOffset,
    );
    return shape.getOuterPath(
        Offset(0, 0) & size, button?.inflate(notchMargin));
  }

  @override
  bool shouldReclip(_BottomAppBarClipper oldClipper) {
    return oldClipper.geometry != geometry ||
        oldClipper.shape != shape ||
        oldClipper.notchMargin != notchMargin;
  }
}
