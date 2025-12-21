// Package imports:
import 'package:permission_handler/permission_handler.dart';

Future<dynamic?> getDeviceContact() async {
  // `contacts_service` has been removed. Return null so callers safely
  // handle absence of a device contact picker.
  try {
    final permissionStatus = await Permission.contacts.request();
    if (permissionStatus == PermissionStatus.granted) {
      // No device picker available in this build; return null.
      return null;
    } else if ([PermissionStatus.denied, PermissionStatus.permanentlyDenied]
        .contains(permissionStatus)) {
      openAppSettings();
    }
  } catch (e) {
    print('## ERROR: failed to get contact: $e');
  }

  return null;
}
