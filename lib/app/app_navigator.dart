import 'package:flutter/material.dart';

/// Root [Navigator] key for opening screens from notification taps before a
/// [BuildContext] exists (e.g. cold start).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
