# UangBro — website_mode

This folder contains a minimal website-mode frontend (HTML/CSS/JS) and a small PHP backend that stores targets in a JSON file.

How to run locally (requires PHP):

```bash
# from the project root
php -S localhost:8000 -t website_mode

# then open http://localhost:8000/
```

This folder contains a small website-mode web app (HTML/CSS/JS) and a PHP backend that stores data in JSON files.

Features implemented:

- Login / Register (session-based)
- Add / Delete transactions (pemasukan / pengeluaran)
- Legacy (unclaimed) transactions supported and can be claimed after login via API

How to run locally (requires PHP):

```bash
# from the project root
php -S localhost:8000 -t website_mode

# then open http://localhost:8000/
```

Available API endpoints (under `website_mode/api`):

- `auth.php` —
  - GET (no action): return current logged-in user (or empty object)
  - POST?action=register (JSON { username, password })
  - POST?action=login (JSON { username, password })
  - POST?action=logout (no body)
  - POST?action=claim (JSON { ids: ["txid1", ...] }) — claim legacy transactions
- `transactions.php` — supports GET (list), POST (create), DELETE?id= (delete). Transactions are stored in `data/transactions.json`.

Data files:

- `data/users.json` — registered users (passwords hashed)
- `data/transactions.json` — stored transactions

Notes / security

- This is a small demo: use a real database and add proper validation and CSRF protection before production use.
