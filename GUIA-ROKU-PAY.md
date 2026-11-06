# Roku Pay no VLTV Play — passo a passo

## 1. No Roku Developer Dashboard
1. Crie o canal (Streaming Store, país Brasil) e ative **Monetization > "in-channel subscriptions (SVOD)"** e **"one-time purchases"**.
2. Crie 2 produtos (Product Catalog), com estes códigos exatos (ou mude em `config.json`):
   - `vltv_anual`  → Annual subscription (preço em USD; a Roku converte para R$ no Brasil)
   - `vltv_vitalicio` → One-time purchase
3. Entre no **Partner Payouts Program** (necessário para receber).
4. Em **Web API Settings** copie a "Roku API Key" → vai só na VPS (`ROKU_API_KEY`).
5. Ative **billing testing** no canal de teste e cadastre sua conta Roku em **Test Users**.

## 2. Na VPS
- Use `vps-roku/roku-pay.js` (rota `POST /roku/comprar`) e adapte as 3 funções ao seu banco.
- Recomendado: bloquear a ativação por site para aparelhos `uid-roku...` (senão contorna a Roku).
- Job diário para renovar/expirar a assinatura anual (comentário no fim do arquivo).

## 3. No app (já alterado neste projeto)
- `Ativacao.brs`: sem site/link; botões Anual / Vitalícia / Restaurar via ChannelStore.
- `Licenca.brs` + `AuthTask.brs`: `licRokuComprar` envia o transactionId para a VPS.
- Versão 1.3.9.

## 4. Teste
Sideload → deixe o teste vencer (ou force `expired` na VPS) → compre com a conta Test User → a TV deve voltar ativa.
