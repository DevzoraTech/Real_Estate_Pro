import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_request.dart';
import '../repositories/service_repository.dart';

class GetServiceRequestsParams {
  final String? customerId;
  final String? providerId;
  final ServiceRequestStatus? status;
  final int page;
  final int limit;

  const GetServiceRequestsParams({
    this.customerId,
    this.providerId,
    this.status,
    this.page = 1,
    this.limit = 20,
  });
}

class GetServiceRequestsUseCase {
  final ServiceRepository repository;

  GetServiceRequestsUseCase(this.repository);

  Future<Either<Failure, List<ServiceRequest>>> call(
    GetServiceRequestsParams params,
  ) async {
    return await repository.getServiceRequests(
      customerId: params.customerId,
      providerId: params.providerId,
      status: params.status,
      page: params.page,
      limit: params.limit,
    );
  }
}

class CreateServiceRequestUseCase {
  final ServiceRepository repository;

  CreateServiceRequestUseCase(this.repository);

  Future<Either<Failure, ServiceRequest>> call(ServiceRequest request) async {
    return await repository.createServiceRequest(request);
  }
}

class UpdateServiceRequestUseCase {
  final ServiceRepository repository;

  UpdateServiceRequestUseCase(this.repository);

  Future<Either<Failure, ServiceRequest>> call(ServiceRequest request) async {
    return await repository.updateServiceRequest(request);
  }
}

class GetServiceRequestByIdUseCase {
  final ServiceRepository repository;

  GetServiceRequestByIdUseCase(this.repository);

  Future<Either<Failure, ServiceRequest>> call(String id) async {
    return await repository.getServiceRequestById(id);
  }
}
