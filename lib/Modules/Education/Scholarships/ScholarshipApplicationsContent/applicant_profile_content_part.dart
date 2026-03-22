part of 'applicant_profile.dart';

extension ApplicantProfileContentPart on _ApplicantProfileState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: controller.fullName.value),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value ||
                    controller.isDetailsLoading.value) {
                  return const Center(child: CupertinoActivityIndicator());
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(controller),
                        24.ph,
                        _buildSectionTitle(
                          'scholarship.applicant.personal_section'.tr,
                        ),
                        _buildInfoCard([
                          _buildText(
                            'scholarship.applicant.full_name'.tr,
                            controller.fullName.value,
                          ),
                          _buildClickableText(
                            'scholarship.applicant.email'.tr,
                            controller.email.value,
                            isEmail: true,
                          ),
                          _buildClickableText(
                            'scholarship.applicant.phone'.tr,
                            '+90${controller.phoneNumber.value}',
                            isPhone: true,
                          ),
                          _buildText(
                            'scholarship.applicant.country'.tr,
                            controller.ulke.value,
                          ),
                          _buildText(
                            'scholarship.applicant.registry_city'.tr,
                            controller.nufusSehir.value,
                          ),
                          _buildText(
                            'scholarship.applicant.registry_district'.tr,
                            controller.nufusIlce.value,
                          ),
                          _buildText(
                            'scholarship.applicant.birth_date'.tr,
                            controller.dogumTarigi.value,
                          ),
                          _buildText(
                            'scholarship.applicant.marital_status'.tr,
                            controller.medeniHal.value,
                          ),
                          _buildText(
                            'scholarship.applicant.gender'.tr,
                            controller.cinsiyet.value,
                          ),
                          _buildText(
                            'scholarship.applicant.disability_report'.tr,
                            controller.engelliRaporu.value,
                          ),
                          _buildText(
                            'scholarship.applicant.employment_status'.tr,
                            controller.calismaDurumu.value,
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                          'scholarship.applicant.education_section'.tr,
                        ),
                        _buildInfoCard([
                          _buildText(
                            'scholarship.applicant.education_level'.tr,
                            controller.educationLevel.value,
                          ),
                          _buildText(
                            'scholarship.applicant.university'.tr,
                            controller.universite.value,
                          ),
                          _buildText(
                            'scholarship.applicant.faculty'.tr,
                            controller.fakulte.value,
                          ),
                          _buildText(
                            'scholarship.applicant.department'.tr,
                            controller.bolum.value,
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                          'scholarship.applicant.family_section'.tr,
                        ),
                        _buildInfoCard([
                          _buildText(
                            'scholarship.applicant.father_alive'.tr,
                            controller.babaHayata.value,
                          ),
                          if (!_isNoValue(controller.babaHayata.value)) ...[
                            _buildText(
                              'scholarship.applicant.father_name'.tr,
                              controller.babaAdi.value,
                            ),
                            _buildText(
                              'scholarship.applicant.father_surname'.tr,
                              controller.babaSoyadi.value,
                            ),
                            _buildClickableText(
                              'scholarship.applicant.father_phone'.tr,
                              '+90${controller.babaPhone.value}',
                              isPhone: true,
                            ),
                            _buildText(
                              'scholarship.applicant.father_job'.tr,
                              controller.babaJob.value,
                            ),
                            _buildText(
                              'scholarship.applicant.father_income'.tr,
                              controller.babaSalary.value,
                            ),
                          ],
                          _buildText(
                            'scholarship.applicant.mother_alive'.tr,
                            controller.anneHayata.value,
                          ),
                          if (!_isNoValue(controller.anneHayata.value)) ...[
                            _buildText(
                              'scholarship.applicant.mother_name'.tr,
                              controller.anneAdi.value,
                            ),
                            _buildText(
                              'scholarship.applicant.mother_surname'.tr,
                              controller.anneSoyadi.value,
                            ),
                            _buildClickableText(
                              'scholarship.applicant.mother_phone'.tr,
                              '+90${controller.annePhone.value}',
                              isPhone: true,
                            ),
                            _buildText(
                              'scholarship.applicant.mother_job'.tr,
                              controller.anneJob.value,
                            ),
                            _buildText(
                              'scholarship.applicant.mother_income'.tr,
                              controller.anneSalary.value,
                            ),
                          ],
                          _buildText(
                            'scholarship.applicant.home_ownership'.tr,
                            controller.evMulkiyeti.value,
                          ),
                          _buildText(
                            'scholarship.applicant.residence_city'.tr,
                            controller.ikametSehir.value,
                          ),
                          _buildText(
                            'scholarship.applicant.residence_district'.tr,
                            controller.ikametIlce.value,
                          ),
                        ]),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
