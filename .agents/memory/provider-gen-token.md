---
name: Provider generation token pattern
description: How to prevent stale previous-user data from being written back after logout in ChangeNotifier providers
---

## Rule
Every ChangeNotifier provider that loads data asynchronously must carry an `int _generation` counter. `clear()` increments it. Each async load method captures the generation at the start and returns early if it changes before the result is assigned.

```dart
int _generation = 0;

void clear() {
  _generation++;
  _items = [];
  // ...
  notifyListeners();
}

Future<void> loadItems() async {
  final gen = _generation;
  _loading = true;
  notifyListeners();
  try {
    final result = await _db.getItems();
    if (_generation != gen) return;  // discard stale
    _items = result;
  } catch (e) {
    if (_generation != gen) return;
    _error = e.toString();
  } finally {
    if (_generation == gen) {
      _loading = false;
      notifyListeners();
    }
  }
}
```

**Why:** Without this, a DB await that started for user A can complete and overwrite the cleared state after user B logs in. The generation token is a lightweight solution that requires no cancellation tokens or Isolates.

**How to apply:** Any provider with async `load*()` methods and a `clear()` path (logout, account switch) needs this pattern. Applied to SiteProvider and WorkerProvider.
