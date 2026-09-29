# KasirKu --- Project README

## 1. Tentang Project

**KasirKu** adalah aplikasi POS dan Inventory Management yang dirancang
sebagai project portfolio Flutter sekaligus prototype produk yang dapat
dikustomisasi untuk client UMKM.

Target bisnis:

-   Toko retail
-   Cafe
-   Warung
-   Kedai makanan
-   Laundry
-   Toko oleh-oleh
-   Bisnis jasa sederhana

## 2. Tujuan Project

Project ini dibuat untuk menunjukkan kemampuan:

-   Flutter development
-   Responsive UI
-   State management
-   Firebase Authentication
-   Cloud Firestore
-   Firebase Storage
-   CRUD
-   POS transaction flow
-   Inventory management
-   Data visualization
-   Form validation
-   Deployment Flutter Web
-   Production-oriented UI architecture

## 3. Platform

KasirKu harus dapat berjalan pada:

  Platform   Target
  ---------- -----------------------------
  Mobile     Android / Web Mobile
  Tablet     Android / iPad / Web Tablet
  Laptop     Web
  Desktop    Web

Flutter Web akan dideploy menggunakan Vercel.

## 4. Tech Stack

### Frontend

-   Flutter
-   Dart
-   Material 3
-   Responsive/adaptive layout

### State Management

Rekomendasi awal:

-   Riverpod

### Backend

-   Firebase Authentication
-   Cloud Firestore
-   Firebase Storage

### Charts

-   fl_chart

### Deployment

-   GitHub
-   Vercel

## 5. Project Structure

``` text
lib/
├── core/
│   ├── constants/
│   ├── router/
│   ├── theme/
│   ├── utils/
│   └── widgets/
│
├── models/
│   ├── product.dart
│   ├── category.dart
│   ├── transaction.dart
│   ├── transaction_item.dart
│   └── user_profile.dart
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── pos/
│   ├── products/
│   ├── transactions/
│   ├── reports/
│   └── settings/
│
└── main.dart
```

## 6. Firebase Collections

``` text
users/{userId}
products/{productId}
categories/{categoryId}
transactions/{transactionId}
settings/{storeId}
```

### Product

``` text
products/{productId}
├── name
├── sku
├── categoryId
├── price
├── costPrice
├── stock
├── minimumStock
├── imageUrl
├── description
├── createdAt
└── updatedAt
```

### Transaction

``` text
transactions/{transactionId}
├── cashierId
├── items[]
├── subtotal
├── discount
├── tax
├── total
├── paymentMethod
├── paymentAmount
├── change
├── createdAt
└── status
```

## 7. Main Screens

1.  Login
2.  Dashboard
3.  Kasir / POS
4.  Checkout
5.  Produk
6.  Tambah Produk
7.  Edit Produk
8.  Riwayat Transaksi
9.  Detail Transaksi
10. Laporan
11. Pengaturan

## 8. Responsive Requirement

Responsive adalah requirement utama, bukan fitur tambahan.

Breakpoint:

``` text
Mobile  : < 640px
Tablet  : 640px - 1024px
Desktop : > 1024px
```

### Mobile

-   Single column
-   Bottom navigation
-   Cart menggunakan bottom sheet/floating cart
-   Product catalog 2 kolom
-   Form single column

### Tablet

-   Split layout
-   Catalog + cart
-   Sidebar dapat dipadatkan
-   Table dapat horizontal scroll

### Desktop

-   Sidebar 260px
-   12-column content layout
-   Max content width 1440px
-   Dashboard analytics
-   Table full width

## 9. Coding Principles

-   Hindari hard-coded screen width.
-   Hindari fixed height yang dapat menyebabkan overflow.
-   Gunakan `LayoutBuilder` untuk perubahan layout.
-   Gunakan `Expanded` / `Flexible` dengan benar.
-   Gunakan `MediaQuery` hanya ketika dibutuhkan.
-   Buat reusable components.
-   Pisahkan UI, state, model, dan data access.
-   Semua interactive touch target minimal 48x48px.
-   Gunakan loading, empty, error, dan success states.

## 10. MVP Priority

### P0 --- Wajib

-   Login
-   Dashboard
-   Product CRUD
-   Cart
-   Checkout
-   Transaction history
-   Responsive UI

### P1 --- Setelah MVP

-   Reports
-   Receipt
-   Product image
-   Role admin/cashier

### P2 --- Future

-   QRIS integration
-   Bluetooth printer
-   Multi-store
-   Multi-tenant
-   Advanced permissions
-   Online backup/export
-   Real payment gateway

## 11. Deployment

Build:

``` bash
flutter build web --release
```

Output:

``` text
build/web
```

Repository GitHub kemudian dapat dihubungkan ke Vercel untuk deployment
Flutter Web.

## 12. Portfolio Goal

Project harus terlihat seperti produk komersial, bukan demo tutorial.

Portfolio harus menampilkan:

-   Live demo
-   Screenshot responsive
-   Video demo singkat
-   GitHub repository
-   Feature list
-   Tech stack
-   Case study singkat
