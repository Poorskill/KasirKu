# KasirKu --- Application Flow

## 1. Overview

KasirKu adalah aplikasi POS (Point of Sale) dan Inventory Management
untuk UMKM Indonesia.

Platform target:

-   Flutter Web
-   Mobile
-   Tablet
-   Desktop
-   Deployment: Vercel untuk Flutter Web
-   Backend: Firebase

## 2. High-Level Flow

``` mermaid
flowchart TD
    A[Open KasirKu] --> B{Authenticated?}
    B -- No --> C[Login]
    C --> D{Login Valid?}
    D -- No --> C
    D -- Yes --> E[Dashboard]
    B -- Yes --> E

    E --> F[Kasir / POS]
    E --> G[Produk]
    E --> H[Transaksi]
    E --> I[Laporan]
    E --> J[Pengaturan]

    F --> K[Pilih Produk]
    K --> L[Keranjang]
    L --> M[Checkout]
    M --> N[Pilih Metode Pembayaran]
    N --> O[Konfirmasi Pembayaran]
    O --> P[Transaksi Berhasil]
    P --> Q[Cetak / Bagikan Struk]

    G --> R[Tambah Produk]
    G --> S[Edit Produk]
    G --> T[Hapus Produk]

    H --> U[Filter / Cari Transaksi]
    U --> V[Detail Transaksi]

    I --> W[Penjualan]
    I --> X[Produk Terlaris]
    I --> Y[Stok]

    J --> Z[Informasi Toko]
    J --> AA[Profil]
    J --> AB[Pengaturan Aplikasi]
```

## 3. Authentication Flow

``` mermaid
flowchart TD
    A[Login Screen] --> B[Input Email & Password]
    B --> C[Firebase Authentication]
    C --> D{Valid?}
    D -- No --> E[Show Error]
    E --> B
    D -- Yes --> F[Load User Profile]
    F --> G{Role}
    G --> H[Admin Dashboard]
    G --> I[Cashier Dashboard]
```

## 4. POS Flow

``` mermaid
flowchart LR
    A[Product Catalog] --> B[Search / Category]
    B --> C[Select Product]
    C --> D[Add to Cart]
    D --> E[Adjust Quantity]
    E --> F[Order Summary]
    F --> G[Checkout]
    G --> H[Payment Method]
    H --> I[Payment Amount]
    I --> J[Calculate Change]
    J --> K[Confirm]
    K --> L[Create Transaction]
    L --> M[Update Stock]
    M --> N[Success Receipt]
```

## 5. Product Management Flow

``` mermaid
flowchart TD
    A[Product List] --> B{Action}
    B --> C[Add Product]
    B --> D[Edit Product]
    B --> E[Delete Product]
    B --> F[Search / Filter]

    C --> G[Validate Form]
    D --> G
    G --> H[Save to Firestore]
    H --> I[Refresh Product List]

    E --> J[Confirmation Dialog]
    J --> K{Confirmed?}
    K -- Yes --> L[Delete Product]
    K -- No --> A
    L --> I
```

## 6. Transaction Flow

``` mermaid
flowchart TD
    A[Transaction History] --> B[Search / Filter]
    B --> C[Select Transaction]
    C --> D[Transaction Detail]
    D --> E{Action}
    E --> F[Print Receipt]
    E --> G[Share Receipt]
```

## 7. Responsive Navigation Flow

``` mermaid
flowchart TD
    A[Device Width] --> B{Width}
    B -- "< 640px" --> C[Mobile Layout]
    B -- "640px - 1024px" --> D[Tablet Layout]
    B -- "> 1024px" --> E[Desktop Layout]

    C --> F[Bottom Navigation]
    C --> G[Bottom Cart Sheet]

    D --> H[Adaptive Sidebar / Navigation]
    D --> I[Split POS Layout]

    E --> J[260px Sidebar]
    E --> K[12 Column Backoffice]
```

## 8. Main Navigation

-   Dashboard
-   Kasir
-   Produk
-   Transaksi
-   Laporan
-   Pengaturan
-   Logout

## 9. Definition of Done

Flow utama dianggap selesai jika user dapat:

1.  Login.
2.  Melihat dashboard.
3.  Membuat produk.
4.  Mengubah produk.
5.  Menghapus produk.
6.  Menambahkan produk ke cart.
7.  Checkout.
8.  Menyelesaikan pembayaran.
9.  Melihat transaksi.
10. Membuka detail transaksi.
11. Melihat laporan.
12. Menggunakan aplikasi dengan baik pada mobile, tablet, laptop, dan
    desktop.
