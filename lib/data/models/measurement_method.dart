enum MeasurementMethod {
  touch,
  ppg,
  combined;

  String get label {
    switch (this) {
      case MeasurementMethod.touch:
        return '터치 방식';
      case MeasurementMethod.ppg:
        return '카메라 방식';
      case MeasurementMethod.combined:
        return '복합 방식';
    }
  }
}
