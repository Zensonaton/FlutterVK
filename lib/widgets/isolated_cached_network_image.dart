import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";
import "package:flutter_cache_manager/flutter_cache_manager.dart";

/// Builder function to create an image widget. The function is called after
/// the ImageProvider completes the image loading.
typedef ImageWidgetBuilder = Widget Function(
  BuildContext context,
  ImageProvider imageProvider,
);

/// Замена [CachedNetworkImage] с целью повышения производительности, поскольку разница в производительности между [CachedNetworkImage] и [Image.network] уж слишком значительна.
///
/// В данном виджете удалены переходы между состояниями загрузки изображения, поскольку они не используются в данном проекте, а они отрицательно влияют на производительность.
class IsolatedCachedImage extends StatelessWidget {
  /// Option to use cacheManager with other settings
  final BaseCacheManager? cacheManager;

  /// The target image that is displayed.
  final String imageUrl;

  /// The target image's cache key.
  final String? cacheKey;

  /// Optional builder to further customize the display of the image.
  final ImageWidgetBuilder? imageBuilder;

  /// Widget displayed while the target [imageUrl] is loading.
  final Widget? placeholder;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double? width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double? height;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit? fit;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, a [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while a
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final Alignment alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// children); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with children in right-to-left environments, for
  /// children that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip children with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  /// Optional headers for the http request of the image url
  final Map<String, String>? httpHeaders;

  /// When set to true it will animate from the old image to the new image
  /// if the url changes.
  final bool useOldImageOnUrlChange;

  /// If non-null, this color is blended with each image pixel using [colorBlendMode].
  final Color? color;

  /// Used to combine [color] with this image.
  ///
  /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
  /// the source and this image is the destination.
  ///
  /// See also:
  ///
  ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
  final BlendMode? colorBlendMode;

  /// Target the interpolation quality for image scaling.
  ///
  /// If not given a value, defaults to FilterQuality.low.
  final FilterQuality filterQuality;

  /// Will resize the image in memory to have a certain width using [ResizeImage]
  final int? memCacheWidth;

  /// Will resize the image in memory to have a certain height using [ResizeImage]
  final int? memCacheHeight;

  /// Will resize the image and store the resized image in the disk cache.
  final int? maxWidthDiskCache;

  /// Will resize the image and store the resized image in the disk cache.
  final int? maxHeightDiskCache;

  const IsolatedCachedImage({
    super.key,
    required this.imageUrl,
    this.httpHeaders,
    this.imageBuilder,
    this.placeholder,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.cacheManager,
    this.useOldImageOnUrlChange = false,
    this.color,
    this.filterQuality = FilterQuality.low,
    this.colorBlendMode,
    this.memCacheWidth,
    this.memCacheHeight,
    this.cacheKey,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Избавиться от CachedNetworkImageProvider, написать свой ImageProvider,
    // который будет использовать Isolate для загрузки изображений с сети/кэша.

    final ImageProvider provider = CachedNetworkImageProvider(
      imageUrl,
      cacheManager: cacheManager,
      cacheKey: cacheKey,
      headers: httpHeaders,
      maxHeight: maxHeightDiskCache,
      maxWidth: maxWidthDiskCache,
    );

    return Image(
      image: provider,
      key: key,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      color: color,
      filterQuality: filterQuality,
      frameBuilder: placeholder != null || imageBuilder != null
          ? (context, child, frame, loaded) {
              // TODO: Вероятнее всего, так делать не стоит.
              if (loaded || frame != null) {
                return imageBuilder?.call(context, provider) ?? child;
              }

              return placeholder ?? child;
            }
          : null,
    );
  }
}
