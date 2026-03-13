import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class TestsController extends GetxController {
  final TestRepository _testRepository = TestRepository.ensure();
  final list = <TestsModel>[].obs;
  final showButtons = false.obs;
  final ustBar = true.obs;
  final scrollController = ScrollController();
  final _previousOffset = 0.0.obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final RxDouble scrollOffset = 0.0.obs;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 30;

  @override
  void onInit() {
    super.onInit();
    getData();
    _scrollControl();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _scrollControl() {
    scrollController.addListener(() {
      final currentOffset = scrollController.position.pixels;

      if (currentOffset > _previousOffset.value) {
        if (showButtons.value) {
          showButtons.value = false;
        }
        ustBar.value = false;
      } else if (currentOffset < _previousOffset.value) {
        if (showButtons.value) {
          showButtons.value = false;
        }
        ustBar.value = true;
      }

      if (currentOffset >= scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore.value &&
          hasMore.value) {
        loadMore();
      }

      _previousOffset.value = currentOffset;
    });
  }

  Future<void> getData() async {
    isLoading.value = true;
    hasMore.value = true;
    _lastDocument = null;
    try {
      final page = await _testRepository.fetchSharedPage(limit: _pageSize);
      list.assignAll(page.items);
      _lastDocument = page.lastDocument;
      hasMore.value = page.hasMore;
    } catch (e) {
      log("TestsController.getData error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_lastDocument == null || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final page = await _testRepository.fetchSharedPage(
        startAfter: _lastDocument,
        limit: _pageSize,
      );
      list.addAll(page.items);
      _lastDocument = page.lastDocument;
      hasMore.value = page.hasMore;
    } catch (e) {
      log("TestsController.loadMore error: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }
}
