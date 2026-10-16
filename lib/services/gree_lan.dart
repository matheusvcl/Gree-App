/* Camada LAN do Gree (UDP 7000). Na web usa o stub — sem rede local. */
export 'gree_lan_stub.dart' if (dart.library.io) 'gree_lan_io.dart';
