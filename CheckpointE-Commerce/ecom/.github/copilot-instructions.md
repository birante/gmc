# aa - AI Coding Agent Instructions

## Project Overview

**aa** is a multi-tenant e-commerce platform built with Rails 8, PostgreSQL, Tailwind CSS, and ActiveAdmin. It supports three user types: **Clients** (customers), **Vendors** (shop owners), and **Employees** (shop staff), each with dedicated namespaced routes and controllers.

## Tech Stack

- **Ruby 3.4.7** (managed by Mise) + **Rails 8.0.3**
- **PostgreSQL 17** with Solid Cable/Cache/Queue for background jobs
- **Tailwind CSS v4** (via `tailwindcss-rails` + Propshaft)
- **ActiveAdmin** for admin panel (translated FR/EN)
- **Hotwire** (Turbo + Stimulus)
- **Analytics**: Ahoy Matey + Chartkick + Amplitude (optional)
- **Testing**: Minitest + FactoryBot + Capybara
- **Deployment**: Kamal (Docker-based) with `deploy.yml`

## Critical Architecture Patterns

### 1. Multi-User Authentication System

Three separate user types with polymorphic sessions:

```ruby
# Models: User, Vendor, Employee (all have has_secure_password)
# Polymorphic: sessions belongs_to :sessionable (User, Vendor, or Employee)
# Helper methods: current_user, current_vendor, current_employee
```

- **Clients** (`User` model): Shop on the platform, manage cart/orders/addresses
- **Vendors** (`Vendor` model): Own shops, manage products, view analytics
- **Employees** (`Employee` model): Assigned to shops via `employee_shops`, role-based (manager, cashier, stock_manager, delivery)

**Controllers**: Namespaced by user type (`client/`, `vendors/`, `employees/`). Base controllers inherit from `ApplicationController` which includes `Authentication` and `Trackable` concerns.

### 2. Shop-Centric Data Model

- **Shops** belong to vendors, have `FriendlyId` slugs, auto-generate `SHOPXXXXXX` codes
- **Items** (products) belong to shops, have categories/subcategories
- **Orders** are linked to shops via `order_items`, track per-shop delivery/payment
- **Employees** access shops via `employee_shops` join table (many-to-many)

**Key Pattern**: Always scope queries by shop context. Use `VendorShopContext` and `EmployeeShopContext` concerns in controllers.

### 3. Analytics System (Ahoy + Custom Tracking)

Auto-tracking enabled via `Trackable` concern in `ApplicationController`:

- **Automatic**: Page views tracked on all HTML requests (excludes AJAX/Turbo)
- **Manual**: Use `analytics.track_event(event_name, properties)` in controllers
- **Event Definitions**: Centralized in `Analytics::EventDefinitions` module (43+ page names)
- **Services**:
  - `Analytics::TrackingService`: Main tracking interface
  - `Analytics::VendorAnalyticsService`: Per-shop analytics for vendors
  - `Analytics::EmployeeAnalyticsService`: Per-shop analytics for employees

**Dashboard Routes**:

- Admin: `/admin/analytics` (platform-wide)
- Vendors: `/vendors/shops/:shop_id/analytics?tab=overview|products|orders|traffic`
- Employees: `/employees/shops/:shop_id/analytics` (same tabs)

**Gotcha**: Ahoy requires `current_visit` helper. Use `ahoy.track()` for low-level events, `analytics.track_event()` for business logic.

### 4. I18n Setup (FR/EN)

- **Default locale**: French (`config.i18n.default_locale = :fr`)
- **Supported**: `:fr`, `:en` with fallbacks enabled
- **Scope prefix**: `(:locale)` in routes (e.g., `/fr/vendors/login`, `/en/vendors/login`)
- **Translation files**: Organized in `config/locales/**/*.yml` (ActiveAdmin, Analytics, Kaminari pagination)

**Pattern**: Always use `I18n.t('key')` in views. Page names for analytics use `Analytics::EventDefinitions.page_name_for(controller, action)` which auto-translates.

### 5. Phone Validation Service

Custom `PhoneValidationService` uses `phonelib` gem for country-specific validation:

```ruby
# Usage in models (User, Vendor, Employee):
validate :phone_number_format
# Normalizes: normalizes :phone_number, with: ->(p) { p.to_s.strip.gsub(/\D/, "") }
```

**Fields**: `phone_number` (normalized digits) + `country_code` (e.g., `"221"` for Senegal)

### 6. Logging Conventions

Models use Rails logger with emoji prefixes for clarity:

- `👤 [User]` - User events
- `🏪 [Vendor]` - Vendor events
- `👷 [Employee]` - Employee events
- `🛒 [Cart]` - Cart actions
- `📦 [Order]` - Order lifecycle
- `📝 [Shop]` - Shop operations

**After callbacks**: `after_create :log_creation`, `after_update :log_update, if: :saved_changes?`

## Development Workflow

### Local Setup

```bash
./start_local.sh  # Starts Rails + Tailwind watch via Foreman
# OR manually:
rails server       # Port 3000
rails tailwindcss:watch
```

### Database Commands

```bash
rails db:create db:migrate db:seed  # Initial setup
rails db:reset                      # Drop, create, migrate, seed
```

### Code Quality

```bash
./bin/rubocop                       # Check style (omakase config)
./bin/rubocop --autocorrect         # Auto-fix
./bin/brakeman                      # Security scan
```

### Testing

```bash
rails test                          # Run all tests
rails test test/models/user_test.rb # Specific file
```

**Test setup**: Uses FactoryBot (`test/factories/`), fixtures (`test/fixtures/`), parallel execution enabled. OTP config reset per test. Locale set to `:en` for consistent error messages.

## Git Workflow (Gitmoji + Gitflow)

**Commit format**: `<gitmoji> <imperative description in French>`

Examples:

- `✨ Ajouter le modèle Currency`
- `🐛 Corriger la validation du code ISO`
- `♻️ Refactor le service de tracking`

**Branches**:

- `main` (production), `develop` (integration)
- `feature/<name>` from `develop`
- `hotfix/<name>` from `main`
- `release/<version>` from `develop`

See `.cursor/rules/gitmoji-gitflow.mdc` for details.

## Key Files & Directories

- **Routes**: `config/routes.rb` (namespaced by user type)
- **Models**: `app/models/{user,vendor,employee,shop,item,order}.rb`
- **Controllers**: `app/controllers/{client,vendors,employees}/` (base + specific)
- **Services**: `app/services/{analytics,checkout,vendors,employees}/`
- **Admin**: `app/admin/*.rb` (ActiveAdmin resources)
- **Concerns**: `app/controllers/concerns/{authentication,trackable,vendor_shop_context}.rb`
- **Analytics Docs**: `app/services/analytics/README.md` (1144 lines, comprehensive)

## Common Patterns

### Adding a New Feature

1. Create migration: `rails g migration AddFeatureToModel`
2. Update model: Add associations, validations, callbacks (with logging)
3. Update controller: Use base controller, include necessary concerns
4. Add routes: Namespace appropriately (`client`, `vendors`, `employees`)
5. Add views: Use Tailwind classes, Turbo Frames where applicable
6. Add tests: FactoryBot factories + Minitest
7. Commit: `✨ Ajouter <feature>`

### Adding Analytics Tracking

```ruby
# In controller action:
analytics.track_event('custom_event', {
  Analytics::Properties::SHOP_ID => @shop.id,
  custom_property: value
})
```

Define event constants in `Analytics::EventDefinitions` module.

### Scoping Queries by Shop

```ruby
# In vendors/employees controllers:
@shop = current_shop  # Provided by VendorShopContext/EmployeeShopContext
@items = @shop.items.where(...)
```

**Never** expose data across shops without explicit permission checks.

## Deployment

- **Staging**: `kamal deploy -d staging` (uses `config/deploy.staging.yml`)
- **Production**: `kamal deploy` (uses `config/deploy.yml`)

Docker-based deployment via Kamal. Environment variables configured in deploy files.

## Documentation

- `LOCAL_DEV.md` - Local development setup
- `ANALYTICS_SETUP.md` - Analytics dashboard guide
- `I18N_VERIFICATION.md` - I18n translation checklist
- `PAGINATION_SETUP.md` - Kaminari pagination setup
- `app/services/analytics/README.md` - Comprehensive analytics docs

## Gotchas & Conventions

- **Session handling**: Polymorphic `sessionable`, use `Current.session`
- **Friendly URLs**: Shops use `friendly_id` slugs, not numeric IDs
- **Active Admin**: Translated via `config/locales/active_admin.{fr,en}.yml`
- **Ahoy visits**: Auto-tracked, use `ahoy.current_visit_id` for events
- **Test locale**: Always `:en` in tests for predictable error messages
- **Tailwind config**: Dual configs (`tailwind.config.js` + `tailwind-active_admin.config.js`)
- **Background jobs**: Use Solid Queue (`solid_queue.yml`) for async processing

## When Making Changes

1. Check existing patterns in similar features (e.g., other controllers in same namespace)
2. Update I18n files for any user-facing text
3. Add logging to models (use emoji prefix conventions)
4. Use concerns for shared functionality (don't repeat auth/tracking logic)
5. Test with all three user types if feature spans namespaces
6. Update relevant `.md` docs if changing architecture
