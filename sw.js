// GYT PWA service worker — network-first (ไม่ cache index ค้าง กัน auto-update พัง)
// มี fetch handler เพื่อให้ Android/Chrome ติดตั้งเป็นแอป standalone ได้ แต่ไม่เก็บ cache ค้าง
self.addEventListener('install', function(e){ self.skipWaiting(); });
self.addEventListener('activate', function(e){ e.waitUntil(self.clients.claim()); });
self.addEventListener('fetch', function(e){
  // ลองเน็ตก่อนเสมอ (ได้เวอร์ชันล่าสุด) — ถ้าออฟไลน์ค่อย fallback (ปกติแอปต้องใช้เน็ตอยู่แล้ว)
  e.respondWith(fetch(e.request).catch(function(){ return caches.match(e.request); }));
});
