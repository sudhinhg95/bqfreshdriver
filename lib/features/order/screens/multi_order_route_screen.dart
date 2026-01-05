import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'dart:math';

class MultiOrderRouteScreen extends StatefulWidget {
  const MultiOrderRouteScreen({super.key});

  @override
  State<MultiOrderRouteScreen> createState() => _MultiOrderRouteScreenState();
}

class _MultiOrderRouteScreenState extends State<MultiOrderRouteScreen> {
  bool _fallbackToFlutterMap = false;
  Timer? _mapInitTimer;
    void _launchMultiStopRoute() {
      if (orders.isEmpty) return;
      // Example driver location (should be replaced with live location if available)
      final driverLat = 26.2285;
      final driverLng = 50.5860;
      // Collect all customer locations
      final customerLocations = orders.map((order) {
        final lat = double.tryParse(order.deliveryAddress?.latitude ?? '') ?? 0.0;
        final lng = double.tryParse(order.deliveryAddress?.longitude ?? '') ?? 0.0;
        return {'lat': lat, 'lng': lng};
      }).toList();
      if (customerLocations.isEmpty) return;
      final origin = '${driverLat},${driverLng}';
      final destination = '${customerLocations.last['lat']},${customerLocations.last['lng']}';
      final waypoints = customerLocations.length > 1
          ? customerLocations.sublist(0, customerLocations.length - 1)
              .map((loc) => '${loc['lat']},${loc['lng']}').join('|')
          : '';
      final url = 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination'
          + (waypoints.isNotEmpty ? '&waypoints=$waypoints' : '')
          + '&travelmode=driving';
      _launchUrl(url);
    }
  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Marker> _mobileMarkers = {};
  Set<gmaps.Polyline> _mobilePolylines = {};
  List<fm.Marker> _webMarkers = [];
  List<fm.Marker> _mobileOsmMarkers = [];
  List<latlng.LatLng> _webPolylinePoints = [];
  List orders = [];

  @override
  void initState() {
    super.initState();
    _prepareRoute();
    // Temporarily force OSM (FlutterMap) on mobile to avoid black screen
    if (!kIsWeb) {
      _fallbackToFlutterMap = true;
    }
  }

  void _prepareRoute() async {
    orders = Get.find<OrderController>().currentOrderList ?? [];
    // Prepare locations for both platforms
    List<latlng.LatLng> customerLocationsWeb = [];
    List<gmaps.LatLng> customerLocationsMobile = [];
    for (var order in orders) {
      final lat = double.tryParse(order.deliveryAddress?.latitude ?? '') ?? 0.0;
      final lng = double.tryParse(order.deliveryAddress?.longitude ?? '') ?? 0.0;
      customerLocationsWeb.add(latlng.LatLng(lat, lng));
      customerLocationsMobile.add(gmaps.LatLng(lat, lng));
    }
    // Example driver location
    latlng.LatLng driverLocationWeb = latlng.LatLng(26.2285, 50.5860);
    gmaps.LatLng driverLocationMobile = gmaps.LatLng(26.2285, 50.5860);
    // Sort by distance from driver (web)
    customerLocationsWeb.sort((a, b) => _distance(driverLocationWeb, a).compareTo(_distance(driverLocationWeb, b)));
    customerLocationsMobile.sort((a, b) => _distanceMobile(driverLocationMobile, a).compareTo(_distanceMobile(driverLocationMobile, b)));
    // Web markers with order number and redirect button
    _webMarkers = [
      fm.Marker(
        point: driverLocationWeb,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
      ),
      ...customerLocationsWeb.asMap().entries.map((entry) {
        int idx = entry.key;
        var order = orders[idx];
        String orderNo = order.id?.toString() ?? (idx + 1).toString();
        return fm.Marker(
          point: entry.value,
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.location_pin, color: Colors.red, size: 40),
              Positioned(
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Text(orderNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ),
            ],
          ),
        );
      }),
    ];
    _webPolylinePoints = [driverLocationWeb, ...customerLocationsWeb];
    // Mobile OSM markers (compact to avoid overflow)
    _mobileOsmMarkers = [
      fm.Marker(
        point: driverLocationWeb,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
      ),
      ...customerLocationsWeb.asMap().entries.map((entry) {
        int idx = entry.key;
        var order = orders[idx];
        String orderNo = order.id?.toString() ?? (idx + 1).toString();
        return fm.Marker(
          point: entry.value,
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.location_pin, color: Colors.red, size: 40),
              Positioned(
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Text(orderNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ),
            ],
          ),
        );
      }),
    ];
    // Mobile markers with order number and redirect button
    _mobileMarkers = {
      gmaps.Marker(
        markerId: const gmaps.MarkerId('driver'),
        position: driverLocationMobile,
        infoWindow: const gmaps.InfoWindow(title: 'Driver'),
      ),
      ...customerLocationsMobile.asMap().entries.map((entry) {
        int idx = entry.key;
        var order = orders[idx];
        String orderNo = order.id?.toString() ?? (idx + 1).toString();
        return gmaps.Marker(
          markerId: gmaps.MarkerId('customer_$idx'),
          position: entry.value,
          infoWindow: gmaps.InfoWindow(
            title: 'Order #$orderNo',
            snippet: 'Route',
            onTap: () {
              final lat = entry.value.latitude;
              final lng = entry.value.longitude;
              final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
              _launchUrl(url);
            },
          ),
        );
      }),
    };
    _mobilePolylines = {
      gmaps.Polyline(
        polylineId: const gmaps.PolylineId('route'),
        points: [driverLocationMobile, ...customerLocationsMobile],
        color: Colors.blue,
        width: 5,
      ),
    };
    setState(() {});
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch map')),
      );
    }
  }

  double _distance(latlng.LatLng a, latlng.LatLng b) {
    const double R = 6371e3;
    double phi1 = a.latitude * pi / 180;
    double phi2 = b.latitude * pi / 180;
    double dPhi = (b.latitude - a.latitude) * pi / 180;
    double dLambda = (b.longitude - a.longitude) * pi / 180;
    double aa = (sin(dPhi/2) * sin(dPhi/2)) + cos(phi1) * cos(phi2) * (sin(dLambda/2) * sin(dLambda/2));
    double c = 2 * atan2(sqrt(aa), sqrt(1-aa));
    return R * c;
  }
  double _distanceMobile(gmaps.LatLng a, gmaps.LatLng b) {
    const double R = 6371e3;
    double phi1 = a.latitude * pi / 180;
    double phi2 = b.latitude * pi / 180;
    double dPhi = (b.latitude - a.latitude) * pi / 180;
    double dLambda = (b.longitude - a.longitude) * pi / 180;
    double aa = (sin(dPhi/2) * sin(dPhi/2)) + cos(phi1) * cos(phi2) * (sin(dLambda/2) * sin(dLambda/2));
    double c = 2 * atan2(sqrt(aa), sqrt(1-aa));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    bool hasValidLocations = kIsWeb ? _webMarkers.isNotEmpty : _mobileMarkers.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Multi-Order Route')),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: hasValidLocations
            ? (kIsWeb
                ? SizedBox.expand(
                    child: fm.FlutterMap(
                      options: fm.MapOptions(
                        center: _webPolylinePoints.isNotEmpty ? _webPolylinePoints.first : latlng.LatLng(26.2285, 50.5860),
                        zoom: 12,
                      ),
                      children: [
                        fm.TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                        ),
                        fm.MarkerLayer(markers: _webMarkers),
                        fm.PolylineLayer(
                          polylines: [fm.Polyline(points: _webPolylinePoints, color: Colors.blue, strokeWidth: 5)],
                        ),
                      ],
                    ),
                  )
                : SizedBox.expand(
                    child: fm.FlutterMap(
                      options: fm.MapOptions(
                        center: _webPolylinePoints.isNotEmpty ? _webPolylinePoints.first : latlng.LatLng(26.2285, 50.5860),
                        zoom: 12,
                      ),
                      children: [
                        fm.TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                        ),
                        fm.MarkerLayer(markers: _mobileOsmMarkers),
                        fm.PolylineLayer(
                          polylines: [fm.Polyline(points: _webPolylinePoints, color: Colors.blue, strokeWidth: 5)],
                        ),
                      ],
                    ),
                  ))
            : const Center(child: Text('No valid customer locations to show on map.')),
      ),
      floatingActionButton: hasValidLocations
          ? FloatingActionButton.extended(
              onPressed: _launchMultiStopRoute,
              icon: Icon(Icons.alt_route),
              label: Text('Route All'),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _mapInitTimer?.cancel();
    super.dispose();
  }
}
