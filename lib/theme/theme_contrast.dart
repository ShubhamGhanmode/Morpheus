enum AppContrast {
  normal,
  medium,
  high,
}

extension AppContrastLabel on AppContrast {
  String get label {
    switch (this) {
      case AppContrast.normal:
        return 'Normal';
      case AppContrast.medium:
        return 'Medium';
      case AppContrast.high:
        return 'High';
    }
  }
}
