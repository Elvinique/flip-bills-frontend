part of 'vas_bloc.dart';

abstract class VasEvent extends Equatable {
  const VasEvent();
  @override
  List<Object?> get props => [];
}

class VasLoadCatalog extends VasEvent {}

class VasBuyAirtime extends VasEvent {
  final String phone;
  final int amountKobo;
  final String network;
  const VasBuyAirtime({
    required this.phone,
    required this.amountKobo,
    required this.network,
  });
  @override
  List<Object?> get props => [phone, amountKobo, network];
}

class VasBuyData extends VasEvent {
  final String phone;
  final String network;
  final String planCode;
  const VasBuyData({
    required this.phone,
    required this.network,
    required this.planCode,
  });
  @override
  List<Object?> get props => [phone, network, planCode];
}

class VasPayElectricity extends VasEvent {
  final String meterNumber;
  final String disco;
  final int amountKobo;
  final String meterType;
  const VasPayElectricity({
    required this.meterNumber,
    required this.disco,
    required this.amountKobo,
    this.meterType = 'prepaid',
  });
  @override
  List<Object?> get props => [meterNumber, disco, amountKobo, meterType];
}

class VasFundBetting extends VasEvent {
  final String customerId;
  final String provider;
  final int amountKobo;
  const VasFundBetting({
    required this.customerId,
    required this.provider,
    required this.amountKobo,
  });
  @override
  List<Object?> get props => [customerId, provider, amountKobo];
}

class VasPurchaseTvCable extends VasEvent {
  final String smartCardNumber;
  final String provider;
  final String planCode;
  const VasPurchaseTvCable({
    required this.smartCardNumber,
    required this.provider,
    required this.planCode,
  });
  @override
  List<Object?> get props => [smartCardNumber, provider, planCode];
}

class VasReset extends VasEvent {}

