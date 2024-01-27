/// enum, перечисляющий поведение того, как приложение может себя ввести в случае закрытия окна. Работает только на Desktop ([isDesktop]).
enum AppCloseBehavior {
  /// Вариант по-умолчанию: Указывает, что при нажатии на X приложение просто закроется.
  close,

  /// Приложение всегда будет сворачиваться, вместо того, что бы закрываться.
  minimize,

  /// Приложение будет сворачиваться только в том случае, если сейчас играет музыка, если ничего не играет - приложение закроется.
  minimizeIfPlaying,
}