const express = require('express');
const app = express();
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'payflow-api', version: '1.0.0' });
});

app.post('/api/payment', (req, res) => {
  const { amount, currency } = req.body;
  res.json({ transaction_id: 'TXN-' + Date.now(), amount, currency, status: 'processed' });
});

app.listen(3000, () => console.log('PayFlow API running on :3000'));
