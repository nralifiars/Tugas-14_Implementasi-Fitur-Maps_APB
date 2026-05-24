# Flutter Maps - Tugas 7: Implementasi Fitur Maps

| Informasi | Keterangan |
|---|---|
| Nama Lengkap | Nur Alifia Rustan |
| NIM | 1202230008 |
| Mata Kuliah | Aplikasi Perangkat Bergerak (APB) |

---

Flutter Maps adalah aplikasi Flutter yang dikembangkan untuk memenuhi Tugas 7 mata kuliah Aplikasi Perangkat Bergerak (APB). Aplikasi ini mengimplementasikan library `flutter_map` untuk menampilkan peta interaktif yang responsif. Aplikasi difokuskan untuk menampilkan rute/lokasi awal dari Telkom University Surabaya, dan dilengkapi dengan interaksi *Floating Action Button (FAB)* yang memungkinkan pengguna untuk berpindah secara dinamis ke lokasi tempat wisata populer di Surabaya, yaitu Jalan Tunjungan.

---

## Fitur Utama

| Fitur | Keterangan |
|---|---|
| **Peta Interaktif** | Peta interaktif mendukung interaksi penuh seperti *drag, pan, rotasi,* dan *pinch-to-zoom*. |
| **Beragam Mode Peta** | Menyediakan 3 lapis tampilan peta: Standar (OSM), Satelit (Esri World Imagery), dan Navigasi (CartoDB). |
| **Custom Marker** | Pin/Marker kustom berbentuk teardrop modern untuk menandakan titik lokasi yang aktif. |
| **FAB Pindah Lokasi** | Tombol pintar di kanan bawah layar untuk meloncat / berpindah instan antara Telkom University Surabaya dan Jalan Tunjungan. |
| **Kontrol Zoom & Arah** | Tombol kontrol manual (Zoom In `+`, Zoom Out `-`) serta reset kompas ke arah Utara. |
| **Animasi & UI Modern** | Tampilan *floating card* dengan efek animasi transisi dan tipografi modern menggunakan `Google Fonts (Poppins)`. |

---

## Alur Arsitektur

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#F8C8D4', 'primaryTextColor': '#5a2d3a', 'primaryBorderColor': '#E8A0B0', 'lineColor': '#D97090', 'secondaryColor': '#FDEEF3', 'tertiaryColor': '#FFF5F8', 'noteBkgColor': '#FDEEF3', 'noteTextColor': '#5a2d3a', 'activationBorderColor': '#D97090', 'activationBkgColor': '#FDEEF3', 'sequenceNumberColor': '#fff'}}}%%
sequenceDiagram
    participant Pengguna
    participant Aplikasi
    participant MapController
    participant TileProvider

    Pengguna->>Aplikasi: Membuka Aplikasi
    Aplikasi->>MapController: Inisialisasi Peta
    Aplikasi->>TileProvider: Request Map Tiles (OpenStreetMap)
    TileProvider-->>Aplikasi: Mengembalikan gambar tile peta
    Aplikasi-->>Pengguna: Menampilkan Peta (Fokus Telkom U Surabaya)

    alt Pindah Lokasi Tempat Wisata
        Pengguna->>Aplikasi: Tap FAB "Jalan Tunjungan"
        Aplikasi->>Aplikasi: setState (Ubah Info Card & Data Aktif)
        Aplikasi->>MapController: move(koordinatTunjungan, zoomLevel)
        MapController-->>Aplikasi: Peta bergeser
        Aplikasi-->>Pengguna: Peta fokus di Jalan Tunjungan dengan Marker Aktif
    end

    alt Ganti Mode Peta (Satelit/Navigasi)
        Pengguna->>Aplikasi: Tap ikon Layer di panel kanan
        Aplikasi->>Aplikasi: setState (Ubah ModePeta)
        Aplikasi->>TileProvider: Request Tiles sesuai Layer baru
        TileProvider-->>Aplikasi: Mengembalikan gambar tile baru
        Aplikasi-->>Pengguna: Tampilan lapisan peta (Tiles) berubah
    end
```

---

## Struktur Kelas

```text
HalamanPeta          - Halaman utama (StatefulWidget) berisi struktur Stack peta dan UI
_Lokasi              - Model data untuk menyimpan informasi lokasi, koordinat, dan label
_KartuPutih          - Widget reusable untuk background kontainer dengan shadow
_KartuInfo           - Widget melayang untuk menampilkan detail nama dan alamat lokasi
_TombolKontrol       - Kumpulan widget aksi map (Zoom In, Zoom Out, Reset Utara)
_FabPindah           - Widget Floating Action Button dinamis untuk beralih lokasi
_PinMarker           - CustomPainter untuk menggambar marker / pin lokasi di atas peta
```

---

## Bukti Hasil (Screenshot)
<img width="326" height="658" alt="Screenshot 2026-05-24 232445" src="https://github.com/user-attachments/assets/c8b9390e-b75f-445b-bad9-6c0f57302cb0" />
<img width="317" height="655" alt="Screenshot 2026-05-24 232456" src="https://github.com/user-attachments/assets/889c298e-f738-4f5f-9517-0deed07aca4f" />




