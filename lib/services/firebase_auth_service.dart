part of hrgg_app;

final FirebaseAuthService firebaseAuthService = FirebaseAuthService();

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void> initialize() => _googleSignIn.initialize();

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    await _saveUserAndLogin(credential, provider: 'password', name: name);
    await appDataService.ensureUserWorkspace();
    await appDataService.registerPrimaryDevice();
    return credential;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _saveUserAndLogin(credential, provider: 'password');
    await appDataService.ensureUserWorkspace();
    await appDataService.registerPrimaryDevice();
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.authenticate();
    final googleCredential = GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
    );
    final credential = await _auth.signInWithCredential(googleCredential);
    await _saveUserAndLogin(credential, provider: 'google.com');
    await appDataService.ensureUserWorkspace();
    await appDataService.registerPrimaryDevice();
    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> _saveUserAndLogin(
    UserCredential credential, {
    required String provider,
    String? name,
  }) async {
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase 사용자 정보를 확인할 수 없습니다.');
    }

    final userRef = _firestore.collection('users').doc(user.uid);
    final loginRef = userRef.collection('loginHistory').doc();
    final batch = _firestore.batch();

    batch.set(
      userRef,
      {
        'uid': user.uid,
        'email': user.email,
        'displayName':
            name?.trim().isNotEmpty == true ? name!.trim() : user.displayName,
        'photoUrl': user.photoURL,
        'providers': user.providerData.map((item) => item.providerId).toList(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (credential.additionalUserInfo?.isNewUser ?? false)
          'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(loginRef, {
      'provider': provider,
      'loggedInAt': FieldValue.serverTimestamp(),
      'isNewUser': credential.additionalUserInfo?.isNewUser ?? false,
      'platform': defaultTargetPlatform.name,
      'success': true,
    });

    await batch.commit();
  }
}

String firebaseAuthErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '올바른 이메일 주소를 입력해주세요.';
      case 'weak-password':
        return '비밀번호는 6자 이상 입력해주세요.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      case 'too-many-requests':
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
      case 'account-exists-with-different-credential':
        return '같은 이메일로 가입된 다른 로그인 방법이 있습니다.';
      default:
        return error.message ?? '인증 처리 중 오류가 발생했습니다.';
    }
  }
  if (error is FirebaseException) {
    return '데이터 저장에 실패했습니다. Firestore 설정을 확인해주세요.';
  }
  return '처리 중 오류가 발생했습니다. 다시 시도해주세요.';
}
