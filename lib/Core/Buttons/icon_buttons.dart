import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class IconButtons {
  static Icon searchIcon = Icon(
    CupertinoIcons.search,
    color: Colors.black,
    size: 25,
  );

  static Icon messagesIcon = Icon(
    CupertinoIcons.mail,
    color: Colors.black,
    size: 25,
  );

  static Icon notificationIcon = Icon(
    CupertinoIcons.bell,
    color: Colors.black,
    size: 25,
  );

  static Icon tagIcon = Icon(
    CupertinoIcons.number,
    color: Colors.black,
    size: 25,
  );

  static ButtonStyle storyButtons = TextButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: 3),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    foregroundColor: Colors.white,
    splashFactory: InkRipple.splashFactory,
  );
}
