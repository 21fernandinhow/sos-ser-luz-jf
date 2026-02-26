# SOS Ser Luz

Aplicação para o **Projeto Ser Luz** (ONG): recebimento de pedidos de ajuda em situações de emergência (enchentes, deslizamentos, pessoas isoladas) e painel para voluntários/coordenadores priorizarem e entrarem em contato.

- **Público:** qualquer pessoa pode enviar um pedido de ajuda (sem login). Os pedidos não aparecem em lista pública.
- **Área da ONG:** login por e-mail/senha; listagem de todos os pedidos e link para contato via WhatsApp.

## Stack

- Ruby 3.x, Rails 8 (monolith)
- PostgreSQL
- ERB + CSS puro (mobile-first, sem framework CSS)
- Autenticação: `has_secure_password` (bcrypt)

## Setup rápido

```bash
# Dependências
bundle install

# Banco de dados (PostgreSQL em execução)
bin/rails db:create db:migrate

# Usuário inicial da ONG (acesso ao painel)
bin/rails db:seed
```

## Rodar a aplicação

```bash
bin/rails server
```

Acesse: http://localhost:3000

- **Home:** mensagem de emergência e botão "Pedir Ajuda"
- **Pedir Ajuda:** formulário público (nome, telefone opcional, endereço, bairro, necessidade)
- **Entrar:** `/ngo/login` — login para a área da ONG
- **Painel:** `/ngo/help_requests` (após login) — lista de pedidos e botão "Contatar no WhatsApp"

## Rotas principais

| Rota | Descrição |
|------|-----------|
| `GET /` | Home (sem lista de pedidos) |
| `GET /help_requests/new` | Formulário "Pedir Ajuda" |
| `POST /help_requests` | Cria pedido de ajuda |
| `GET /ngo/login` | Tela de login ONG |
| `POST /ngo/session` | Login |
| `DELETE /ngo/session` | Logout |
| `GET /ngo/help_requests` | Painel (requer login) |

## Segurança

- Lista de pedidos **nunca** é exposta em ações públicas (home e criação).
- Área `/ngo/*` protegida por `before_action :require_ngo_login`.
- Senhas apenas como `password_digest` (bcrypt); sessão via `session[:user_id]`.

## Especificação

Ver [spec.md](./spec.md) para detalhes técnicos e critérios de aceite.
