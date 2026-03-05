# Pocusapp 2.0

Bem-vindo ao repositório unificado do Pocusapp 2.0! Esta é a base estrutural que sustenta nossa aplicação, separando responsabilidades de forma clara entre aplicativos, funções no servidor e definições de banco de dados.

## 🛠️ Stack Oficial

Nossa arquitetura moderna é composta pelas seguintes tecnologias e serviços:

*   **Aplicativo Mobile:** Flutter + PowerSync + Supabase
*   **Painel Administrativo:** Next.js
*   **Backend / Serverless:** Supabase Edge Functions
*   **Gateway de Pagamentos:** Mercado Pago
*   **Internacionalização (i18n):** PT-BR e ES

## 📂 Estrutura do Monorepo

O repositório adota um formato de *monorepo* organizado da seguinte maneira:

```text
Pocusapp/
  apps/
    mobile/
    admin/
  supabase/
    migrations/
    functions/
    seed/
  docs/
    ARCHITECTURE.md
    CONVENTIONS.md
    SECURITY.md
    i18n.md
```

## ⚖️ Regras Rápidas

Para garantirmos estabilidade e segurança inegociáveis, siga estes princípios ao desenvolver para o Pocusapp:

1.  **Segredos Protegidos:** NUNCA exponha tokens, chaves secretas empresariais ou chaves de API restritas do lado do cliente (`apps/`). Tudo deve ficar nas variáveis de ambiente seguras ou ser injetado/utilizado pelas funções no backend.
2.  **Operações Sensiveis no Servidor:** Pagamentos, checagem de direitos e fluxos de assinaturas (*entitlement*) devem obrigátoriamente ocorrer exclusivamente através de Edge Functions.
3.  **Desenvolvimento Offline-First:** Toda interação comum da UI lerá diretamente de bancos de dados locais antes de buscar dados novos online.

*Para uma visão holística e mais granular sobre segurança, convenções e decisões técnicas, por favor visite a pasta `/docs` neste repositório.*

## 🚀 Próximas Etapas

Aqui está o roadmap de altíssimo nível do que esperamos implementar a curto prazo, utilizando o alicerce deste projeto:

- [ ] Criar e configurar o projeto de desenvolvimento do Supabase local e remoto.
- [ ] Escrever as migrações (arquitetura DB) e estipular as políticas de RLS.
- [ ] Criar as Edge Functions integradas ao Mercado Pago.
- [ ] Construir o setup/scaffold do Next.js para o Admin.
- [ ] Construir o setup/scaffold base do Flutter para o Mobile.