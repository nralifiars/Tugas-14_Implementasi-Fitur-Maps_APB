import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

const _merah   = Color(0xFFE05252);
const _merahBg = Color(0xFFFFEBEB);
const _abu600  = Color(0xFF757575);
const _abu900  = Color(0xFF212121);

enum ModePeta { standar, satelit, navigasi }

extension ModePetaExt on ModePeta {
  String get label {
    switch (this) {
      case ModePeta.standar:  return 'Standar';
      case ModePeta.satelit:  return 'Satelit';
      case ModePeta.navigasi: return 'Navigasi';
    }
  }

  IconData get icon {
    switch (this) {
      case ModePeta.standar:  return Icons.map_outlined;
      case ModePeta.satelit:  return Icons.satellite_alt_outlined;
      case ModePeta.navigasi: return Icons.navigation_outlined;
    }
  }

  String get tileUrl {
    switch (this) {
      case ModePeta.standar:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case ModePeta.satelit:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case ModePeta.navigasi:
        return 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
    }
  }

  bool get isDark     => this == ModePeta.satelit;
  bool get isNavigasi => this == ModePeta.navigasi;
  double get rotasi   => this == ModePeta.navigasi ? 30.0 : 0.0;
}

class _Lokasi {
  final String id;
  final String nama;
  final String kategori;
  final String alamat;
  final LatLng latlng;
  final double zoom;
  const _Lokasi({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.alamat,
    required this.latlng,
    required this.zoom,
  });
}

const _telkom = _Lokasi(
  id: 'telkom',
  nama: 'Telkom University Surabaya',
  kategori: 'Universitas · Surabaya',
  alamat: 'Jl. Ketintang No.156, Ketintang, Kec. Gayungan, Surabaya, Jawa Timur 60231',
  latlng: LatLng(-7.3112662, 112.7288845),
  zoom: 18.0,
);

const _tunjungan = _Lokasi(
  id: 'tunjungan',
  nama: 'Jalan Tunjungan',
  kategori: 'Wisata Kota · Surabaya',
  alamat: 'Jl. Tunjungan, Embong Kaliasin, Kec. Genteng, Kota Surabaya, Jawa Timur',
  latlng: LatLng(-7.2577, 112.7382),
  zoom: 18.0,
);

class HalamanPeta extends StatefulWidget {
  const HalamanPeta({super.key});

  @override
  State<HalamanPeta> createState() => _HalamanPetaState();
}

class _HalamanPetaState extends State<HalamanPeta>
    with SingleTickerProviderStateMixin {
  final MapController _ctrl = MapController();

  _Lokasi  _aktif        = _telkom;
  bool     _tampilWisata = false;
  ModePeta _mode         = ModePeta.standar;
  bool     _mapReady     = false;

  late final AnimationController _cardAnim;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim  = CurvedAnimation(parent: _cardAnim, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 700),
        () { if (mounted) _cardAnim.forward(); });
  }

  @override
  void dispose() {
    _cardAnim.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _pindahLokasi(_Lokasi lok) {
    setState(() {
      _aktif = lok;
      if (lok.id == 'tunjungan') _tampilWisata = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapReady) {
        _ctrl.move(lok.latlng, lok.zoom);
      }
    });

    _cardAnim.reset();
    Future.delayed(const Duration(milliseconds: 60),
        () { if (mounted) _cardAnim.forward(); });
  }

  void _gantiMode(ModePeta mode) {
    setState(() => _mode = mode);
    if (_mapReady) {
      _ctrl.rotate(mode.rotasi);
    }
  }

  void _zoomIn() {
    if (!_mapReady) return;
    final z = _ctrl.camera.zoom;
    _ctrl.move(_ctrl.camera.center, (z + 1).clamp(5.0, 19.0));
  }

  void _zoomOut() {
    if (!_mapReady) return;
    final z = _ctrl.camera.zoom;
    _ctrl.move(_ctrl.camera.center, (z - 1).clamp(5.0, 19.0));
  }

  void _resetNorth() {
    if (_mapReady) _ctrl.rotate(0.0);
  }

  @override
  Widget build(BuildContext context) {
    final bool diWisata  = _aktif.id == 'tunjungan';
    final bool isDark    = _mode.isDark;
    final bool isNavMode = _mode.isNavigasi;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: _ctrl,
            options: MapOptions(
              initialCenter: _telkom.latlng,
              initialZoom: _telkom.zoom,
              minZoom: 5,
              maxZoom: 19,
              onMapReady: () => setState(() => _mapReady = true),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                key: ValueKey(_mode),
                urlTemplate: _mode.tileUrl,
                userAgentPackageName: 'com.tugas7.flutter_maps',
                keepBuffer: 5,
                maxNativeZoom: 19,
              ),
              if (_mode == ModePeta.satelit)
                RichAttributionWidget(attributions: [
                  TextSourceAttribution('Esri World Imagery'),
                ]),
              MarkerLayer(
                markers: [
                  _buatMarker(_telkom,    aktif: _aktif.id == 'telkom'),
                  if (_tampilWisata)
                    _buatMarker(_tunjungan, aktif: _aktif.id == 'tunjungan'),
                ],
              ),
            ],
          ),
          if (isNavMode)
            Positioned(
              bottom: 0, left: 0, right: 0, height: 220,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  children: [
                    _KartuPutih(
                      isDark: isDark,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 11),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_city_rounded,
                                color: _merah, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Tel-U Surabaya Maps',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : _abu900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _KartuPutih(
                        isDark: isDark,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: _merah, size: 15),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _aktif.nama,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : _abu900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _KartuPutih(
                isDark: isDark,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ModePeta.values.map((m) {
                      final aktif = _mode == m;
                      return GestureDetector(
                        onTap: () => _gantiMode(m),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                m.icon,
                                color: aktif
                                    ? _merah
                                    : (isDark
                                        ? Colors.white54
                                        : Colors.black38),
                                size: 20,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                m.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: aktif
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: aktif
                                      ? _merah
                                      : (isDark
                                          ? Colors.white54
                                          : Colors.black38),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 160,
            child: Column(
              children: [
                _TombolKontrol(
                  icon: Icons.add,
                  isDark: isDark,
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 2),
                _TombolKontrol(
                  icon: Icons.remove,
                  isDark: isDark,
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 8),
                _TombolKontrol(
                  icon: Icons.explore_outlined,
                  isDark: isDark,
                  onTap: _resetNorth,
                  tooltip: 'Reset utara',
                ),
              ],
            ),
          ),
          Positioned(
            left: 12, right: 60, bottom: 86,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _KartuInfo(lokasi: _aktif, isDark: isDark),
              ),
            ),
          ),
          Positioned(
            right: 12, bottom: 16,
            child: _FabPindah(
              diWisata: diWisata,
              onTap: () =>
                  _pindahLokasi(diWisata ? _telkom : _tunjungan),
            ),
          ),
          if (isNavMode)
            Positioned(
              bottom: 86,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _merah,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.navigation_rounded,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Mode Navigasi',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Marker _buatMarker(_Lokasi lok, {required bool aktif}) {
    return Marker(
      point: lok.latlng,
      width: aktif ? 44 : 36,
      height: aktif ? 58 : 48,
      alignment: Alignment.topCenter,
      child: _PinMarker(aktif: aktif),
    );
  }
}

class _KartuPutih extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _KartuPutih({required this.child, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E2E).withValues(alpha: 0.92)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TombolKontrol extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final String? tooltip;
  const _TombolKontrol({
    required this.icon,
    required this.onTap,
    this.isDark = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final Widget btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E2E).withValues(alpha: 0.92)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20,
            color: isDark ? Colors.white70 : _abu900),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

class _KartuInfo extends StatelessWidget {
  final _Lokasi lokasi;
  final bool isDark;
  const _KartuInfo({required this.lokasi, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final Color bgColor   = isDark
        ? const Color(0xFF1E1E2E).withValues(alpha: 0.95)
        : Colors.white;
    final Color textColor = isDark ? Colors.white : _abu900;
    final Color subColor  = isDark ? Colors.white60 : _abu600;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _merahBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: _merah, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lokasi.nama,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    )),
                const SizedBox(height: 2),
                Text(lokasi.kategori,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _merah,
                    )),
                const SizedBox(height: 5),
                Text(lokasi.alamat,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: subColor,
                      height: 1.5,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FabPindah extends StatelessWidget {
  final bool diWisata;
  final VoidCallback onTap;
  const _FabPindah({required this.diWisata, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _merah,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _merah.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              diWisata ? Icons.school_outlined : Icons.place_outlined,
              color: Colors.white,
              size: 17,
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                diWisata ? 'Telkom U Surabaya' : 'Jalan Tunjungan',
                key: ValueKey(diWisata),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinMarker extends StatelessWidget {
  final bool aktif;
  const _PinMarker({required this.aktif});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PinPainter(aktif: aktif));
}

class _PinPainter extends CustomPainter {
  final bool aktif;
  const _PinPainter({required this.aktif});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final r  = w / 2;

    final fill = Paint()
      ..color = aktif ? _merah : const Color(0xFFEF9A9A)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = aktif ? 2.5 : 2.0;

    final path = ui.Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, r), radius: r))
      ..moveTo(cx - r * 0.55, h * 0.58)
      ..quadraticBezierTo(cx - r * 0.9, h * 0.82, cx, h)
      ..quadraticBezierTo(cx + r * 0.9, h * 0.82, cx + r * 0.55, h * 0.58)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawCircle(Offset(cx, r), r, stroke);
    canvas.drawCircle(
      Offset(cx, r),
      aktif ? r * 0.32 : r * 0.26,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) => old.aktif != aktif;
}
