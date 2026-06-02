/// OneSignal App ID.
/// Ganti dengan App ID dari dashboard OneSignal kamu:
/// https://app.onesignal.com → Settings → Keys & IDs
class OneSignalConfig {
  static const String appId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: 'YOUR_ONESIGNAL_APP_ID', // ganti ini
  );
}
