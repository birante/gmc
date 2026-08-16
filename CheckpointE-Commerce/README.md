# Checkpoint E-Commerce — Yoonema

## Submission

- **Live app:** [https://yoonema.com/](https://yoonema.com/)
- **Code:** [`./ecom/`](./ecom) (Rails 8, Ruby 3.4, PostgreSQL 17)

## What was built

Yoonema is a **multi-tenant e-commerce platform** in production, serving three
distinct spaces:

- **Client** — end-users who browse the catalogue, put items in a cart, check
  out and pay online.
- **Vendor** — sellers who manage their shop, catalogue, orders, and payouts.
- **Employee / Admin** — internal staff running the platform, with an
  [ActiveAdmin](https://activeadmin.info/) dashboard (FR/EN).

### Features covered (mapping to a typical e-commerce checkpoint)

| Feature                          | Where in the code                                          |
| -------------------------------- | ---------------------------------------------------------- |
| Product catalogue                | `app/models/{item,category,attribute_value}*`, `app/controllers/{items,categories,shops}_controller.rb` |
| Search                           | `app/controllers/search_controller.rb`                     |
| Cart                             | `app/models/{cart,cart_item}.rb`, `app/controllers/client/{carts,cart_items}_controller.rb` |
| Checkout                         | `app/services/checkout/`, `app/controllers/client/orders_controller.rb` |
| Payment (PayDunya integration)   | `app/services/payment_services/paydunya_http_service.rb`, `app/controllers/paydunya_callbacks_controller.rb` |
| Address book                     | `app/models/address.rb`, `app/controllers/client/addresses_controller.rb` |
| Auth (client + vendor + admin)   | `app/controllers/{passwords,users}_controller.rb`, `app/controllers/client/{registrations,accounts,passwords}_controller.rb` |
| Vendor space                     | `app/controllers/vendors/`                                 |
| Employee space + admin panel     | `app/controllers/{admin,employees}/` + ActiveAdmin         |
| Delivery zones / prices          | `app/models/delivery_*`                                    |
| Blog / content pages             | `app/controllers/{blog_posts,pages}_controller.rb`, `app/models/blog_*` |
| Homepage builder                 | `app/models/home_page_section*.rb` (configurable sections) |
| Newsletter                       | `app/controllers/newsletter_subscribers_controller.rb`     |
| Contact + reviews                | `app/models/{contact_message,review}.rb`                   |
| Analytics                        | Ahoy + Chartkick — see `docs/analytics/`                   |
| Notifications (SMS / WhatsApp)   | `app/services/{sms,whatsapp,notifications}/`               |

## Stack

- **Rails 8.0** / **Ruby 3.4.7**
- **PostgreSQL 17** + Solid Cable / Cache / Queue (Rails 8 defaults)
- **Tailwind CSS v4** (`tailwindcss-rails` + Propshaft)
- **Hotwire** (Turbo + Stimulus)
- **ActiveAdmin** — FR/EN admin dashboard
- **PayDunya** — payment integration (mobile-money + card)
- **Ahoy + Chartkick** — analytics
- **Kamal** — containerised deployment (Docker + `config/deploy.yml`)

## Local run

```bash
cd ecom
./start_local.sh              # foreman: rails server + tailwind watch
# or explicitly:
bundle exec rails db:create db:migrate db:seed
bundle exec rails server      # :3000
bundle exec rails tailwindcss:watch
```

Test suite + quality checks:

```bash
bundle exec rails test        # Minitest
bundle exec rubocop           # style
bundle exec brakeman          # security
```

Full README with deployment notes: [`ecom/README.md`](./ecom/README.md).

## Documentation

The `ecom/docs/` directory carries the day-to-day project documentation
— architecture rules, PayDunya integration, deployment guides,
performance work, refactoring notes, load-testing results. The main
entry points:

| File                                    | What's in it                                                 |
| --------------------------------------- | ------------------------------------------------------------ |
| [`ecom/docs/DOCUMENTATION.md`](./ecom/docs/DOCUMENTATION.md) | Consolidated documentation index               |
| [`ecom/docs/DEPLOYMENT_GUIDE.md`](./ecom/docs/DEPLOYMENT_GUIDE.md) | Production + preprod deployment (Kamal + Docker) |
| [`ecom/docs/PERFORMANCE_OPTIMIZATION.md`](./ecom/docs/PERFORMANCE_OPTIMIZATION.md) | Caching, Ahoy, recommendations perf work |
| [`ecom/docs/LOAD_TEST_1000_USERS.md`](./ecom/docs/LOAD_TEST_1000_USERS.md) | Load-testing methodology + results             |
| [`ecom/docs/rules/`](./ecom/docs/rules)     | Architecture and design-system conventions               |

## Checkpoint requirements — checklist

- [x] **Code pushed to a public repository** — this repo (`gmc`) hosts
      the whole submission at
      `CheckpointE-Commerce/`.
- [x] **Link to the deployed app** — **[https://yoonema.com/](https://yoonema.com/)**.
