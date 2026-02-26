# Development Spec — SOS Ser Luz

**Based on:** [PRD.md](./PRD.md)  
**Purpose:** Technical specification for MVP implementation  
**Last updated:** 25/02/2025  

**Naming convention:** All code nomenclature in English (models, tables, columns, routes, controllers, methods, variables, params). User-facing copy (labels, buttons, messages) may remain in Portuguese for the target audience.

---

## Context

This project is built for **Projeto Ser Luz**, an NGO that responds to emergencies in cities affected by **floods, landslides, and people stranded** (e.g. isolated by water). The city is in a **state of calamity**; the NGO needs a single place to receive **help requests** from the population so it can prioritize and coordinate rescue and aid.

- **Who requests help:** Affected people or relatives on their behalf — they only submit a request (no login). They do **not** see other requests.
- **Who uses the panel:** NGO volunteers/coordinators — they log in, see all requests, and contact people (e.g. via WhatsApp) to organize assistance.
- **Goal:** Reduce the time between a request and the start of aid; keep requests private (visible only to the NGO, not on a public list).

The spec and UI should reflect this emergency context: clear calls to action, minimal friction to submit a request, and a panel focused on quick contact and prioritization.

---

## 1. Stack and environment

| Item | Choice |
|------|--------|
| Framework | Ruby on Rails (monolith) |
| Ruby | 3.x |
| Frontend | ERB + plain CSS (no Tailwind/Bootstrap) |
| Database | PostgreSQL (dev and prod from the start) |
| Authentication | `has_secure_password` (bcrypt) |
| Deploy | Render / Fly.io / VPS (TBD) |

**Initial commands (reference):**
```bash
rails new sos_ser_luz -d postgresql
```
Then configure `config/database.yml` for local PostgreSQL (e.g. user, password) and ensure the dev database exists (`rails db:create`).

---

## 2. Models and database

### 2.1 Model `HelpRequest` (table: `help_requests`)

| Column | Rails type | Null | Default | Notes |
|--------|------------|------|---------|--------|
| `name` | string | NOT NULL | — | Validation: presence |
| `phone` | string | yes | — | Optional; normalize to digits only for WhatsApp link |
| `address` | string | NOT NULL | — | Validation: presence |
| `neighborhood` | string | NOT NULL | — | Validation: presence |
| `need` | text | NOT NULL | — | Validation: presence (description of what they need) |
| `situation_type` | string | yes | — | Optional MVP: flooded, displaced, landslide, other |
| `urgent` | boolean | yes | false | Optional MVP |
| `status` | string | yes | 'pending' | Optional MVP: pending, in_progress, completed |
| `created_at` | datetime | — | — | Timestamps |
| `updated_at` | datetime | — | — | Timestamps |

**Required validations (MVP):**
- `name`, `address`, `neighborhood`, `need`: presence.

**Helper method (WhatsApp):**
- `phone_digits_only` (or `whatsapp_phone`): returns `phone` with digits only (to build `https://wa.me/55XXXXXXXXXXX`). If `phone` is blank, return `nil`; in the panel do not show the button or show it disabled.

**Example migration:**
```ruby
create_table :help_requests do |t|
  t.string :name, null: false
  t.string :phone
  t.string :address, null: false
  t.string :neighborhood, null: false
  t.text :need, null: false
  t.string :situation_type
  t.boolean :urgent, default: false
  t.string :status, default: 'pending'
  t.timestamps
end
```

### 2.2 Model `User` (table: `users`) — NGO user

| Column | Rails type | Null | Notes |
|--------|------------|------|--------|
| `email` | string | NOT NULL | Unique; used as login |
| `password_digest` | string | NOT NULL | has_secure_password |
| `created_at` | datetime | — | |
| `updated_at` | datetime | — | |

**Validations:**
- `email`: presence, uniqueness, valid format (optional).
- In model: `has_secure_password`.

**Example migration:**
```ruby
create_table :users do |t|
  t.string :email, null: false, index: { unique: true }
  t.string :password_digest, null: false
  t.timestamps
end
```

**Seed (MVP):** create one initial NGO user (email and password in seed or ENV).

---

## 3. Routes (config/routes.rb)

```ruby
# Public
root "home#index"
get  "help_requests/new", to: "help_requests#new", as: :new_help_request
post "help_requests",     to: "help_requests#create"

# NGO session
get    "ngo/login",   to: "sessions#new",    as: :ngo_login
post   "ngo/session", to: "sessions#create", as: :ngo_session
delete "ngo/session", to: "sessions#destroy", as: :ngo_logout

# NGO area (authenticated)
namespace :ngo do
  get "help_requests", to: "help_requests#index", as: :help_requests
end
```

---

## 4. Controllers

### 4.1 `ApplicationController`
- Method `current_user` (read from session) and `user_signed_in?` (or `logged_in?`) per project convention.
- `require_ngo_login` (or `authenticate_user`) used as `before_action` on routes under namespace `ngo`.

### 4.2 `HomeController` (action: `index`)
- Only renders the home view.
- **Do not** send list of help requests to the view. Page only with emergency message and CTA “Pedir Ajuda” + link “Área da ONG” / “Entrar”.

### 4.3 `HelpRequestsController` (public)
- **new:** show form (Name, Phone optional, Address, Neighborhood, What do you need?; optional: situation_type, urgent).
- **create:** 
  - Strong params: only `name`, `phone`, `address`, `neighborhood`, `need` (and optionally `situation_type`, `urgent`).
  - Validate and save; on success: redirect (e.g. to root or thank-you page) + flash confirmation; optionally include help request id in flash (e.g. “Pedido #123 registrado.”).
  - On error: re-render `new` with errors.

### 4.4 `SessionsController` (NGO)
- **new:** login form (email + password).
- **create:** authenticate with `User.find_by(email: params[:email]).authenticate(params[:password])`; on success set `session[:user_id]` and redirect to panel (`ngo_help_requests_path`); on failure flash error and re-render `new`.
- **destroy:** `session.delete(:user_id)` and redirect to home or login.

### 4.5 `Ngo::HelpRequestsController` (namespace ngo)
- **before_action:** require authentication (redirect to `ngo_login_path` if not authenticated).
- **index:** 
  - List all help requests (e.g. `HelpRequest.order(created_at: :desc)`; optional: `.limit(100)`).
  - Optional MVP: order by `urgent` first then by date; filters by neighborhood and status (P1).
  - View: table or cards with name, phone, address, neighborhood, need, date; “Contatar no WhatsApp” button per request (link `https://wa.me/55` + digits only). If no phone, hide button or show disabled with “Sem telefone”.

---

## 5. Views (suggested structure)

- **Layout:** `application.html.erb` with head, CSS (plain), body and yield; optional: nav with link “Pedir Ajuda” and “Entrar” (Área da ONG) when not logged in; when logged in: “Painel”, “Sair”.
- **Home:** `home/index.html.erb` — title “SOS Ser Luz” (or “Projeto Ser Luz – SOS”), context text, button/link “Pedir Ajuda” (`new_help_request_path`), link “Entrar” / “Área da ONG” (`ngo_login_path`). No list of help requests.
- **Help requests (public):** `help_requests/new.html.erb` — form with PRD fields; button “Enviar Pedido de Ajuda”. After submit, confirmation via redirect + flash (and optionally thank-you page).
- **Session:** `sessions/new.html.erb` — login form (email, password), button “Entrar”.
- **NGO panel:** `ngo/help_requests/index.html.erb` — list of help requests (name, phone, address, neighborhood, need, date); per row/card, link “Contatar no WhatsApp” (`https://wa.me/55#{help_request.phone_digits_only}`) if phone present.

**CSS:** one or more files in `app/assets/stylesheets/` (e.g. `application.css`), no framework; basic responsive layout (form and table/list readable on mobile).

---

## 6. Authentication and security

- Passwords: only `password_digest` in DB; use `has_secure_password` in `User` model.
- Session: use `session[:user_id]`; set after login, clear after logout.
- NGO route protection: in `Ngo::HelpRequestsController` (and any future namespace controllers), `before_action :require_ngo_login` (or equivalent) that redirects to `ngo_login_path` if `current_user` is nil.
- Do not expose list of help requests in any public action (home and help_requests#new/create do not load help requests for listing).

---

## 7. WhatsApp link

- Format: `https://wa.me/55XXXXXXXXXXX` (55 = Brazil, then area code + number, digits only).
- In `HelpRequest` model: method that returns phone with digits only (e.g. `phone.to_s.gsub(/\D/, '')`). If empty, return `nil`.
- In panel view: if `help_request.phone_digits_only.present?`, show link with `target="_blank"` and `rel="noopener"`; otherwise do not show button or show “Sem telefone” disabled.

---

## 8. Acceptance criteria (development checklist)

- [ ] Home shows only emergency message and CTA “Pedir Ajuda”; no list of help requests.
- [ ] “Pedir Ajuda” form has: Name *, Phone (optional), Address *, Neighborhood *, What do you need? *; submits via POST and persists to `help_requests`.
- [ ] After creating help request: user sees confirmation (flash or page); help request does not appear on any public page.
- [ ] Login screen at `/ngo/login`; POST to `/ngo/session`; logout via DELETE `/ngo/session`; session persisted by cookie.
- [ ] Without login, access to `/ngo/help_requests` redirects to login.
- [ ] After login, `/ngo/help_requests` lists all help requests (name, phone, address, neighborhood, need, date), ordered by date (newest first).
- [ ] Each help request with phone has “Contatar no WhatsApp” button/link that opens `wa.me/55` + digits only.
- [ ] Responsive layout and plain CSS; no CSS/JS framework dependency.

---

## 9. Optional in MVP (P1 / backlog)

- Form and model fields: `situation_type`, `urgent`; show in panel list and order by urgency when applicable.
- Panel filters: by neighborhood and by status (pending / in_progress / completed).
- Edit help request status in UI (backlog).
- Seed with one NGO user (email and password configurable).

---

## 10. Suggested delivery order

1. Create Rails app with PostgreSQL, configure `database.yml` and create DB (`rails db:create`), then create models `User` and `HelpRequest` with migrations and validations.
2. Public routes: home (no list of help requests), `help_requests/new` and `help_requests#create` with confirmation.
3. Authentication: User model with `has_secure_password`, SessionsController (login/logout), `current_user` and route protection.
4. NGO namespace: `Ngo::HelpRequestsController#index` with list and WhatsApp link per help request.
5. Plain CSS styling and responsive tweaks.
6. NGO user seed; document credentials for internal use.
7. (Optional) Fields situation_type, urgent, status and panel filters.

---

*Spec derived from [PRD.md](./PRD.md). Adjust per implementation decisions and feedback.*
