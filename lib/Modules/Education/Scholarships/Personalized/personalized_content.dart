import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Personalized/personalized_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart';

class PersonalizedContent extends StatelessWidget {
  final IndividualScholarshipsModel model;
  final bool firmaDetayMi;

  const PersonalizedContent({
    super.key,
    required this.model,
    required this.firmaDetayMi,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 0.2),
        ),
        child: _buildNetworkImage(),
      ),
    );
  }

  Widget _buildNetworkImage() {
    return CachedNetworkImage(
      imageUrl: model.img,
      memCacheHeight: 500,
      fit: BoxFit.contain,
      placeholder: (context, url) => _buildLoadingWidget(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.grey[300],
      child: const Center(child: CupertinoActivityIndicator()),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.error, color: Colors.red, size: 30),
      ),
    );
  }

  Future<void> _navigateToDetail(BuildContext context) async {
    final scholarshipData = _createScholarshipData();
    Get.to(() => ScholarshipDetailView(), arguments: scholarshipData);
  }

  Map<String, dynamic> _createScholarshipData() {
    String docId = '';
    if (Get.isRegistered<PersonalizedController>()) {
      final pc = Get.find<PersonalizedController>();
      docId = pc.docIdByTimestamp[model.timeStamp] ?? '';
    }
    return {
      'model': model,
      'type': 'bireysel',
      'userData': null,
      'docId': docId,
      'scholarshipId': docId,
    };
  }
}
