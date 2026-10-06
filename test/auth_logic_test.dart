import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/features/auth/data/account_service.dart';
import 'package:fitrix/features/auth/data/auth_failure.dart';
import 'package:fitrix/features/auth/presentation/widgets/code_input.dart';
import 'package:fitrix/features/profile/data/models/profile_row.dart';
import 'package:fitrix/features/profile/data/models/user_profile.dart';
import 'package:fitrix/features/profile/data/repositories/profile_repository.dart';

import 'support/fake_auth.dart';

UserProfile _profile({
  String name = 'Alex',
  String surname = 'Smith',
  String age = '30',
  String weight = '72.5',
  String height = '180',
}) =>
    UserProfile(
      name: name,
      surname: surname,
      age: age,
      weight: weight,
      height: height,
    );

void main() {
  group('ProfileValidator', () {
    test('accepts a plausible profile', () {
      expect(ProfileValidator.validate(_profile()), isEmpty);
      expect(ProfileValidator.validate(_profile(surname: '')), isEmpty);
      expect(ProfileValidator.validate(_profile(weight: '72,5')), isEmpty);
    });

    test('requires a name, age, weight and height', () {
      final errors = ProfileValidator.validate(
        _profile(name: '  ', age: '', weight: '', height: ''),
      );
      expect(errors.keys, unorderedEquals(['name', 'age', 'weight', 'height']));
    });

    test('matches the database limits', () {
      expect(ProfileValidator.age('4'), isNotNull);
      expect(ProfileValidator.age('5'), isNull);
      expect(ProfileValidator.age('120'), isNull);
      expect(ProfileValidator.age('121'), isNotNull);
      expect(ProfileValidator.age('30.5'), isNotNull);
      expect(ProfileValidator.age('abc'), isNotNull);

      expect(ProfileValidator.weight('19.9'), isNotNull);
      expect(ProfileValidator.weight('20'), isNull);
      expect(ProfileValidator.weight('400'), isNull);
      expect(ProfileValidator.weight('400.1'), isNotNull);
      expect(ProfileValidator.weight('seventy'), isNotNull);

      expect(ProfileValidator.height('79'), isNotNull);
      expect(ProfileValidator.height('80'), isNull);
      expect(ProfileValidator.height('260'), isNull);
      expect(ProfileValidator.height('261'), isNotNull);

      expect(ProfileValidator.name('a' * 100), isNull);
      expect(ProfileValidator.name('a' * 101), isNotNull);
      expect(ProfileValidator.surname('a' * 101), isNotNull);
    });

    test('normalizes text and numbers', () {
      final profile = ProfileValidator.normalize(
        _profile(name: ' Alex ', weight: '72,50', height: '180.0'),
      );
      expect(profile.name, 'Alex');
      expect(profile.weight, '72.5');
      expect(profile.height, '180');
    });
  });

  group('ProfileRow', () {
    test('local profile → upsert payload', () {
      final row = ProfileRow.fromLocal(
        id: 'u1',
        profile: _profile(weight: '72,5'),
        language: 'ru',
      );
      expect(row.toUpsert(), {
        'id': 'u1',
        'name': 'Alex',
        'surname': 'Smith',
        'age': 30,
        'weight_kg': 72.5,
        'height_cm': 180.0,
        'language': 'ru',
      });
    });

    test('onboarding_complete is only ever sent as true', () {
      final done = ProfileRow.fromLocal(
        id: 'u1',
        profile: _profile(),
        onboardingComplete: true,
      );
      expect(done.toUpsert()['onboarding_complete'], isTrue);
      final notDone = ProfileRow.fromLocal(id: 'u1', profile: _profile());
      expect(notDone.toUpsert().containsKey('onboarding_complete'), isFalse);
    });

    test('without the profile only language and onboarding are sent', () {
      final row = ProfileRow.fromLocal(
        id: 'u1',
        profile: _profile(),
        language: 'es',
        onboardingComplete: true,
      );
      expect(row.toUpsert(includeProfile: false), {
        'id': 'u1',
        'language': 'es',
        'onboarding_complete': true,
      });
    });

    test('values the database would reject become null', () {
      final row = ProfileRow.fromLocal(
        id: 'u1',
        profile: _profile(
          name: 'n' * 150,
          age: 'old',
          weight: '1000',
          height: '-5',
        ),
        language: 'fr',
      );
      expect(row.name.length, ProfileLimits.nameMaxLength);
      expect(row.age, isNull);
      expect(row.weightKg, isNull);
      expect(row.heightCm, isNull);
      expect(row.language, 'en');
    });

    test('database row → local profile', () {
      final row = ProfileRow.fromJson({
        'id': 'u1',
        'name': 'Alex',
        'surname': 'Smith',
        'age': 30,
        'weight_kg': 72.5,
        'height_cm': 180,
        'language': 'uz',
        'onboarding_complete': true,
      });
      expect(row.onboardingComplete, isTrue);
      expect(row.language, 'uz');
      final profile = row.toUserProfile();
      expect(profile.name, 'Alex');
      expect(profile.age, '30');
      expect(profile.weight, '72.5');
      expect(profile.height, '180');
    });

    test('a fresh row with nulls maps to empty fields', () {
      final profile = ProfileRow.fromJson({'id': 'u1', 'age': null})
          .toUserProfile();
      expect(profile.age, '');
      expect(profile.weight, '');
      expect(profile.height, '');
    });
  });

  group('AppRouter.redirectFor', () {
    String? redirect(
      String location, {
      bool onboarded = false,
      bool authEnabled = true,
      bool signedIn = false,
    }) =>
        AppRouter.redirectFor(
          location: location,
          onboardingComplete: onboarded,
          authEnabled: authEnabled,
          signedIn: signedIn,
        );

    test('local-only mode behaves as before accounts', () {
      expect(redirect(AppRouter.intro, authEnabled: false), isNull);
      expect(redirect(AppRouter.profile, authEnabled: false), isNull);
      expect(redirect(AppRouter.home, authEnabled: false), isNull);
      expect(
        redirect(AppRouter.intro, authEnabled: false, onboarded: true),
        AppRouter.home,
      );
      expect(
        redirect(AppRouter.signIn, authEnabled: false, onboarded: true),
        AppRouter.home,
      );
      expect(redirect(AppRouter.me, authEnabled: false, onboarded: true),
          isNull);
    });

    test('onboarded and signed in: onboarding routes go Home', () {
      expect(redirect(AppRouter.intro, onboarded: true, signedIn: true),
          AppRouter.home);
      expect(redirect(AppRouter.signIn, onboarded: true, signedIn: true),
          AppRouter.home);
      expect(redirect(AppRouter.me, onboarded: true, signedIn: true), isNull);
    });

    test('onboarded without a session: sign in again', () {
      expect(redirect(AppRouter.home, onboarded: true), AppRouter.signIn);
      expect(redirect(AppRouter.intro, onboarded: true), AppRouter.signIn);
      expect(redirect(AppRouter.workouts, onboarded: true), AppRouter.signIn);
      expect(redirect(AppRouter.signIn, onboarded: true), isNull);
    });

    test('onboarding steps after sign-in need a session', () {
      expect(redirect(AppRouter.intro), isNull);
      expect(redirect(AppRouter.language), isNull);
      expect(redirect(AppRouter.signIn), isNull);
      expect(redirect(AppRouter.profile), AppRouter.signIn);
      expect(redirect(AppRouter.chat), AppRouter.signIn);
      expect(redirect(AppRouter.transition), AppRouter.signIn);
      expect(redirect(AppRouter.profile, signedIn: true), isNull);
    });
  });

  group('AuthFailure.from', () {
    test('maps Supabase errors', () {
      expect(
        AuthFailure.from(
          const AuthApiException('Token has expired or is invalid',
              statusCode: '403', code: 'otp_expired'),
          verifying: true,
        ).kind,
        AuthFailureKind.invalidCode,
      );
      expect(
        AuthFailure.from(const AuthApiException('slow down',
                statusCode: '429', code: 'over_email_send_rate_limit'))
            .kind,
        AuthFailureKind.rateLimited,
      );
      expect(
        AuthFailure.from(const AuthApiException('slow down',
                statusCode: '429', code: 'over_request_rate_limit'))
            .kind,
        AuthFailureKind.rateLimited,
      );
      expect(
        AuthFailure.from(const AuthApiException('bad',
                statusCode: '400', code: 'email_address_invalid'))
            .kind,
        AuthFailureKind.invalidEmail,
      );
      expect(
        AuthFailure.from(const AuthApiException('boom', statusCode: '400'))
            .kind,
        AuthFailureKind.unknown,
      );
    });

    test('maps connection problems to "no connection"', () {
      expect(AuthFailure.from(AuthRetryableFetchException(message: 'x')).kind,
          AuthFailureKind.network);
      expect(AuthFailure.from(const SocketException('offline')).kind,
          AuthFailureKind.network);
      expect(AuthFailure.from(TimeoutException('slow')).kind,
          AuthFailureKind.network);
    });

    test('email format check', () {
      expect(looksLikeEmail('a@b.co'), isTrue);
      expect(looksLikeEmail(' a@b.co '), isTrue);
      expect(looksLikeEmail('a@b'), isFalse);
      expect(looksLikeEmail('not an email'), isFalse);
      expect(looksLikeEmail(''), isFalse);
    });
  });

  group('CodeDigitsFormatter', () {
    final formatter = CodeDigitsFormatter(6);
    String apply(String old, String typed) => formatter
        .formatEditUpdate(
          TextEditingValue(text: old),
          TextEditingValue(text: typed),
        )
        .text;

    test('keeps digits only, up to six', () {
      expect(apply('', '12a3'), '123');
      expect(apply('', 'Code: 123 456'), '123456');
      expect(apply('12', '12345678'), '345678', reason: 'pasted code wins');
      expect(apply('123456', '1234567'), '123456', reason: 'full stays full');
    });
  });

  group('AccountService', () {
    late SharedPreferences prefs;
    late AppSession session;
    late FakeAuthGateway auth;
    late FakeProfileRemote remote;
    late AccountService account;

    Future<void> setUpWith(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      prefs = await SharedPreferences.getInstance();
      session = AppSession(prefs);
      auth = FakeAuthGateway(users: {'a@x.com': 'user-a', 'b@x.com': 'user-b'});
      remote = FakeProfileRemote();
      account = AccountService(
        prefs: prefs,
        session: session,
        auth: auth,
        remote: remote,
        retryDelay: (_) => const Duration(milliseconds: 10),
      )..start();
      addTearDown(account.dispose);
    }

    test('new account continues onboarding and remembers the account',
        () async {
      await setUpWith({'language': 'ru'});
      auth.signInAs('a@x.com');
      expect(await account.completeSignIn('user-a'), SignInDestination.profile);
      expect(session.accountUserId, 'user-a');
      expect(session.onboardingComplete, isFalse);
      expect(account.isSignedIn, isTrue);
    });

    test('returning account on a new device is restored and goes Home',
        () async {
      await setUpWith({'language': 'en'});
      remote.rows['user-a'] = {
        'id': 'user-a',
        'name': 'Alex',
        'surname': '',
        'age': 30,
        'weight_kg': 72.5,
        'height_cm': 180,
        'language': 'es',
        'onboarding_complete': true,
      };
      auth.signInAs('a@x.com');
      final generation = session.generation;

      expect(await account.completeSignIn('user-a'), SignInDestination.home);
      expect(session.onboardingComplete, isTrue);
      expect(session.generation, generation + 1);
      expect(prefs.getString('language'), 'es');
      final profile = await ProfileRepository().getProfile();
      expect(profile!.name, 'Alex');
      expect(profile.weight, '72.5');
    });

    test('a started but unfinished profile pre-fills the form', () async {
      await setUpWith({});
      remote.rows['user-a'] = {'id': 'user-a', 'name': 'Al', 'age': 40};
      auth.signInAs('a@x.com');
      expect(await account.completeSignIn('user-a'), SignInDestination.profile);
      expect((await ProfileRepository().getProfile())!.age, '40');
    });

    test('another account signing in clears the previous data first',
        () async {
      await setUpWith({
        'account_user_id': 'user-a',
        'onboarding_complete': true,
        'user_name': 'Alex',
        'workout_history': '[]',
        'language': 'ru',
        'sb-127-auth-token': 'session',
      });
      auth.signInAs('b@x.com');

      expect(await account.completeSignIn('user-b'), SignInDestination.profile);
      expect(session.accountUserId, 'user-b');
      expect(session.onboardingComplete, isFalse);
      expect(prefs.getString('user_name'), isNull);
      expect(prefs.getString('workout_history'), isNull);
      expect(prefs.getString('language'), 'ru', reason: 'chosen on device');
      expect(prefs.getString('sb-127-auth-token'), 'session',
          reason: 'the new session is kept');
    });

    test('the same account signing back in keeps local data, no fetch',
        () async {
      await setUpWith({
        'account_user_id': 'user-a',
        'onboarding_complete': true,
        'user_name': 'Alex',
      });
      remote.fetchError = const SocketException('offline');
      auth.signInAs('a@x.com');

      expect(await account.completeSignIn('user-a'), SignInDestination.home);
      expect(prefs.getString('user_name'), 'Alex');
    });

    test('data from before accounts existed is adopted and uploaded',
        () async {
      await setUpWith({
        'onboarding_complete': true,
        'user_name': 'Alex',
        'user_age': '30',
      });
      auth.signInAs('a@x.com');
      expect(await account.completeSignIn('user-a'), SignInDestination.home);
      await account.flush();
      expect(remote.rows['user-a']!['name'], 'Alex');
      expect(remote.rows['user-a']!['onboarding_complete'], isTrue);
      expect(account.hasPendingUpload, isFalse);
    });

    test('a failed profile load changes nothing and can be retried',
        () async {
      await setUpWith({'account_user_id': 'user-a', 'user_name': 'Alex'});
      remote.fetchError = const SocketException('offline');
      auth.signInAs('b@x.com');

      await expectLater(account.completeSignIn('user-b'), throwsException);
      expect(session.accountUserId, 'user-a');
      expect(prefs.getString('user_name'), 'Alex');

      remote.fetchError = null;
      expect(await account.completeSignIn('user-b'), SignInDestination.profile);
      expect(prefs.getString('user_name'), isNull);
    });

    test('profile upload retries until it lands', () async {
      await setUpWith({'language': 'uz'});
      auth.signInAs('a@x.com');
      await account.completeSignIn('user-a');
      await ProfileRepository().saveProfile(_profile());

      remote.upsertError = const SocketException('offline');
      expect(await account.profileChanged(), isFalse);
      expect(account.hasPendingUpload, isTrue);

      remote.upsertError = null;
      // The back-off timer (10ms in this test) sends it again.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await account.flush();
      expect(account.hasPendingUpload, isFalse);
      expect(remote.rows['user-a']!['age'], 30);
      expect(remote.rows['user-a']!['language'], 'uz');
      expect(remote.rows['user-a']!['onboarding_complete'], isFalse);

      await session.completeOnboarding();
      expect(await account.profileChanged(), isTrue);
      expect(remote.rows['user-a']!['onboarding_complete'], isTrue);
    });

    test('pending upload is re-sent on the next launch', () async {
      await setUpWith({
        'account_user_id': 'user-a',
        'onboarding_complete': true,
        'profile_sync_pending': true,
        'user_name': 'Alex',
      });
      // Persisted session restored at launch, after start() ran.
      auth.signInAs('a@x.com');
      await account.flush();
      expect(remote.rows['user-a']!['onboarding_complete'], isTrue);
      expect(account.hasPendingUpload, isFalse);
    });

    test('nothing is uploaded for a different signed-in account', () async {
      await setUpWith({
        'account_user_id': 'user-a',
        'profile_sync_pending': true,
        'user_name': 'Alex',
      });
      auth.signInAs('b@x.com');
      expect(await account.flush(), isFalse);
      expect(remote.upserts, 0);
    });

    test('sign-out ends the session and clears the device, even offline',
        () async {
      await setUpWith({
        'account_user_id': 'user-a',
        'onboarding_complete': true,
        'user_name': 'Alex',
        'profile_sync_pending': true,
      });
      auth.signInAs('a@x.com');
      remote.upsertError = const SocketException('offline');

      await account.signOut();
      expect(auth.signOutCalls, 1);
      expect(auth.userId, isNull);
      expect(prefs.getKeys(), isEmpty);
    });
  });
}
