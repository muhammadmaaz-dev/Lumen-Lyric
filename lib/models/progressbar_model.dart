class ProgressBarState {
  final Duration current;
  final Duration total;

  ProgressBarState({required this.current, required this.total});

  // Ye helpers UI mein calculation se bachayenge
  double get currentSeconds => current.inSeconds.toDouble();
  double get totalSeconds =>
      total.inSeconds.toDouble() < 1 ? 1 : total.inSeconds.toDouble();
  // Agar progress slider ke end se aage nikal jaye to crash na ho
  double get safeValue =>
      currentSeconds > totalSeconds ? totalSeconds : currentSeconds;
}
