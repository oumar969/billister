// IO implementations (mobile/desktop) for helpers that rely on `dart:io`.

import 'dart:io';

bool isSocketException(Object e) => e is SocketException;
