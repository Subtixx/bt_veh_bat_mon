import 'package:shared_preferences/shared_preferences.dart';
import 'package:volt_vole/logging.dart';

class Settings {
  bool _showAllDevices = false;
  bool get showAllDevices => _showAllDevices;
  set showAllDevices(bool value) {
    _showAllDevices = value;
    updateSetting('showAllDevices', value);
  }
  bool _showUnknownDevices = false;
  bool get showUnknownDevices => _showUnknownDevices;
  set showUnknownDevices(bool value) {
    _showUnknownDevices = value;
    updateSetting('showUnknownDevices', value);
  }
  bool _stopAfterDeviceFound = true;
  bool get stopAfterDeviceFound => _stopAfterDeviceFound;
  set stopAfterDeviceFound(bool value) {
    _stopAfterDeviceFound = value;
    updateSetting('stopAfterDeviceFound', value);
  }
  bool _showDuplicatedEntries = false;
  bool get showDuplicatedEntries => _showDuplicatedEntries;
  set showDuplicatedEntries(bool value) {
    _showDuplicatedEntries = value;
    updateSetting('showDuplicatedEntries', value);
  }
  double _redLowerBound = 8;
  double get redLowerBound => _redLowerBound;
  set redLowerBound(double value) {
    _redLowerBound = value;
    updateSetting('redLowerBound', value);
  }
  double _redUpperBound = 9;
  double get redUpperBound => _redUpperBound;
  set redUpperBound(double value) {
    _redUpperBound = value;
    updateSetting('redUpperBound', value);
  }
  double _yellowLowerBound = 9;
  double get yellowLowerBound => _yellowLowerBound;
  set yellowLowerBound(double value) {
    _yellowLowerBound = value;
    updateSetting('yellowLowerBound', value);
  }
  double _yellowUpperBound = 10;
  double get yellowUpperBound => _yellowUpperBound;
  set yellowUpperBound(double value) {
    _yellowUpperBound = value;
    updateSetting('yellowUpperBound', value);
  }
  int _dayFilter = 168;
  int get dayFilter => _dayFilter;
  set dayFilter(int value) {
    if (!INTERVALS.contains(value)) {
      Log.error('Invalid interval: $value');
      _dayFilter = INTERVALS.first;
      return;
    }
    _dayFilter = value;
    updateSetting('dayFilter', value);
  }
  // In hours [1hour, 1day, 7days, 30days, 90days, 365days]
  static const INTERVALS = [1, 24, 168, 720, 2160, 8760];

  bool _isLoading = true;
  get isLoading => _isLoading;

  static final Settings _instance = Settings._internal();
  Settings._internal() {
    loadSettings();
  }
  factory Settings() {
    return _instance;
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showAllDevices = prefs.getBool('showAllDevices') ?? false;
    _showUnknownDevices = prefs.getBool('showUnknownDevices') ?? false;
    _stopAfterDeviceFound = prefs.getBool('stopAfterDeviceFound') ?? true;
    _showDuplicatedEntries = prefs.getBool('showDuplicatedEntries') ?? false;
    _redLowerBound = prefs.getDouble('redLowerBound') ?? 8;
    _redUpperBound = prefs.getDouble('redUpperBound') ?? 9;
    _yellowLowerBound = prefs.getDouble('yellowLowerBound') ?? 9;
    _yellowUpperBound = prefs.getDouble('yellowUpperBound') ?? 10;
    _dayFilter = prefs.getInt('dayFilter') ?? INTERVALS.first;

    if (!INTERVALS.contains(_dayFilter)) {
      Log.error('Invalid interval: $_dayFilter');
      _dayFilter = INTERVALS.first;
    }

    _isLoading = false;
  }

  Future<void> updateSetting(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == 'showAllDevices') {
      await prefs.setBool(key, value);
      _showAllDevices = value;
    } else if (key == 'showUnknownDevices') {
      await prefs.setBool(key, value);
      _showUnknownDevices = value;
    } else if (key == 'stopAfterDeviceFound') {
      await prefs.setBool(key, value);
      _stopAfterDeviceFound = value;
    } else if (key == 'showDuplicatedEntries') {
      await prefs.setBool(key, value);
      _showDuplicatedEntries = value;
    } else if (key == 'redLowerBound') {
      await prefs.setDouble(key, value);
      _redLowerBound = value;
    } else if (key == 'redUpperBound') {
      await prefs.setDouble(key, value);
      _redUpperBound = value;
    } else if (key == 'yellowLowerBound') {
      await prefs.setDouble(key, value);
      _yellowLowerBound = value;
    } else if (key == 'yellowUpperBound') {
      await prefs.setDouble(key, value);
      _yellowUpperBound = value;
    }else if (key == 'dayFilter') {
      await prefs.setInt(key, value);
      _dayFilter = value;
    }
  }

  Future<void> updateSettings() async {
    await updateSetting('showAllDevices', _showAllDevices);
    await updateSetting('showUnknownDevices', _showUnknownDevices);
    await updateSetting('stopAfterDeviceFound', _stopAfterDeviceFound);
    await updateSetting('showDuplicatedEntries', _showDuplicatedEntries);
    await updateSetting('redLowerBound', _redLowerBound);
    await updateSetting('redUpperBound', _redUpperBound);
    await updateSetting('yellowLowerBound', _yellowLowerBound);
    await updateSetting('yellowUpperBound', _yellowUpperBound);
  }
}
