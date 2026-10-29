# 360 Phone Shop — Mobile App Analysis

Analysis of the three project resources (`360-backend`, `frontend`,
`360-Mobile-App-Sample-Screens.docx`) that drove the Flutter app in this folder.
Dates are absolute; the document was produced on 13 October 2026.

## 1. What the system is

An inventory, POS and sales system for a phone shop with an English/Khmer web UI.

| Layer | Technology | Notes |
|---|---|---|
| Backend | Java 21, Spring Boot 3.4.2, Spring Security + JWT, JPA/Flyway on PostgreSQL 17, Redis, S3-compatible RustFS, springdoc | REST under `/api/v1`, port 8081 (3333 in docker-compose, nginx in front) |
| Web frontend | React 19, TypeScript, Vite, Tailwind 4 + shadcn/ui, TanStack Query/Form/Table, Redux Toolkit, Recharts | Vercel rewrites `/api/v1/*` to `http://169.58.63.127:3333/api/v1/*` |
| Design doc | 10 sample phone screens with the endpoints each one uses | Dated 6 October 2026 |

### Backend conventions the app depends on

- Envelope: `{ success, status, message, payload, Instant }` (capital `I`). `payload` is absent on deletes. Dashboard summary and profit-loss return raw DTOs.
- Paging (catalog, stock, sales, purchases, customers): `page` is 1-based, `size` default 10, **no sort**. Report endpoints use Spring `Pageable` (0-based `page`, `sort=prop,dir`).
- Security: `anyRequest().permitAll()` plus `@PreAuthorize("hasAuthority('x:y')")` on controllers. A missing/expired token or missing permission answers **403**, never 401. The app therefore refreshes on 401 *and* on 403 when the local JWT `exp` has passed, and proactively refreshes 30 s before expiry.
- Refresh tokens are opaque strings that rotate on every `POST /auth/refresh`; the app stores the rotated token.
- Errors: validation `400 {field: message}`, duplicate `409 {timestamp,message,status}`, not found `404 {status,message}`, everything else Spring's default `500` body. All are mapped to one `ApiException`.
- Status lifecycle `ACT` / `DEL` / `INT` on master data; sale status `COMPLETED | PENDING | CANCELLED | RETURNED | PARTIALLY_RETURNED`; payment status `PENDING | PARTIAL | PAID`; serial status `AVAILABLE | SOLD | OUT_OF_STOCK | CANCELLED`.

## 2. Scope delivered (as narrowed by the project owner)

| Page | Backend endpoints | Permission |
|---|---|---|
| Sign in | `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout` | – |
| POS terminal (search, category chips, camera scan, product grid, cart bar) | `GET /product`, `GET /category`, `GET /stores`, `GET /product-serial?productId=`, `GET /reports/product-serials?barcode=` (scan fallback) | `product:read`, `category:read`, `store:read`, `stock:read` |
| Cart (customer, quantity, serial assignment, discount) | `GET /customer`, `POST /customer` | `customer:read`, `customer:create` |
| Payment (cash/bank, paying amount, quick cash, change/due) | `GET /bank`, `POST /sales` | `bank:read`, `sale:create` |
| Camera scanner (product barcode and serial) | – | camera permission |
| Products (list, detail sheet with serial rows) | `GET /product`, `GET /product-serial?productId=` | `product:read`, `stock:read` |
| Purchases (list, filters, detail sheet) | `GET /purchases`, `GET /purchases/{id}` | `purchase:read` |
| Suppliers (list, create, edit, delete) | `GET/POST/PUT/DELETE /suppliers` | `supplier:*` |

Dropped from the design document on request: dashboard, sales list/detail/return, stock tab, reports, held orders, receipt page, "More" menu, register/forgot/change password, profile.

## 3. Branding carried over

| Element | Value | Source |
|---|---|---|
| Primary navy | `#052949` | `--sidebar` in `frontend/src/index.css` |
| Accent orange | `#F46D34` | active menu marker in `App.css`, brand mark |
| Status green / amber / red | `#148550` / `#A3660C` / `#BB3A42` | stock pills in `App.css` |
| Chart blue | `#17678E` | web sales chart |
| Fonts | Noto Sans + Noto Sans Khmer (bundled TTF) | `--font-sans` in `index.css` |
| Logo | `frontend/public/logo.png` | bundled as `assets/images/logo.png` |
| Strings | `frontend/src/i18n/locales/{en,km}.ts` copied verbatim, plus `mobile.*` keys | language stored under `app_language` like the web |

## 4. Inconsistencies and gaps found (and how the app handles them)

### Backend vs. web frontend

1. **Double payment recording.** The web POS posts `/sales` with `paidAmount` and then posts `/payments` again. The backend already creates a `Payment` row inside `SaleServiceImpl.create` when `paidAmount > 0`, and `PaymentServiceImpl.create` recomputes `paidAmount` as the sum of all payments, so the web records the tender twice. The app posts the sale **once** and skips `/payments`.
2. **`/sales/{id}/complete` is unreachable.** Sales are created as `COMPLETED`; the endpoint requires `PENDING` and throws 500 otherwise. The web still calls it after payment. The app does not.
3. **Walk-in customer.** `SaleRequest.customerId` is annotated optional but the service calls `findById(null)` and fails with 500. The web picks the customer whose name contains "walk". The app does the same and creates `WALK-IN / Walk-In Customer` on first use if none exists.
4. **Product search.** `GET /product?name=` is an exact, case-sensitive match. The web loads 1,000 products and filters locally; the app loads all pages (100 per page) and filters locally.
5. **Serial lookup by barcode.** `GET /product-serial?barcode=` throws server-side (`barCode` vs `barcode` attribute). The app loads serials by `productId` and matches locally; for scanning it falls back to `GET /reports/product-serials?barcode=` which works but needs `report:read`.
6. **Stock rows name the model, not the product.** `StockMapper` fills `productId`/`productName` from `product.models`. The app uses `ProductResponse.qty` (sum across stores) for stock badges instead of joining stock rows.
7. **Image preview needs a bearer token.** `/files/preview-file/{name}?bucketName=` is guarded by `file:read`, and the `fileUrl` returned on upload points at a non-existent `/api/v2`. The app fetches image bytes through the authenticated client and rebuilds the URL from the stored file name.
8. **PUT nulls `status`.** MapStruct update mappers for Customer/Supplier/Bank/Currency/Expense set `status = null` when omitted, after which the row vanishes from lists and `findById` NPEs. The supplier form always resends `status`.
9. **List filters that crash (500):** purchases `supplierId`/`storeId`, expenses `storeId`/`bankId`/`expenseTypeId`, model `categoryId`/`brandId`, variant-value `variantTypeId`, currency `code` without `name`. The app never sends these and filters client-side.
10. **Stock `status` filter is a no-op** (the spec strips `_` before comparing to `OUT_STOCK`). Client-side classification is used.
11. **Dashboard figures.** `DashboardSummaryResponse` has only four month KPIs; the web `types/dashboard` expects "today" figures that the backend does not return, and `activeCustomers.changePercentage` is hard-coded `10.3`. (Dashboard was dropped from scope.)
12. **`currency:*` permissions are not seeded**, so `/currency` answers 403 for every default role.
13. **Register stores `username = firstName + " " + lastName`** regardless of the username typed.
14. **Password-reset token lives 1 minute** (`plusMinutes(1)` bug) and the reset link points at `localhost:5173`.
15. **Cancel does not restore stock**; only `/return` does. Delete restores stock but only sets `deletedBy` (sale still listed).

### Design document vs. implementation

- Screen 6 lists `POST /payments` and `PATCH /sales/{id}/complete` for payment; per findings 1–2 the app uses `POST /sales` only.
- Screen 8 relies on `/stock/low-stock`, which is commented out in the backend.
- Screen 2 suggests calling `/dashboard/summary` instead of the web's four 1,000-row list calls; correct, but out of the narrowed scope.
- The document recommends HTTPS; the API is plain HTTP at an IP. The app enables cleartext traffic for development (`android:usesCleartextTraffic`, `NSAllowsArbitraryLoads`) and lets the user change the server URL from the sign-in screen. A production build should point `--dart-define=API_BASE_URL` at an HTTPS domain and remove those exceptions.
- Held orders live in the browser's `localStorage` (`pos_held_sales`) on the web; there is no backend endpoint. Dropped from the mobile scope.

## 5. Seeded accounts (DatabaseSeeder)

| Username | Email | Role | Password |
|---|---|---|---|
| younam | namyou854@gmail.com | ROLE_SUPER_ADMIN | admin@123 |
| sovansreyneat | admin@gmail.com | ROLE_ADMIN | admin@123 |
| kheavanna | user@gmail.com | ROLE_USER (read-all + sale/quote/payment/customer create) | admin@123 |

No store, bank, customer, supplier or product is seeded. `PaymentServiceImpl` falls back to bank id 1 and `StockServiceImpl` to store id 1, so create those first.
