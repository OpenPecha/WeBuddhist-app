import 'dart:io';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// POST /users/upload — uploads a local [File] as avatar and returns the hosted URL.
class UploadAvatarUseCase extends UseCase<String, File> {
  final AuthRepository _repository;

  UploadAvatarUseCase(this._repository);

  @override
  Future<Either<Failure, String>> call(File file) {
    return _repository.uploadAvatar(file);
  }
}
