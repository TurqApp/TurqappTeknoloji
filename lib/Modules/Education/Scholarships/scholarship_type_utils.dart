import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_constants.dart';

bool isIndividualScholarshipType(String type) {
  const variants = {
    kIndividualScholarshipType,
    'individual',
    'individuell',
    'individuelle',
    'individuale',
    'индивидуальная',
  };
  return variants.contains(normalizeSearchText(type));
}
