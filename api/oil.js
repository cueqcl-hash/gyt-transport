// GYT — ดึงราคาน้ำมันบางจาก (ไฮดีเซล) ฝั่ง server เอง
// same-origin: เบราว์เซอร์เรียก /api/oil ได้ตรงๆ ไม่ต้องพึ่ง CORS proxy ภายนอก (ที่ล่มบ่อย)
// ข้อมูลราคาสาธารณะของบางจาก — cache 30 นาทีที่ edge, ยิงจริงน้อยมาก
const https = require('https');

module.exports = (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Cache-Control', 's-maxage=1800, stale-while-revalidate=3600');

  const upstream = https.request({
    hostname: 'oil-price.bangchak.co.th',
    path: '/ApiOilPrice2/th',
    method: 'GET',
    headers: {
      'User-Agent': 'Mozilla/5.0 (GYT-Transport internal fuel-cost)',
      'Accept': 'application/json, text/plain, */*'
    }
  }, (up) => {
    let body = '';
    up.setEncoding('utf8');
    up.on('data', (chunk) => { body += chunk; });
    up.on('end', () => {
      res.setHeader('Content-Type', 'application/json; charset=utf-8');
      res.status(up.statusCode || 200).send(body);
    });
  });

  upstream.on('error', (e) => {
    res.status(502).json({ error: 'upstream: ' + (e && e.message ? e.message : String(e)) });
  });
  upstream.setTimeout(10000, () => {
    upstream.destroy();
    if (!res.headersSent) res.status(504).json({ error: 'upstream timeout' });
  });
  upstream.end();
};
