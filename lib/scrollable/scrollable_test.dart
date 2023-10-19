import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SwipeableItem extends StatefulWidget {
  final SliverChildDelegate childrenDelegate;

  const SwipeableItem({Key? key, required this.childrenDelegate}) : super(key: key);

  @override
  _SwipeableItemState createState() => _SwipeableItemState();
}

class _SwipeableItemState extends State<SwipeableItem> {
  final ScrollController controller = ScrollController();
  final AxisDirection axisDirection = AxisDirection.left;

  @override
  Widget build(BuildContext context) {
    return Scrollable(
      axisDirection: axisDirection,
      dragStartBehavior: DragStartBehavior.start,
      viewportBuilder: (context, position) {
        print(position);
        return Viewport(
          axisDirection: axisDirection,
          offset: position,
          clipBehavior: Clip.antiAlias,
          slivers: <Widget>[
            SliverFillViewport(
              viewportFraction: 1,
              delegate: widget.childrenDelegate,
            ),
          ],
        );
      },
      physics: PageScrollPhysics(),
      controller: controller,
    );
  }
}
