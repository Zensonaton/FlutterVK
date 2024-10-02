import "package:flutter/material.dart";

/// [Intent], вызываемый при нажатии [LogicalKeyboardKey.space], который управляет паузой в плеере.
class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

/// [Intent], вызываемый при нажатии [LogicalKeyboardKey.control] + [LogicalKeyboardKey.f], который открывает экран с любимыми треками.
class FavoriteTracksIntent extends Intent {
  const FavoriteTracksIntent();
}

/// [Intent], вызываемый при нажатии [LogicalKeyboardKey.control] + [LogicalKeyboardKey.arrowLeft], который перематывает в начало трека, либо запускает предыдущий.
class PreviousTrackIntent extends Intent {
  const PreviousTrackIntent();
}

/// [Intent], вызываемый при нажатии [LogicalKeyboardKey.control] + [LogicalKeyboardKey.arrowRight], который перематывает в начало следующего трека, либо запускает следующий.
class NextTrackIntent extends Intent {
  const NextTrackIntent();
}

/// [Intent], вызываемый при нажатии [LogicalKeyboardKey.arrowLeft], который перемещает плеер на [seekSeconds] секунд назад.
class RewindIntent extends Intent {
  const RewindIntent();
}

/// [Intent], вызываемый при нажатии [LogicalKeyboardKey.arrowRight], который перемещает плеер на [seekSeconds] секунд вперед.
class FastForwardIntent extends Intent {
  const FastForwardIntent();
}

/// [Intent], вызываемый при нажатии [LogicalKeyboardKey.arrowUp], который увеличивает громкость плеера на 10%.
class VolumeUpIntent extends Intent {
  const VolumeUpIntent();
}

/// [Intent], вызываемый при нажатии [LogicalKeyboardKey.arrowDown], который уменьшает громкость плеера на 10%.
class VolumeDownIntent extends Intent {
  const VolumeDownIntent();
}

/// [Intent], вызываемый при нажатии [LogicalKeyboardKey.s], который переключает shuffle в плеере.
class ShuffleIntent extends Intent {
  const ShuffleIntent();
}

/// [Intent], вызываемый при нажатии [LogicalKeyboardKey.l], который переключает повтор текущего трека в плеере.
class LoopModeIntent extends Intent {
  const LoopModeIntent();
}

/// [Intent], вызываемый при нажатии [LogicalKeyboardKey.ctrlLeft] + [LogicalKeyboardKey.q], который закрывает приложение.
class CloseAppIntent extends Intent {
  const CloseAppIntent();
}

/// [Intent], вызываемый при нажатии [LogicalKeyboardKey.f11], который открывает или закрывает полноэкранный плеер.
class FullscreenPlayerIntent extends Intent {
  const FullscreenPlayerIntent();
}
