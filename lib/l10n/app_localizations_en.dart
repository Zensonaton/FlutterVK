// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get general_yes => 'Yes';

  @override
  String get general_no => 'No';

  @override
  String get general_save => 'Save';

  @override
  String get general_reset => 'Reset';

  @override
  String get general_clear => 'Clear';

  @override
  String get general_cancel => 'Cancel';

  @override
  String get general_close => 'Close';

  @override
  String get general_loading => 'Loading...';

  @override
  String get general_restore => 'Restore';

  @override
  String get general_continue => 'Continue';

  @override
  String get general_shuffle => 'Shuffle';

  @override
  String get general_play => 'Play';

  @override
  String get general_pause => 'Pause';

  @override
  String get general_resume => 'Resume';

  @override
  String get general_enable => 'Enable';

  @override
  String get general_edit => 'Edit';

  @override
  String get general_logout => 'Logout';

  @override
  String get general_exit => 'Exit';

  @override
  String get general_title => 'Title';

  @override
  String get general_artist => 'Artist';

  @override
  String get general_genre => 'Genre';

  @override
  String get general_share => 'Share';

  @override
  String get general_nothing_found => 'Nothing found';

  @override
  String get general_copy_to_downloads => 'Copy to \"Downloads\"';

  @override
  String get general_open_folder => 'Open folder';

  @override
  String get general_select => 'Select';

  @override
  String get general_details => 'Details';

  @override
  String get general_install => 'Install';

  @override
  String get general_show => 'Show';

  @override
  String general_filesize_mb({required int value}) {
    return '$value MB';
  }

  @override
  String general_filesize_gb({required double value}) {
    final intl.NumberFormat valueNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String valueString = valueNumberFormat.format(value);

    return '$valueString GB';
  }

  @override
  String get general_favorites_playlist => 'Favorites';

  @override
  String get general_search_playlist => 'Search audios';

  @override
  String get general_owned_playlist => 'Your playlist';

  @override
  String get general_saved_playlist => 'Saved playlist';

  @override
  String get general_recommended_playlist => 'Recommended playlist';

  @override
  String general_audios_count({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count audios',
      one: '$count audio',
    );
    return '$_temp0';
  }

  @override
  String get dislike_track_action => 'Dislike';

  @override
  String get enable_shuffle_action => 'Enable shuffle';

  @override
  String get disable_shuffle_action => 'Disable shuffle';

  @override
  String get previous_track_action => 'Previous';

  @override
  String get play_track_action => 'Play';

  @override
  String get pause_track_action => 'Pause';

  @override
  String get next_track_action => 'Next';

  @override
  String get enable_repeat_action => 'Enable repeat';

  @override
  String get disable_repeat_action => 'Disable repeat';

  @override
  String get favorite_track_action => 'Like';

  @override
  String get remove_favorite_track_action => 'Dislike';

  @override
  String get not_yet_implemented => 'Not implemented yet';

  @override
  String get not_yet_implemented_desc => 'This feature has not been implemented yet.';

  @override
  String get error_dialog => 'An error occurred';

  @override
  String get error_dialog_desc => 'Something went wrong. And I\'m sorry about that. Try again later.';

  @override
  String player_playback_error({required String error}) {
    return 'Playback error: $error';
  }

  @override
  String player_playback_error_stopped({required String error}) {
    return 'Playback stopped due to excessive errors: $error';
  }

  @override
  String get track_added_to_queue => 'Track added to queue.';

  @override
  String get app_restart_required => 'Restart the application to apply changes.';

  @override
  String get option_unavailable_with_light_theme => 'This option is unavailable because app is used in light theme.';

  @override
  String get option_unavailable_without_recommendations => 'This setting is unavailable you haven\'t connected VK recommendations.';

  @override
  String get option_unavailable_without_audio_playing => 'You will not be able to see changes to this settings, because no audio is playing right now.';

  @override
  String get thumbnails_unavailable_without_recommendations => 'Thumbnails aren\'t shown because you haven\'t connected VK recommendations.';

  @override
  String get app_minimized_message => 'Flutter VK minimized.\nUse the tray or reopen the app to restore the window.';

  @override
  String get tray_show_hide => 'Show/Hide';

  @override
  String get music_readme_contents => 'Hey-hey-hey! Stop right there! 🤚\n\nYes, this folder contains tracks downloaded by the Flutter VK app.\nIf you noticed, these tracks are saved in a very unusual format, and theres a reason for that.\nI, the app developer, dont want users (like you!) to easily access these tracks.\n\nIf you try hard enough, youll eventually find the track you need. However, Id prefer you didnt.\nIf it turns out that someone is using the app to download tracks, Ill have to add additional levels of obfuscation or encryption, like AES.\n\nPlease respect the work of the artists who put a lot of time into creating their tracks. Distributing them this way causes them serious harm.\nIf you still decide to distribute the tracks as .mp3 files, at least do it without any profit, only for personal use.\n\nThanks for your attention, fren :)';

  @override
  String get internet_required_title => 'No Connection';

  @override
  String get internet_required_desc => 'This action can only be performed when connected to the internet. Please connect to a network and try again.';

  @override
  String get demo_mode_enabled_title => 'Unavailable in demo mode';

  @override
  String get demo_mode_enabled_desc => 'This feature is not available in demo mode of Flutter VK.\nHead to the \"profile\" to download full version on your device.';

  @override
  String get prerelease_app_version_warning => 'Beta Version';

  @override
  String get prerelease_app_version_warning_desc => 'Shhhh! Here be dragons! You\'ve stepped into dangerous territory by installing the beta version of Flutter VK. Beta versions are less stable and not recommended for regular users.\n\nBy continuing, you acknowledge the risks of using the beta version of the app.\nThis notification will only be shown once.';

  @override
  String get demo_mode_welcome_warning => 'Demo mode';

  @override
  String get demo_mode_welcome_warning_desc => 'Welcome to demo mode of Flutter VK!\nThis app version is limited and there are performance and stability issues.\nHead to the \"profile\" to download full version on your device.';

  @override
  String get welcome_title => 'Welcome! 😎';

  @override
  String get welcome_desc => '<bold>Flutter VK</bold> is an experimental unofficial VK client built using the Flutter framework with <link>open source code</link> for listening to music without needing a VK BOOM subscription.';

  @override
  String get login_title => 'Authorization';

  @override
  String get login_desktop_desc => 'To authorize, <link>🔗 follow the link</link> and grant the app access to your VK account.\nAfter clicking allow, copy the website address from the browser\'s address bar and paste it into the field below:';

  @override
  String get login_connect_recommendations_title => 'Connect Recommendations';

  @override
  String get login_connect_recommendations_desc => 'To connect recommendations, <link>🔗 follow the link</link> and grant the app access to your VK account.\nAfter clicking allow, copy the website address from the browser\'s address bar and paste it into the field below:';

  @override
  String get login_authorize => 'Authorize';

  @override
  String get login_mobile_alternate_auth => 'Alternate Authorization Method';

  @override
  String get login_no_token_error => 'Access token was not found in the provided link.';

  @override
  String get login_no_music_access_desc => 'Flutter VK couldn\'t access the special music sections needed for the app to function.\nThis error usually occurs if you mistakenly tried to authorize using the Kate Mobile app instead of the VK Admin app.\n\nPlease carefully follow the authorization instructions and try again.';

  @override
  String login_wrong_user_id({required String name}) {
    return 'Flutter VK detected that you connected a different VK page than the one currently connected.\nPlease log in as $name on VK and try again.';
  }

  @override
  String get login_success_auth => 'Authorization successful!';

  @override
  String get music_label => 'Music';

  @override
  String get music_label_offline => 'Music (offline)';

  @override
  String get search_label => 'Search';

  @override
  String get search_label_offline => 'Search (offline)';

  @override
  String get music_library_label => 'Library';

  @override
  String get profile_label => 'Profile';

  @override
  String get profile_labelOffline => 'Profile (offline)';

  @override
  String get downloads_label => 'Downloads';

  @override
  String get downloads_label_offline => 'Downloads (offline)';

  @override
  String music_welcome_title({required String name}) {
    return 'Welcome, $name! 👋';
  }

  @override
  String category_closed({required String category}) {
    return 'You closed the {category} section. You can restore it by clicking the button in active sections.';
  }

  @override
  String get my_music_chip => 'My Music';

  @override
  String get my_playlists_chip => 'Your Playlists';

  @override
  String get realtime_playlists_chip => 'In Real Time';

  @override
  String get recommended_playlists_chip => 'Playlists for You';

  @override
  String get simillar_music_chip => 'Taste Matches';

  @override
  String get by_vk_chip => 'Curated by VK';

  @override
  String get connect_recommendations_chip => 'Connect VK Recommendations';

  @override
  String get connect_recommendations_title => 'Connect Recommendations';

  @override
  String get connect_recommendations_desc => 'By connecting recommendations, you\'ll gain access to music sections like \"Playlists for You\", \"VK Mix\", and you\'ll also get access to track covers.\n\nTo connect recommendations, you\'ll need to authorize again via VK.';

  @override
  String get all_tracks => 'All Tracks';

  @override
  String get track_unavailable_offline_title => 'Track unavailable offline';

  @override
  String get track_unavailable_offline_desc => 'You cannot listen to this track offline because you did not downloaded it earlier.';

  @override
  String get track_restricted_title => 'Audio unavailable';

  @override
  String get track_restricted_desc => 'VK reported that this audio is unavailable. This decision was likely made by the track artist or label. Since you haven\'t downloaded this track earlier, playback is impossible.';

  @override
  String search_tracks_in_playlist({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '$count track',
    );
    return 'Search among $_temp0 here';
  }

  @override
  String get playlist_is_empty => 'This playlist is empty.';

  @override
  String get playlist_search_zero_results => 'No results found for your query. Try <click>clearing your query</click>.';

  @override
  String get enable_download_title => 'Enable track downloading';

  @override
  String enable_download_desc({required int count, required String downloadSize}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '$count track',
    );
    return 'By enabling this feature, Flutter VK will automatically download all tracks in this playlist, making them available for offline listening. If you continue, Flutter VK will download $_temp0, that\'ll take ~$downloadSize of internet traffic.';
  }

  @override
  String get disable_download_title => 'Delete downloaded tracks';

  @override
  String disable_download_desc({required int count, required String size}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved tracks',
      one: '$count saved track',
    );
    return 'You will remove $_temp0 which are taking up $size on your device. After removal, you will not be able to listen to this playlist offline. Are you sure you want to continue?';
  }

  @override
  String get stop_downloading_button => 'Stop';

  @override
  String get delete_downloaded_button => 'Delete';

  @override
  String playlist_downloading({required String title}) {
    return 'Downloading playlist \"$title\"';
  }

  @override
  String playlist_download_removal({required String title}) {
    return 'Removing tracks from playlist \"$title\"';
  }

  @override
  String get search_music_global => 'Search VK music';

  @override
  String get type_to_search => 'Enter the song title above to start searching.';

  @override
  String get audio_restore_too_late_desc => 'The track cannot be restored because too much time has passed since its deletion. Use the search to find this track and add it again.';

  @override
  String get add_track_as_liked => 'Mark as liked';

  @override
  String get remove_track_as_liked => 'Remove from liked';

  @override
  String get open_track_playlist => 'Open playlist';

  @override
  String get add_track_to_playlist => 'Add to playlist';

  @override
  String get play_track_next => 'Play next';

  @override
  String get go_to_track_album => 'Go to album';

  @override
  String go_to_track_album_desc({required String title}) {
    return 'Opens the album page \"$title\"';
  }

  @override
  String get search_track_on_genius => 'Search on Genius';

  @override
  String get search_track_on_genius_desc => 'Track lyrics and other information from Genius';

  @override
  String get download_this_track => 'Download';

  @override
  String get download_this_track_desc => 'Allows you to listen to the track even without an internet connection';

  @override
  String get change_track_thumbnail => 'Change cover';

  @override
  String get change_track_thumbnail_desc => 'Sets the cover by searching from Deezer';

  @override
  String get reupload_track_from_youtube => 'Reupload from YouTube';

  @override
  String get reupload_track_from_youtube_desc => 'Locally replaces this audio with a version from YouTube';

  @override
  String get replace_track_with_local => 'Replace with local audio';

  @override
  String get replace_track_with_local_desc => 'Locally replaces this audio with another one downloaded on your device';

  @override
  String get replace_track_with_local_filepicker_title => 'Select a track for replacement';

  @override
  String get replace_track_with_local_success => 'The track was successfully replaced on this device.';

  @override
  String get remove_local_track_version => 'Remove local track version';

  @override
  String get remove_local_track_success => 'The track was successfully restored.';

  @override
  String get remove_local_track_is_restricted_title => 'Track is restricted';

  @override
  String get remove_local_track_is_restricted_desc => 'This track is unavailable for playback. Continuing will remove this track from your device, and you will no longer be able to listen to it here. Are you sure you want to lose access to this track?';

  @override
  String get track_details => 'Track details';

  @override
  String get change_track_thumbnail_search_text => 'Deezer query';

  @override
  String get change_track_thumbnail_type_to_search => 'Enter the track title above to search for covers.';

  @override
  String get icon_tooltip_downloaded => 'Downloaded';

  @override
  String get icon_tooltip_replaced_locally => 'Replaced locally';

  @override
  String get icon_tooltip_restricted => 'Unavailable';

  @override
  String get icon_tooltip_restricted_playable => 'Restricted but playable';

  @override
  String get track_info_edit_error_restricted => 'You cannot edit this track because it is an official release.';

  @override
  String track_info_edit_error({required String error}) {
    return 'An error occurred while editing the track: $error';
  }

  @override
  String get all_blocks_disabled => 'Woah! It looks like there is nothing here.';

  @override
  String get all_blocks_disabled_desc => 'Turn something on by clicking the desired switch above.';

  @override
  String simillarity_percent({required int simillarity}) {
    return '<bold>$simillarity%</bold> match with you';
  }

  @override
  String get fullscreen_no_audio => '<bold>Sshhhh, don\'t wake up the doggo</bold>!\n\nYou have nothing playing right now.\nClick <exit>here</exit> to close the player.';

  @override
  String logout_desc({required String name}) {
    return 'Are you sure you want to log out of the $name account in the Flutter VK app?';
  }

  @override
  String get no_recommendations_warning => 'Recommendations are not connected';

  @override
  String get no_recommendations_warning_desc => 'Connected Recommendations give you access to curated by VK playlists with new tracks, and ability to see audio thumbnails. Tap here to connect Recommendations and fix this.';

  @override
  String get demo_mode_warning => 'You are running in demo mode';

  @override
  String get demo_mode_warning_desc => 'Because of this, some features may be disabled or not work correctly.\n\nTap here to install full version of Flutter VK on your device.';

  @override
  String get player_queue_header => 'Playing music from';

  @override
  String get player_lyrics_header => 'Lyrics source';

  @override
  String get lyrics_vk_source => 'VK';

  @override
  String get lyrics_lrclib_source => 'LRCLib';

  @override
  String get global_search_query => 'What are you looking for?';

  @override
  String get search_history => 'Search history';

  @override
  String get visual_settings => 'Visual & cosmetic settings';

  @override
  String get app_theme => 'Theme';

  @override
  String get app_theme_desc => 'The dark theme makes the UI more pleasant for use, especially at night or dark environments. Additionally, you can enable the OLED theme, which makes the app background as black as possible to save battery on some devices.';

  @override
  String get app_theme_system => 'System';

  @override
  String get app_theme_light => 'Light';

  @override
  String get app_theme_dark => 'Dark';

  @override
  String get oled_theme => 'OLED theme';

  @override
  String get oled_theme_desc => 'With the OLED theme, a truly black color will be used for the background. This can save battery on some devices.';

  @override
  String get enable_oled_theme => 'Use OLED theme';

  @override
  String get use_player_colors_appwide => 'Track colors app-wide';

  @override
  String get use_player_colors_appwide_desc => 'After enabling this setting, colors of the playing track cover will be shown throughout the app.';

  @override
  String get enable_player_colors_appwide => 'Allow track colors app-wide';

  @override
  String get player_dynamic_color_scheme_type => 'Cover color palette type';

  @override
  String get player_dynamic_color_scheme_type_desc => 'This setting specifies how bright the color palette will be displayed in the player during music playback.';

  @override
  String get player_dynamic_color_scheme_type_tonalSpot => 'Default';

  @override
  String get player_dynamic_color_scheme_type_neutral => 'Neutral';

  @override
  String get player_dynamic_color_scheme_type_content => 'Bright';

  @override
  String get player_dynamic_color_scheme_type_monochrome => 'Monochrome';

  @override
  String get alternate_slider => 'Alternate slider';

  @override
  String get alternate_slider_desc => 'Determines slider position for displaying track playback progress in the bottom player.';

  @override
  String get enable_alternate_slider => 'Move slider above player';

  @override
  String get use_track_thumb_as_player_background => 'Track image as fullscreen player background';

  @override
  String get spoiler_next_audio => 'Spoiler next track';

  @override
  String get spoiler_next_audio_desc => 'This setting indicates whether the title of the next track will be displayed before finishing the current one.';

  @override
  String get enable_spoiler_next_audio => 'Show next track';

  @override
  String get crossfade_audio_colors => 'Player color crossfade';

  @override
  String get crossfade_audio_colors_desc => 'Makes a smooth transition of player colors before the next track starts.';

  @override
  String get enable_crossfade_audio_colors => 'Enable color crossfade';

  @override
  String get show_audio_thumbs => 'Show covers';

  @override
  String get show_audio_thumbs_desc => 'This setting indicates whether music thumbnails will be shown.\n\nChanges to this setting won\'t affect the player.';

  @override
  String get enable_show_audio_thumbs => 'Show track covers';

  @override
  String get music_player => 'Music player';

  @override
  String get track_title_in_window_bar => 'Track title in window bar';

  @override
  String get close_action => 'Action on window close';

  @override
  String get close_action_desc => 'Determines whether the app will actually close when the window is closed';

  @override
  String get close_action_close => 'Close';

  @override
  String get close_action_minimize => 'Minimize';

  @override
  String get close_action_minimize_if_playing => 'Minimize if music is playing';

  @override
  String get android_keep_playing_on_close => 'Playback after swiping';

  @override
  String get android_keep_playing_on_close_desc => 'Determines whether playback will continue after closing the app in the list of open apps on Android';

  @override
  String get shuffle_on_play => 'Shuffle on play';

  @override
  String get shuffle_on_play_desc => 'Shuffles tracks in the playlist when playback starts';

  @override
  String get profile_pauseOnMuteTitle => 'Pause on silent volume';

  @override
  String get profile_pauseOnMuteDescription => 'Playback will pause when the volume is set to minimum';

  @override
  String get stop_on_long_pause => 'Stop on inactivity';

  @override
  String get stop_on_long_pause_desc => 'The player will stop playing after a long pause, potentially saving battery life and device resources';

  @override
  String get rewind_on_previous => 'Rewind on previous track';

  @override
  String get rewind_on_previous_desc => 'In which cases an attempt to start the previous track will rewind to the beginning instead of starting the previous track.\nA repeated attempt to rewind within a short time will start the previous track regardless of the setting value';

  @override
  String get rewind_on_previous_always => 'Always';

  @override
  String get rewind_on_previous_only_via_ui => 'Only via UI';

  @override
  String get rewind_on_previous_only_via_notification => 'Only via notification/headphones';

  @override
  String get rewind_on_previous_only_via_disabled => 'Never';

  @override
  String get check_for_duplicates => 'Duplicate prevention';

  @override
  String get check_for_duplicates_desc => 'You will see a warning that the track is already liked to avoid saving it twice';

  @override
  String get track_duplicate_found_title => 'Duplicate found';

  @override
  String get track_duplicate_found_desc => 'It looks like this track is already saved. Saving this track will create another copy of it.\nAre you sure you want to create a duplicate of this track?';

  @override
  String get discord_rpc => 'Discord Rich Presence';

  @override
  String get discord_rpc_desc => 'Broadcasts the playing track in Discord';

  @override
  String get player_debug_logging => 'Debug player logging';

  @override
  String get player_debug_logging_desc => 'Enables output of technical data of the music player to the log. This option is intended for debugging purposes and is not recommended for regular use. Usage of this option may lead to performance issues.';

  @override
  String get experimental_options => 'Experimental features';

  @override
  String get deezer_thumbnails => 'Deezer covers';

  @override
  String get deezer_thumbnails_desc => 'Downloads covers for tracks from Deezer if the track does not have one.\nSometimes may provide incorrect/low-quality covers';

  @override
  String get lrclib_lyrics => 'Lyrics via LRCLIB';

  @override
  String get lrclib_lyrics_desc => 'Downloads lyrics from LRCLIB if the track does not have them or they are not synchronized.\nSometimes may provide incorrect/low-quality lyrics';

  @override
  String get apple_music_animated_covers => 'Animated covers from Apple Music';

  @override
  String get apple_music_animated_covers_desc => 'Downloads animated covers for tracks from Apple Music if the track does not have one.\nSometimes may provide incorrect/low-quality covers';

  @override
  String get volume_normalization => 'Volume normalization';

  @override
  String get volume_normalization_desc => 'Automatically adjusts the volume of tracks to a consistent level';

  @override
  String get volume_normalization_dialog_desc => '\"Normal\" and \"loud\" setting values may cause distortion in some tracks.';

  @override
  String get volume_normalization_disabled => 'Disabled';

  @override
  String get volume_normalization_quiet => 'Quiet';

  @override
  String get volume_normalization_normal => 'Normal';

  @override
  String get volume_normalization_loud => 'Loud';

  @override
  String get silence_removal => 'Silence removal';

  @override
  String get silence_removal_desc => 'Removes silence from beginning and end of audio tracks';

  @override
  String get app_settings => 'App settings';

  @override
  String get export_settings => 'Export settings';

  @override
  String get export_settings_desc => 'Saves local track changes and app settings to a file to restore them on another device';

  @override
  String get import_settings => 'Import settings';

  @override
  String get import_settings_desc => 'Loads a file previously created using \"export settings\"';

  @override
  String get export_music_list => 'Export track list';

  @override
  String export_music_list_desc({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count liked tracks',
      one: '$count liked track',
    );
    return 'List of $_temp0:';
  }

  @override
  String get export_settings_title => 'Export settings';

  @override
  String get export_settings_tip => 'About settings export';

  @override
  String get export_settings_tip_desc => 'Settings export is a feature that allows you to save app and track settings to a special file for manual transfer to another device.\n\nAfter exporting, you will need to transfer the file to another device and use the <importSettings><importSettingsIcon></importSettingsIcon> Import settings</importSettings> feature to load the changes.';

  @override
  String get export_settings_modified_settings => 'Flutter VK settings';

  @override
  String export_settings_modified_settings_desc({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count settings',
      one: '$count setting',
    );
    return '$_temp0 changed';
  }

  @override
  String get export_settings_modified_thumbnails => 'Changed track covers';

  @override
  String export_settings_modified_thumbnails_desc({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count covers',
      one: '$count cover',
    );
    return '$_temp0 changed using the <colored><icon></icon> Change cover</colored> option';
  }

  @override
  String get export_settings_modified_lyrics => 'Changed lyrics';

  @override
  String export_settings_modified_lyrics_desc({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lyrics',
      one: '$count lyric',
    );
    return '$_temp0 changed';
  }

  @override
  String get export_settings_modified_metadata => 'Changed track metadata';

  @override
  String export_settings_modified_metadata_desc({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '$count track',
    );
    return '$_temp0 changed';
  }

  @override
  String get export_settings_downloaded_restricted => 'Downloaded but restricted tracks';

  @override
  String export_settings_downloaded_restricted_desc({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '$count track',
    );
    return '$_temp0 available for listening despite restricted access due to caching';
  }

  @override
  String get export_settings_locally_replaced => 'Locally replaced tracks';

  @override
  String export_settings_locally_replaced_desc({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '$count track',
    );
    return '$_temp0 replaced using the <colored><icon></icon> Local track replacement</colored> option';
  }

  @override
  String get export_settings_export => 'Export';

  @override
  String get export_settings_success => 'Export completed';

  @override
  String get export_settings_success_desc => 'Export completed successfully! Manually transfer the file to another device and use the \"import settings\" option to restore the changes.';

  @override
  String get copy_to_downloads_success => 'The file was successfully copied to the \"Downloads\" folder.';

  @override
  String get settings_import => 'Import settings';

  @override
  String get settings_import_tip => 'About settings import';

  @override
  String get settings_import_tip_desc => 'Settings import is a feature that synchronizes Flutter VK app settings and track changes made on another device.\n\nNot sure where to start? Refer to the <exportSettings><exportSettingsIcon></exportSettingsIcon> Export settings</exportSettings> feature.';

  @override
  String get settings_import_select_file => 'No file selected for settings import.';

  @override
  String get settings_import_select_file_dialog_title => 'Select a file for settings and tracks import';

  @override
  String get settings_import_version_missmatch => 'Compatibility issue';

  @override
  String settings_import_version_missmatch_desc({required String version}) {
    return 'This file was created in a previous version of Flutter VK (v$version), which may cause issues with the import.\n\nAre you sure you want to continue?';
  }

  @override
  String get settings_import_import => 'Import';

  @override
  String get settings_import_success => 'Settings import successful';

  @override
  String get settings_import_success_desc_with_delete => 'Settings and tracks import completed successfully.\n\nYou may need to restart the app for some settings to be saved and applied.\n\nAfter import, the export file is no longer needed. Do you want to delete it?';

  @override
  String get settings_import_success_desc_no_delete => 'Settings and tracks import completed successfully. You may need to restart the app for some settings to be saved and applied.';

  @override
  String get reset_db => 'Reset track database';

  @override
  String get reset_db_desc => 'Clears the local copy of the track database stored on this device';

  @override
  String get reset_db_dialog => 'Reset track database';

  @override
  String get reset_db_dialog_desc => 'Continuing will delete the track database stored on this device. Please do not do this unless absolutely necessary.\n\nYour tracks (both liked and downloaded) will not be deleted, but you will need to restart the caching process on previously downloaded playlists.';

  @override
  String get app_updates_policy => 'Updates display type';

  @override
  String get app_updates_policy_desc => 'Determines how the app will notify you about new updates';

  @override
  String get app_updates_policy_dialog => 'Dialog';

  @override
  String get app_updates_policy_popup => 'Bottom popup';

  @override
  String get app_updates_policy_disabled => 'Disabled';

  @override
  String get disable_updates_warning => 'Disable app updates';

  @override
  String get disable_updates_warning_desc => 'It looks like you are trying to disable app updates. This is not recommended as future versions may fix bugs and add new features.\n\nIf you are annoyed by the fullscreen dialog, try changing this setting to \"Bottom popup\": This option will not interfere with your usage.';

  @override
  String get disable_updates_warning_disable => 'Disable anyway';

  @override
  String get updates_are_disabled => 'App updates are disabled. You can check for updates manually by clicking the \"About the app\" button on the profile page.';

  @override
  String get updates_channel => 'Updates channel';

  @override
  String get updates_channel_desc => 'The beta channel has more frequent but less stable builds';

  @override
  String get updates_channel_releases => 'Main (default)';

  @override
  String get updates_channel_prereleases => 'Beta';

  @override
  String get share_logs => 'Share log file';

  @override
  String get share_logs_desc => 'Technical information for debugging errors';

  @override
  String get share_logs_desc_no_logs => 'Unavailable because the log file is empty';

  @override
  String get about_flutter_vk => 'About Flutter VK';

  @override
  String get app_telegram => 'Telegram channel';

  @override
  String get app_telegram_desc => 'Clicking here will open Telegram channel with CI builds and other information';

  @override
  String get app_github => 'Source code';

  @override
  String get app_github_desc => 'Click here to visit the Github repository of Flutter VK';

  @override
  String get show_changelog => 'Changelog';

  @override
  String get show_changelog_desc => 'Shows the changelog for this version';

  @override
  String changelog_dialog({required String version}) {
    return 'Changelog for $version';
  }

  @override
  String get app_version => 'About the app';

  @override
  String app_version_desc({required Object version}) {
    return 'Installed version: $version.\nClick here to check for new updates';
  }

  @override
  String get app_version_prerelease => 'beta';

  @override
  String get download_manager_current_tasks => 'Currently downloading';

  @override
  String get download_manager_old_tasks => 'Previously downloaded';

  @override
  String download_manager_all_tasks({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '$count task',
    );
    return '$_temp0 total';
  }

  @override
  String get download_manager_no_tasks => 'Empty...';

  @override
  String get update_available => 'Flutter VK update available';

  @override
  String update_available_desc({required String oldVersion, required String newVersion, required DateTime date, required DateTime time, required String badges}) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'v$oldVersion <arrow></arrow> v$newVersion, $dateString, $timeString. $badges';
  }

  @override
  String get update_prerelease_type => '<debug></debug> beta';

  @override
  String app_update_download_long_title({required String version}) {
    return 'Flutter VK update v$version';
  }

  @override
  String update_available_popup({required Object version}) {
    return 'Flutter VK update $version available.';
  }

  @override
  String update_check_error({required String error}) {
    return 'Error checking for updates: $error';
  }

  @override
  String get update_pending => 'Update download started. Wait for the download to complete, then follow the instructions.';

  @override
  String get update_install_error => 'Update installation error';

  @override
  String get no_updates_available => 'The latest version of the app is installed.';
}
