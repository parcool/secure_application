class LockDisturbController {
  static final LockDisturbController _instance = LockDisturbController._internal();

  static LockDisturbController get instance {
    return _instance;
  }

  LockDisturbController._internal();

  factory LockDisturbController() => _instance;

  bool isOpenFilexDisturbing = false;
}
