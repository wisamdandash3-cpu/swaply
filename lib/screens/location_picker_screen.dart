import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';

/// نتيجة اختيار الموقع: العنوان النصي والإحداثيات (إن وُجدت).
typedef LocationPickerResult = ({String address, double? lat, double? lng});

/// شاشة لتحديد أو تحديث الموقع: خريطة، زر "موقعي"، وحقل العنوان.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialAddress,
  });

  final String? initialAddress;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();
  LatLng? _locationLatLng;
  bool _locationLoading = false;
  bool _locationRequested = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialAddress ?? '';
    _requestLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    if (_locationRequested || !mounted) return;
    _locationRequested = true;
    setState(() => _locationLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        _locationRequested = false;
        setState(() => _locationLoading = false);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          _locationRequested = false;
          setState(() => _locationLoading = false);
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      _locationLatLng = latLng;
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      _mapController.move(latLng, 15);
      final placemarks = await geo.placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final area = [p.locality, p.administrativeArea, p.subAdministrativeArea]
            .where((e) => e != null && e.isNotEmpty)
            .join(', ');
        if (area.isNotEmpty) {
          _addressController.text = area;
        } else if (p.country != null && p.country!.isNotEmpty) {
          _addressController.text = p.country!;
        }
      }
    } catch (_) {
      // ignore
    }
    if (mounted) {
      _locationRequested = false;
      setState(() => _locationLoading = false);
    }
  }

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) return;
    try {
      final locations = await geo.locationFromAddress(query);
      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);
        setState(() => _locationLatLng = latLng);
        _mapController.move(latLng, 15);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).comingSoon),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final center = _locationLatLng ?? const LatLng(52.52, 13.405);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlack,
        elevation: 0,
        title: Text(
          l10n.myNeighbourhood,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.darkBlack,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop<LocationPickerResult>((
              address: _addressController.text.trim(),
              lat: _locationLatLng?.latitude,
              lng: _locationLatLng?.longitude,
            )),
            child: Text(l10n.postConfirm, style: const TextStyle(color: AppColors.hingePurple, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.postLiveHint,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkBlack.withValues(alpha: 0.75),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: _locationLatLng != null ? 15 : 12,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                      onMapReady: () {
                        if (!_locationRequested) _requestLocation();
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.swaply.swaply',
                      ),
                      if (_locationLatLng != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _locationLatLng!,
                              width: 36,
                              height: 36,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.blue,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white,
                      elevation: 2,
                      borderRadius: BorderRadius.circular(24),
                      child: IconButton(
                        icon: _locationLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                        onPressed: _locationLoading ? null : () async {
                          _locationRequested = false;
                          await _requestLocation();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: l10n.postEnterAddressPlaceholder,
              border: const UnderlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searchAddress,
              ),
            ),
            onSubmitted: (_) => _searchAddress(),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.postZoomIntoArea,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.darkBlack.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
