# KasirKu --- References

## 1. Primary Design Reference

Google Stitch project:

https://stitch.withgoogle.com/projects/9657030091374091798

The Stitch export used for this project contains:

-   Dashboard Ringkasan
-   Kasir / POS
-   Checkout Pembayaran
-   Kelola Produk
-   Tambah/Edit Produk
-   Riwayat Transaksi
-   Detail Struk
-   KasirKu Design System

## 2. Local Stitch Export

The project export is:

``` text
stitch_kasirku_pos_inventory_dashboard.zip
```

Important design-system reference:

``` text
kasirku_design_system/DESIGN.md
```

The design system defines the original:

-   Color tokens
-   Typography
-   Spacing
-   Responsive breakpoints
-   Elevation
-   Shape/radius
-   Components
-   POS interaction rules

## 3. Design System Baseline

Primary:

``` text
#2563EB
```

Background:

``` text
#F8FAFC
```

Surface:

``` text
#FFFFFF
```

Text:

``` text
#0F172A
```

Secondary:

``` text
#64748B
```

Success:

``` text
#16A34A
```

Warning:

``` text
#F59E0B
```

Danger:

``` text
#DC2626
```

Typography:

``` text
Plus Jakarta Sans
```

## 4. Responsive Baseline

Original Stitch design strategy:

``` text
Mobile  < 640px
Tablet  640px - 1024px
Desktop > 1024px
```

Desktop:

-   12-column system
-   Maximum content width 1440px
-   260px sidebar

Tablet:

-   Split POS
-   Product catalog
-   Dedicated cart

Mobile:

-   Single-column
-   2-column product grid
-   Bottom navigation
-   Floating cart / bottom sheet

## 5. Flutter References

Official Flutter documentation:

https://docs.flutter.dev/

Flutter responsive/adaptive design:

https://docs.flutter.dev/ui/adaptive-responsive

Flutter web:

https://docs.flutter.dev/platform-integration/web

## 6. Firebase References

Firebase:

https://firebase.google.com/

Firebase Authentication:

https://firebase.google.com/docs/auth

Cloud Firestore:

https://firebase.google.com/docs/firestore

Firebase Storage:

https://firebase.google.com/docs/storage

## 7. Vercel References

Vercel:

https://vercel.com/

Deployment should use the generated Flutter Web output:

``` text
build/web
```

The exact Vercel build configuration may depend on the selected
deployment workflow.

## 8. Suggested Flutter Packages

Core:

``` text
flutter_riverpod
go_router
firebase_core
firebase_auth
cloud_firestore
firebase_storage
```

UI / utility:

``` text
fl_chart
intl
cached_network_image
```

Packages should be added only when needed. Avoid adding dependencies
unnecessarily.

## 9. Reference Data

Use Indonesian business data in demos:

``` text
Kopi Susu Gula Aren
Mie Goreng Spesial
Es Teh Manis
Roti Bakar
Air Mineral
```

Currency:

``` text
Rp 15.000
Rp 25.000
Rp 1.250.000
```

## 10. Portfolio Reference

The final portfolio presentation should include:

1.  Project overview
2.  Problem solved
3.  Feature list
4.  Responsive screenshots
5.  Short demo video
6.  Tech stack
7.  Architecture
8.  Live demo
9.  GitHub repository
10. Lessons learned

## 11. Important Note

The Stitch design is the visual reference, not a requirement to copy
every pixel literally.

When implementing in Flutter:

-   Preserve visual identity.
-   Preserve information hierarchy.
-   Preserve core user flows.
-   Improve responsive behavior when needed.
-   Prefer reusable Flutter components over duplicated page-specific UI.
