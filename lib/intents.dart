import "package:flutter/material.dart";

/// [Intent], вызываемый при нажатии [LogicalKeyboardKey.space], который управляет паузой в плеере.
class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

/// [Intent], вызываемый при нажатии [LogicalKeyboardKey.f11], который открывает или закрывает полноэкранный плеер.
class FullscreenPlayerIntent extends Intent {
  const FullscreenPlayerIntent();
}
