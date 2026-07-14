// GYT — ดึงราคาน้ำมันบางจาก (ไฮดีเซล) ฝั่ง server เอง
// same-origin: เบราว์เซอร์เรียก /api/oil ได้ตรงๆ ไม่ต้องพึ่ง CORS proxy ภายนอก (ที่ล่มบ่อย)
// ข้อมูลราคาสาธารณะของบางจาก — cache 30 นาทีที่ edge, ยิงจริงน้อยมาก
// ใช้ raw http response method (ไม่พึ่ง helper ของ framework) เพื่อความเข้ากันได้สูงสุด
const https = require('https');

module.exports = (req, res) => {
  function send(code, contentType, body) {
    try {
      res.statusCode = code;
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Cache-Control', 's-maxage=1800, stale-while-revalidate=3600');
      res.setHeader('Content-Type', contentType);
      res.end(body);
    } catch (e) { /* response อาจถูกส่งไปแล้ว */ }
  }

  var upstream = https.request({
    hostname: 'oil-price.bangchak.co.th',
    path: '/ApiOilPrice2/th',
    method: 'GET',
    headers: {
      'User-Agent': 'Mozilla/5.0 (GYT-Transport internal fuel-cost)',
      'Accept': 'application/json, text/plain, */*'
    }
  }, function (up) {
    var body = '';
    up.setEncoding('utf8');
    up.on('data', function (chunk) { body += chunk; });
    up.on('end', function () {
      send(up.statusCode || 200, 'application/json; charset=utf-8', body);
    });
  });

  upstream.on('error', function (e) {
    send(502, 'application/json; charset=utf-8', JSON.stringify({ error: 'upstream: ' + (e && e.message ? e.message : String(e)) }));
  });
  upstream.setTimeout(10000, function () {
    upstream.destroy();
    send(504, 'application/json; charset=utf-8', JSON.stringify({ error: 'upstream timeout' }));
  });
  upstream.end();
};
