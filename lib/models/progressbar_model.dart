class ProgressBarState {
  final Duration current;
  final Duration total;

  ProgressBarState({required this.current, required this.total});

  double get currentSeconds => current.inSeconds.toDouble();
  double get totalSeconds =>
      total.inSeconds.toDouble() < 1 ? 1 : total.inSeconds.toDouble();
  double get safeValue =>
      currentSeconds > totalSeconds ? totalSeconds : currentSeconds;
}
