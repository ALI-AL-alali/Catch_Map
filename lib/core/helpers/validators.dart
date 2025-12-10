class Validators {
  /// ✅ يتحقق من البريد الإلكتروني
  static String? email(
    String? value, {
    String fieldName = "البريد الإلكتروني",
  }) {
    if (value == null || value.trim().isEmpty) {
      return "الرجاء إدخال $fieldName";
    }

    const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    if (!RegExp(pattern).hasMatch(value.trim())) {
      return "$fieldName غير صالح";
    }
    return null;
  }

  /// ✅ يتحقق من كلمة المرور
  static String? password(
    String? value, {
    int minLength = 8,
    bool requireUpperCase = false,
    bool requireNumber = false,
    bool requireSpecialChar = false,
  }) {
    if (value == null || value.isEmpty) {
      return "الرجاء إدخال كلمة المرور";
    }

    if (value.length < minLength) {
      return "يجب أن تكون كلمة المرور $minLength أحرف على الأقل";
    }

    if (requireUpperCase && !RegExp(r'[A-Z]').hasMatch(value)) {
      return "يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل";
    }

    if (requireNumber && !RegExp(r'[0-9]').hasMatch(value)) {
      return "يجب أن تحتوي كلمة المرور على رقم واحد على الأقل";
    }

    if (requireSpecialChar && !RegExp(r'[!@#\$&*~]').hasMatch(value)) {
      return "يجب أن تحتوي كلمة المرور على رمز خاص واحد على الأقل";
    }

    return null;
  }

  /// ✅ تأكيد كلمة المرور
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return "الرجاء تأكيد كلمة المرور";
    }
    if (value != password) {
      return "كلمة المرور غير مطابقة";
    }
    return null;
  }

  /// ✅ تحقق من رقم الهاتف السوري
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return "الرجاء إدخال رقم الهاتف";
    }

    // يقبل أرقام تبدأ بـ 09 وتليها 8 أرقام
    if (!RegExp(r'^09\d{8}$').hasMatch(value)) {
      return "رقم الهاتف غير صالح";
    }

    // استبعاد بعض الشبكات
    if (value.startsWith('090') ||
        value.startsWith('091') ||
        value.startsWith('097')) {
      return "هذا الرقم غير مدعوم";
    }

    return null;
  }

  /// ✅ تحقق عام من أي حقل نصي
  static String? requiredField(
    String? value, {
    String fieldName = 'هذا الحقل',
  }) {
    if (value == null || value.trim().isEmpty) {
      return "الرجاء إدخال $fieldName";
    }
    return null;
  }

  /// ✅ تحقق من الاسم
  static String? name(String? value, {int minLength = 2}) {
    if (value == null || value.trim().isEmpty) {
      return "الرجاء إدخال الاسم";
    }
    if (value.trim().length < minLength) {
      return "الاسم يجب أن يحتوي على $minLength أحرف على الأقل";
    }
    return null;
  }
}
