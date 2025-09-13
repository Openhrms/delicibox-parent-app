library env;

/// Feature flags / environment switches.
class Env {
  /// Keep `true` for mock auth (no Firebase needed). Switch to `false` when wiring Firebase.
  static const bool useMockAuth = false;
}

/// Alias so callers can use a stable, unique name (avoids class name collisions).
const bool kUseMockAuth = Env.useMockAuth;
