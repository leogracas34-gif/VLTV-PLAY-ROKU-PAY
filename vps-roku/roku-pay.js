// VLTV Play - VPS | Compra Roku Pay: POST /lg/roku/comprar
// Plugado no license.js:  require('./roku-pay')(pub, { db, verificar, assinar, ativar, resposta, agoraS, limitar });
const https = require('https');
const express = require('express');

module.exports = function (pub, X) {
  const { db, verificar, assinar, ativar, resposta, agoraS, limitar } = X;
  const PRODUTOS = { vltv_anual: 12, vltv_vitalicio: 'vitalicio' };
  const VITALICIO = 4102444800;

  function validar(txid) {
    return new Promise((ok) => {
      const key = process.env.ROKU_API_KEY;
      if (!key) return ok({ erro: 'sem_chave' });
      const rq = https.get({
        host: 'apipub.roku.com',
        path: '/listen/transaction-service.svc/validate-transaction/' + encodeURIComponent(key) + '/' + encodeURIComponent(txid),
        headers: { Accept: 'application/json' }, timeout: 8000,
      }, (r) => {
        let b = ''; r.on('data', (c) => (b += c));
        r.on('end', () => { try { ok({ json: JSON.parse(b) }); } catch (e) { ok({ erro: 'resposta' }); } });
      });
      rq.on('timeout', () => { rq.destroy(); ok({ erro: 'rede' }); });
      rq.on('error', () => ok({ erro: 'rede' }));
    });
  }

  function dataSeg(s) {
    if (!s) return 0;
    const m = /\/Date\((\d+)/.exec(String(s));
    const ms = m ? Number(m[1]) : Date.parse(String(s));
    return Number.isFinite(ms) ? Math.floor(ms / 1000) : 0;
  }

  pub.post('/lg/roku/comprar', limitar('roku', 30, 3600000), express.json({ limit: '10kb' }), async (req, res) => {
    try {
      const h = req.headers['authorization'] || '';
      const id = verificar(h.startsWith('Bearer ') ? h.slice(7) : '');
      if (!id) return res.status(401).json({ error: 'token' });
      const d = db.prepare('SELECT * FROM devices WHERE device_id = ?').get(id);
      if (!d) return res.status(404).json({ error: 'desconhecido' });

      const b = req.body || {};
      const txid = String(b.transaction_id || '').slice(0, 200);
      const cod = String(b.product_code || '');
      if (!txid || !Object.prototype.hasOwnProperty.call(PRODUTOS, cod)) return res.status(400).json({ error: 'dados' });

      const uso = db.prepare('SELECT device_code FROM payments WHERE txid = ?').get(txid);
      if (uso && uso.device_code !== d.code) return res.status(409).json({ error: 'em_uso' });

      const v = await validar(txid);
      if (v.erro === 'sem_chave') return res.status(503).json({ error: 'sem_chave' });
      if (v.erro) return res.status(502).json({ error: v.erro });
      const j = v.json || {};
      const ativoNaRoku = j.isEntitled === true || (j.isEntitled === undefined && String(j.purchaseStatus || '').toLowerCase() === 'active');
      if (!ativoNaRoku) return res.status(402).json({ error: 'sem_direito' });
      if (j.productCode && String(j.productCode) !== cod) return res.status(400).json({ error: 'produto' });

      const valor = Math.round(Number(j.total) * 100) || null;
      const r = ativar(d.code, PRODUTOS[cod], txid, valor, 'roku');
      if (!r.ok) return res.status(400).json({ error: 'ativar' });

      if (PRODUTOS[cod] !== 'vitalicio') {
        const fim = dataSeg(j.expirationDate);
        if (fim > agoraS()) db.prepare('UPDATE devices SET paid_until = ? WHERE id = ? AND paid_until < ?').run(fim, d.id, VITALICIO);
      }

      const dd = db.prepare('SELECT * FROM devices WHERE id = ?').get(d.id);
      res.json(resposta(dd, { token: assinar(dd.device_id, 60) }));
    } catch (e) {
      res.status(500).json({ error: 'interno' });
    }
  });
};
