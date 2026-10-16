/* Stub para web/desktop — sem UDP nativo; os fluxos mostram aviso. */
class GreeLanDevice {
  final String cid;
  final String name;
  final String ver;
  final String model;
  final String address;
  GreeLanDevice({required this.cid, required this.address, this.name = '', this.ver = '', this.model = ''});
}

class GreeLan {
  static bool get supported => false;

  Future<List<GreeLanDevice>> scan({Duration timeout = const Duration(seconds: 5)}) async => const [];
  Future<String?> bind(GreeLanDevice dev, {Duration timeout = const Duration(seconds: 5)}) async => null;
  Future<Map<String, dynamic>?> status(GreeLanDevice dev, String key) async => null;
  Future<bool> ping(GreeLanDevice dev, String key) async => false;
  Future<bool> command(GreeLanDevice dev, String key, List<String> opt, List<dynamic> p) async => false;
}
