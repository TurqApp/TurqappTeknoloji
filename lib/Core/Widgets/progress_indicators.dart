import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UploadProgressController extends GetxController {
  final RxDouble progress = 0.0.obs;
  final RxString status = ''.obs;
  final RxString currentFile = ''.obs;
  final RxInt currentIndex = 0.obs;
  final RxInt totalFiles = 0.obs;
  final RxBool isVisible = false.obs;
  final RxBool isPaused = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  void startProgress({
    required int total,
    required String initialStatus,
  }) {
    totalFiles.value = total;
    currentIndex.value = 0;
    progress.value = 0.0;
    status.value = initialStatus;
    isVisible.value = true;
    isPaused.value = false;
    hasError.value = false;
    errorMessage.value = '';
  }

  void updateProgress({
    required int current,
    required String fileName,
    required String statusText,
    double? progressValue,
  }) {
    currentIndex.value = current;
    currentFile.value = fileName;
    status.value = statusText;

    if (progressValue != null) {
      progress.value = progressValue;
    } else {
      progress.value = current / totalFiles.value;
    }
  }

  void setError(String error) {
    hasError.value = true;
    errorMessage.value = error;
    status.value = 'progress.error_occurred'.tr;
  }

  void complete(String message) {
    progress.value = 1.0;
    status.value = message;
    Future.delayed(const Duration(seconds: 2), () {
      isVisible.value = false;
    });
  }

  void hide() {
    isVisible.value = false;
  }

  void pause() {
    isPaused.value = true;
    status.value = 'progress.paused'.tr;
  }

  void resume() {
    isPaused.value = false;
  }
}

class CircularProgressWithText extends StatelessWidget {
  final double progress;
  final String text;
  final Color? color;
  final double size;

  const CircularProgressWithText({
    super.key,
    required this.progress,
    required this.text,
    this.color,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: Colors.grey.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).primaryColor,
            ),
          ),
          Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: size * 0.2,
                fontWeight: FontWeight.bold,
                color: color ?? Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UploadProgressWidget extends StatelessWidget {
  final UploadProgressController controller;

  const UploadProgressWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isVisible.value) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'common.loading'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => controller.hide(),
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress circle
            CircularProgressWithText(
              progress: controller.progress.value,
              text: '${(controller.progress.value * 100).toInt()}%',
              size: 80,
            ),

            const SizedBox(height: 16),

            // Status text
            Text(
              controller.status.value,
              style: TextStyle(
                fontSize: 14,
                color:
                    controller.hasError.value ? Colors.red : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),

            if (controller.currentFile.value.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Dosya: ${controller.currentFile.value}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // File counter
            const SizedBox(height: 12),
            Text(
              '${controller.currentIndex.value} / ${controller.totalFiles.value}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),

            // Action buttons
            if (controller.hasError.value) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => controller.hide(),
                    child: Text('common.cancel'.tr),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      controller.hasError.value = false;
                      controller.resume();
                    },
                    child: Text('common.retry'.tr),
                  ),
                ],
              ),
            ] else if (controller.isPaused.value) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.resume(),
                child: Text('common.continue'.tr),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class LinearProgressWithLabels extends StatelessWidget {
  final double progress;
  final String leftLabel;
  final String rightLabel;
  final Color? color;

  const LinearProgressWithLabels({
    super.key,
    required this.progress,
    required this.leftLabel,
    required this.rightLabel,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              leftLabel,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              rightLabel,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;
  final Color? activeColor;
  final Color? inactiveColor;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = index <= currentStep;
        final isCompleted = index < currentStep;

        return Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? (activeColor ?? Theme.of(context).primaryColor)
                    : (inactiveColor ?? Colors.grey[300]),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step,
                style: TextStyle(
                  fontSize: 14,
                  color: isActive ? Colors.black : Colors.grey[600],
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
