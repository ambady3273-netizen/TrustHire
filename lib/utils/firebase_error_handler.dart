class FirebaseErrorHandler {
  static String getMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
        return 'Incorrect password.';

      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'weak-password':
        return 'Password should contain at least 6 characters.';

      case 'network-request-failed':
        return 'No internet connection.';

      case 'too-many-requests':
        return 'Too many requests. Please try again later.';

      case 'invalid-credential':
        return 'Invalid email or password.';

      default:
        return 'Something went wrong. Please try again.';
    }
  }
}