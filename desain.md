# KasirKu --- Design Specification

## 1. Design Direction

**Modern Utilitarian SaaS**

Karakter:

-   Clean
-   Professional
-   Reliable
-   Fast
-   Minimal visual noise
-   High readability
-   Touch-friendly

KasirKu harus terlihat seperti software bisnis yang benar-benar
digunakan setiap hari.

## 2. Design Principle

### 1. Usability First

Kasir harus dapat melakukan transaksi dengan sedikit langkah.

### 2. Responsive by Default

Setiap screen wajib bekerja pada:

-   320px+
-   375px
-   390px
-   414px
-   640px
-   768px
-   1024px
-   1280px
-   1440px+
-   Ultrawide

### 3. Consistency

Gunakan token design system yang sama di seluruh aplikasi.

### 4. Accessibility

-   Kontras jelas.
-   Font mudah dibaca.
-   Touch target minimum 48x48px.
-   Jangan hanya menggunakan warna untuk menyampaikan status.

## 3. Color Tokens

``` text
Primary             #2563EB
Background          #F8FAFC
Surface             #FFFFFF
Text Primary        #0F172A
Text Secondary      #64748B
Border              #E2E8F0
Success             #16A34A
Warning             #F59E0B
Danger              #DC2626
```

## 4. Typography

Font utama:

**Plus Jakarta Sans**

  Token               Size   Weight   Line Height
  ----------------- ------ -------- -------------
  Display             32px      700          40px
  Headline Large      24px      700          32px
  Headline Medium     20px      600          28px
  Headline Small      18px      600          24px
  Body Large          16px      500          24px
  Body Medium         14px      400          20px
  Body Small          12px      400          16px
  Label Large         14px      600          20px
  Label Medium        12px      600          16px

Currency:

-   Gunakan `Rp`
-   Ribuan menggunakan titik
-   Contoh: `Rp 18.000`
-   Tidak menggunakan desimal

## 5. Spacing

Gunakan grid 8px.

``` text
4px   = micro spacing
8px   = xs
16px  = sm / default
24px  = md
32px  = lg
48px  = xl
64px  = section spacing
```

## 6. Radius

``` text
8px   = input / button
12px  = small cards
16px  = product cards / invoice cards
24px  = bottom sheets / large modal
9999px = badges / chips
```

## 7. Responsive Layout

### Mobile --- \< 640px

``` text
Single Column
Padding: 16px
Product Grid: 2 columns
Navigation: Bottom Navigation
Cart: Floating Bar + Bottom Sheet
Tables: Card/List or horizontal scroll
Forms: 1 column
```

### Tablet --- 640px--1024px

``` text
Padding: 24px
POS: Catalog + Cart split
Navigation: Compact sidebar / adaptive navigation
Cards: 2–3 columns
Tables: Responsive scroll
```

### Desktop --- \> 1024px

``` text
Sidebar: 260px
Content: 12 columns
Max Width: 1440px
Margin: 32px
Dashboard: Multi-column
POS: Catalog + Cart
```

## 8. Navigation

### Desktop

``` text
KasirKu
├── Dashboard
├── Kasir
├── Produk
├── Transaksi
├── Laporan
└── Pengaturan
```

Sidebar fixed width: 260px.

### Mobile

Bottom navigation:

``` text
Dashboard | Kasir | Produk | Transaksi | Lainnya
```

## 9. Dashboard

Components:

-   Greeting
-   KPI cards
-   Sales chart
-   Low stock
-   Recent transactions
-   Top products

KPI:

``` text
Penjualan Hari Ini
Rp 4.250.000

Transaksi
128

Total Produk
245

Stok Menipis
8
```

## 10. POS

Desktop/tablet:

``` text
Product Catalog | Cart
```

Mobile:

``` text
Product Catalog
       ↓
Floating Cart
       ↓
Bottom Sheet
```

Product card:

-   Image
-   Name
-   Price
-   Stock status
-   Quick add

## 11. Status

### Tersedia

``` text
Background: #DCFCE7
Text: #16A34A
```

### Menipis

``` text
Background: #FEF3C7
Text: #D97706
```

### Habis

``` text
Background: #FEE2E2
Text: #DC2626
```

## 12. Buttons

Primary:

``` text
Background: #2563EB
Text: #FFFFFF
Height: 48px
Radius: 8px
```

Secondary:

``` text
Background: #F1F5F9
Text: #0F172A
Border: #E2E8F0
```

Danger:

``` text
Background: #FEE2E2
Text: #DC2626
```

## 13. Tables

Desktop:

-   Full table
-   Sticky header when appropriate
-   Pagination
-   Search
-   Filter

Mobile:

-   Convert rows into cards where practical.
-   Otherwise allow controlled horizontal scrolling.
-   Never force the entire desktop table into a tiny viewport.

## 14. Forms

Desktop:

-   2-column form when fields are independent.
-   Full-width fields for description/upload.

Mobile:

-   Single column.

Validation:

-   Inline error
-   Clear error text
-   Preserve entered data

## 15. States

Every data-driven screen harus memiliki:

-   Loading
-   Empty
-   Error
-   Success
-   Disabled
-   Skeleton/loading state where useful

## 16. Important UI Rules

-   Do not use excessive gradients.
-   Do not use glassmorphism as the primary visual language.
-   Do not use tiny text for financial data.
-   Do not create controls below 48x48px touch area.
-   Do not rely on color alone for status.
-   Do not hard-code desktop dimensions into mobile layouts.
-   Do not allow charts or tables to overflow the viewport.
-   Do not hide essential POS actions on mobile.

## 17. Design Reference

The initial visual direction comes from the Google Stitch KasirKu design
export. The Flutter implementation should preserve the brand identity
while adapting each screen to its available viewport.
