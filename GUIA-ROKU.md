# VLTV Play para Roku — guia rápido

## 1. Chaves (mesmas do app da LG)
No GitHub: Settings > Secrets and variables > Actions > New secret
- `TMDB_API_KEY` = sua chave do TMDB
- `VPS_APP_KEY`  = a chave `x-app-key` da VPS (créditos)
Sem as chaves o app abre normal, só fica sem títulos/sinopses do TMDB e sem o aprendizado de créditos.

## 2. Gerar o zip
Suba esta pasta num repositório (pode ser o mesmo do LG, em uma pasta própria) e rode a Action
"Gerar VLTV Play Roku". Baixe o artefato `VLTV-Roku-app.zip` (o `manifest` fica na raiz do zip).

## 3. Testar na sua Roku (modo desenvolvedor)
1. Controle da Roku: Home x3, Cima x2, Direita, Esquerda, Direita, Esquerda, Direita. Ative o Modo Desenvolvedor e crie a senha.
2. No navegador do celular (mesmo Wi‑Fi): `http://IP-DA-ROKU` (usuário `rokudev`).
3. Upload do `VLTV-Roku-app.zip` > Install. O canal abre sozinho.
4. Erros e mensagens de depuração: telnet no IP da Roku, porta 8085.

## 4. Publicar na Roku Channel Store
1. Conta em developer.roku.com. Gere a chave de assinatura UMA vez: telnet no IP da Roku porta 8085 > `genkey` (guarde senha e DevID).
2. Na página da Roku (`http://IP-DA-ROKU`) > Packager: nome do app + senha > "Package" > baixe o `.pkg`.
3. Developer Dashboard > Manage My Channels > Add Channel > Streaming Channel (non-certified, ou Direct Publisher não serve para este app).
4. Preencha: nome, descrição, categoria, classificação indicativa, política de privacidade (URL), suporte (leandro_gracas@yahoo.com.br), imagens (ícone 540x405 e 336x210 já estão em `images/`), envie o `.pkg`.
5. Roku exige: conta de teste ou código de teste para o revisor (o código de parceiro serve), privacidade, e que o app não compre/ative dentro do canal fora das regras deles. A tela de ativação mostra só código + site (sem preços), como no LG.
6. Se o canal for "não listado", o teste com amigos é por link de convite do Dashboard.

## O que NÃO foi testado
Não havia Roku aqui: o código passou no compilador (BrighterScript) e a lógica de pesquisa/títulos foi testada em emulador, mas as telas, o player (HLS/ts, áudio, legenda) e o foco do controle precisam da sua primeira rodada na TV. Mande o texto de qualquer erro que aparecer (telnet 8085) e eu corrijo.

## Regras iguais ao app da LG
- Código de parceiro (campo Servidor da aba Xtream, sem ponto/dois-pontos/barra): TV ativa sempre ("Ativo parceiro" na VPS).
- Outras listas: teste de 7 dias, depois ativação. Lista que não é de parceiro avisa a VPS e aparece vencida se não ativou.
- Pesquisa de Filmes/Séries: índice baixado uma vez e guardado; a cada abertura só baixa títulos novos (precisa do `gateway.js` novo na VPS).
