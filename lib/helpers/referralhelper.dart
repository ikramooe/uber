import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:tProject/globals.dart';

class ReferralHelper {
  static ShortDynamicLink link;
  static DynamicLinkParameters parameters;

  static void initDynamicLinks() async {
    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      print(deepLink);
      print('here');
      print(deepLink.data.toString());
      print(deepLink.query);
    }

    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink?.link;

      if (deepLink != null) {
        print(deepLink);
        print(deepLink.data);
        print(deepLink.query);
      }
    }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });
  }

  static void initialize() {
    String link = "https://orcloud.dz?invitedby=" + currentFirebaseUser.uid;
    parameters = DynamicLinkParameters(
      uriPrefix:
          'https://tproject.page.link', // uri prefix used for Dynamic Links in Firebase Console
      link: Uri.parse(link),
      androidParameters: AndroidParameters(
        packageName: 'com.example.tproject', // package name for your app
        minimumVersion: 0,
      ),
      iosParameters: IosParameters(
          bundleId: 'com.example.tproject'), // bundle ID for your app
    );
  }

  static void createLink() async {
    link = await parameters.buildShortLink();
  }
}
