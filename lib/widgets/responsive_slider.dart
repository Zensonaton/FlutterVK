import "package:flutter/material.dart";

/// Виджет, расширяющий виджет [Slider], который хранит у себя информацию о том, какое значение выбрано, и использует именно его, пока не обновится передаваемое значение.
class ResponsiveSlider extends StatefulWidget {
  /// Значение, используемое у [Slider].
  final double value;

  /// Callback-метод, вызываемый после окончания скроллинга.
  final Function(double)? onChangeEnd;

  const ResponsiveSlider({
    super.key,
    required this.value,
    this.onChangeEnd,
  });

  @override
  State<ResponsiveSlider> createState() => _ResponsiveSliderState();
}

class _ResponsiveSliderState extends State<ResponsiveSlider> {
  /// Переменная, хранящая в себе временное значение [Slider]'а, используемое во время скроллинга.
  ///
  /// Данная переменная не null только тогда, пока пользователь меняет значение у [Slider]'а.
  double? scrollValue;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: scrollValue ?? widget.value,
      onChanged: (double value) {
        setState(() => scrollValue = value);
      },
      onChangeEnd: (double value) async {
        if (widget.onChangeEnd != null) {
          await widget.onChangeEnd!(value);
        }

        scrollValue = null;
      },
    );
  }
}
