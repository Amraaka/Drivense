//ValueNotifier holds a data
// ValueListenableBuildier: listen to the data (dont need state)

import 'package:flutter/material.dart';

ValueNotifier<int> selectedPageNotifier = ValueNotifier(0);
ValueNotifier isDarkModeNotifier = ValueNotifier(false);