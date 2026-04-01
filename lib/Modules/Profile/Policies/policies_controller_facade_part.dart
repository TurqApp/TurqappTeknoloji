part of 'policies_controller.dart';

PoliciesController ensurePoliciesController({
  String? tag,
  bool permanent = false,
}) =>
    _ensurePoliciesController(tag: tag, permanent: permanent);

PoliciesController? maybeFindPoliciesController({String? tag}) =>
    _maybeFindPoliciesController(tag: tag);
