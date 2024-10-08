import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// Виджет, расширяющий виджет [Slider], который хранит у себя информацию о том, какое значение выбрано, и использует именно его, пока не обновится передаваемое значение.
class ResponsiveSlider extends HookWidget {
  /// Значение, используемое у [Slider].
  final double value;

  /// Callback-метод, вызываемый во время скроллинга.
  final Function(double)? onChange;

  /// Callback-метод, вызываемый после окончания скроллинга.
  final Function(double)? onChangeEnd;

  const ResponsiveSlider({
    super.key,
    required this.value,
    this.onChange,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<double?> scrollValue = useState(null);

    return Slider(
      value: scrollValue.value ?? value,
      onChanged: (double value) {
        if (onChange != null) {
          onChange!(value);
        }

        scrollValue.value = value;
      },
      onChangeEnd: (double value) async {
        if (onChangeEnd != null) {
          await onChangeEnd!(value);
        }

        scrollValue.value = null;
      },
    );
  }
}
