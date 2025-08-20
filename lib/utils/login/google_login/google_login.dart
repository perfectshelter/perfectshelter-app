import 'package:perfectshelter/exports/main_export.dart';
import 'package:perfectshelter/utils/login/lib/login_status.dart';
import 'package:perfectshelter/utils/login/lib/login_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleLogin extends LoginSystem {
  GoogleSignIn? _googleSignIn;

  @override
  Future<void> init() async {
    _googleSignIn = GoogleSignIn(
      scopes: ['profile', 'email'],
    );
  }

  @override
  Future<UserCredential?> login() async {
    try {
      emit(MProgress());
      final googleSignIn = await _googleSignIn?.signIn();

      if (googleSignIn == null) {
        Widgets.hideLoder(context);

        await HelperUtils.showSnackBarMessage(
            context, 'googleLoginFailed'.translate(context!));
        return null;
      }
      final googleAuth = await googleSignIn.authentication;

      final AuthCredential authCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await firebaseAuth.signInWithCredential(authCredential);
      emit(MSuccess(userCredential, type: 'google'));

      return userCredential;
    } on PlatformException catch (e) {
      if (e.code == 'network_error') {
        emit(MFail('noInternet'.translate(context!)));
      }
    } on FirebaseAuthException catch (e) {
      emit(MFail(ErrorFilter.check(e.code)));
    } on Exception catch (_) {
      emit(MFail('googleLoginFailed'.translate(context!)));
    }
    return null;
  }

  @override
  void onEvent(MLoginState state) {
    if (kDebugMode) print('MLoginState is: $state');
  }
}
