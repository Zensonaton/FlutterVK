'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "300d57104f91448f6e1faad12f1b00b8",
"assets/AssetManifest.bin.json": "4cec0f7d8c1678fead66b55aaf3366c2",
"assets/AssetManifest.json": "df19ed28eabd0dafd8474a2eba23e539",
"assets/assets/animations/alternativeSlider.riv": "7b9191748f292f71909bda49dbea5996",
"assets/assets/animations/appWideColors.riv": "f218d4b3c91123568aea0d4ff40d8614",
"assets/assets/animations/dynamicSchemeType.riv": "15676dd32a5681ddb060ebc8cdd97c27",
"assets/assets/animations/oled.riv": "17480b048427042f55efa91a5d44ab41",
"assets/assets/animations/spoilerNextAudio": "d087c3e4d740239fc473984f2636543c",
"assets/assets/animations/spoilerNextAudio.riv": "d087c3e4d740239fc473984f2636543c",
"assets/assets/animations/theme.riv": "629ddac517174914a236d266bc5a2946",
"assets/assets/audios/playback-error-en.mp3": "520cb5fc5d6d4d0d9c6eea26483adfe4",
"assets/assets/audios/playback-error-ru.mp3": "cee3fe20067ddf57673bdc6aea7ecb21",
"assets/assets/icon.ico": "90ad852feb881044b5df8f3d014d538b",
"assets/assets/icon.png": "7ee983d87f3cf60c7a1ed2b7d7bfb03e",
"assets/assets/images/audioEqualizer.gif": "01ecc0ca7a55c98b4e9f5566277bac6b",
"assets/assets/images/dog.gif": "47ed7c9c5cfca2f518290501a2ea6396",
"assets/assets/taskbar/dislike.ico": "2eacecdd23ab0467d0fd8adb4adec5f3",
"assets/assets/taskbar/favorite_off.ico": "2d33cdf4d87d00e67d6081af07cb25c8",
"assets/assets/taskbar/favorite_on.ico": "862d9d3ec06a52eef672638906103fbc",
"assets/assets/taskbar/next.ico": "ceaffecceef98cfeac9f983e231f2c6d",
"assets/assets/taskbar/pause.ico": "0f0b764d2d140989d571a92502486309",
"assets/assets/taskbar/play.ico": "7ab03deb5ff5b0b516961b35e9ffb16f",
"assets/assets/taskbar/previous.ico": "48f640fab847fdb229a0442190b89be7",
"assets/assets/taskbar/repeat_off.ico": "63c959f0b8673c32d1f440bcf764f3d0",
"assets/assets/taskbar/repeat_on.ico": "a192abc11bf3101629ba4010babc95c0",
"assets/assets/taskbar/shuffle_off.ico": "bdf38e41c091349da448c1fc3ba2f41b",
"assets/assets/taskbar/shuffle_on.ico": "0e853d88018fe3fd06563afc7badc00e",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "495e7e66df38dea8913ff579811a0c73",
"assets/NOTICES": "3af45ca36ce21dba6bd2e27fa589b689",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.css": "5a8d0222407e388155d7d1395a75d5b9",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.html": "16911fcc170c8af1c5457940bd0bf055",
"assets/packages/flutter_inappwebview_web/assets/web/web_support.js": "509ae636cfdd93e49b5a6eaf0f06d79f",
"assets/packages/media_kit/assets/web/hls1.4.10.js": "bd60e2701c42b6bf2c339dcf5d495865",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"favicon.png": "630a34400135b97f5b276223552b2d4d",
"flutter.js": "4b2350e14c6650ba82871f60906437ea",
"flutter_bootstrap.js": "78b23ed55680df0e644bb72ef51dde2a",
"icons/Icon-192.png": "b6710ebbc5ff5510440f7de8b7923503",
"icons/Icon-512.png": "5f84d76726e238502a09dda6b3ff2e25",
"icons/Icon-maskable-192.png": "45391defe8e417557fb0c2a39f2a539e",
"icons/Icon-maskable-512.png": "6d5c5d9db2a1b2ccdc7fb42474b51325",
"index.html": "f99628319665a535ab959234fcbfce16",
"/": "f99628319665a535ab959234fcbfce16",
"main.dart.js": "37fd28e22ec6715e0a1f72858fb7f1af",
"manifest.json": "6e33b7e0a4bc4f75ba842110d182aa6d",
"version.json": "127732bb2face387e5554becffbf7b1c"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
