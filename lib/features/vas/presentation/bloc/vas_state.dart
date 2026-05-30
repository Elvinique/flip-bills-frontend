part of 'vas_bloc.dart';

abstract class VasState extends Equatable {
  const VasState();
  @override
  List<Object?> get props => [];
}

class VasInitial extends VasState {}

class VasCatalogLoading extends VasState {}

class VasCatalogLoaded extends VasState {
  final List<Map<String, dynamic>> airtimeNetworks;
  final List<Map<String, dynamic>> dataPlans;
  final List<Map<String, dynamic>> electricityDiscos;
  final List<Map<String, dynamic>> bettingProviders;

  const VasCatalogLoaded({
    required this.airtimeNetworks,
    required this.dataPlans,
    required this.electricityDiscos,
    required this.bettingProviders,
  });

  @override
  List<Object?> get props =>
      [airtimeNetworks, dataPlans, electricityDiscos, bettingProviders];
}

class VasProcessing extends VasState {}

class VasSuccess extends VasState {
  final String message;
  final String? reference;
  final String? token; // electricity token if applicable

  const VasSuccess({
    required this.message,
    this.reference,
    this.token,
  });

  @override
  List<Object?> get props => [message, reference, token];
}

class VasFailure extends VasState {
  final String message;
  const VasFailure({required this.message});
  @override
  List<Object?> get props => [message];
}
