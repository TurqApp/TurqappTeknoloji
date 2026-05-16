#!/usr/bin/env bash
set -euo pipefail

DEVICE_ID="${DEVICE_ID:-}"
ADB_BIN="${ADB_BIN:-/Users/turqapp/Library/Android/sdk/platform-tools/adb}"

adb_args=()
if [[ -n "$DEVICE_ID" ]]; then
  adb_args=(-s "$DEVICE_ID")
fi

adb_cmd() {
  if ((${#adb_args[@]})); then
    "$ADB_BIN" "${adb_args[@]}" "$@"
  else
    "$ADB_BIN" "$@"
  fi
}

usage() {
  cat <<USAGE
Usage: DEVICE_ID=<adb-id> $0 clear|sample [log-file]

clear   Clear Android logcat before a focused QA pass.
sample  Summarize HLS segment/download and stop/playback signals from logcat.

If a log file is passed, sample reads that file instead of adb logcat.
Output lines are prefixed with [HLS_USAGE_SUMMARY] so QA reports can grep them.
USAGE
}

clear_logcat() {
  adb_cmd logcat -c
  echo "[HLS_USAGE_SUMMARY] label=clear status=ok"
}

read_logs() {
  local file="${1:-}"
  if [[ -n "$file" ]]; then
    cat "$file"
  else
    adb_cmd logcat -d
  fi
}

sample_logs() {
  local file="${1:-}"
  read_logs "$file" | awk '
    function field(line, key,    pattern, value) {
      pattern = key "=[^ ]+"
      if (match(line, pattern)) {
        value = substr(line, RSTART + length(key) + 1, RLENGTH - length(key) - 1)
        return value
      }
      return ""
    }

    function add_bytes(bucket, bytes) {
      if (bucket == "") bucket = "unknown"
      bytes_by_bucket[bucket] += bytes
      count_by_bucket[bucket] += 1
    }

    function add_count(bucket) {
      if (bucket == "") bucket = "unknown"
      count_only[bucket] += 1
    }

    function short_doc(doc) {
      if (length(doc) > 8) return substr(doc, 1, 8)
      return doc
    }

    function mark_replay_start(doc, stage) {
      doc = short_doc(doc)
      if (doc == "") return
      replay_active[doc] = 1
      replay_start_count += 1
      add_count("replayStage:" stage)
    }

    function add_replay_network(doc, segment, bytes, origin, source) {
      doc = short_doc(doc)
      if (doc == "" || replay_active[doc] != 1) return
      key = doc "|" segment
      replay_network_count += 1
      replay_network_bytes += bytes
      replay_network_count_by_key[key] += 1
      replay_network_bytes_by_key[key] += bytes
      add_bytes("replayNetworkOrigin:" origin, bytes)
      add_bytes("replayNetworkSource:" source, bytes)
    }

    /\[HlsSegmentTrace\]/ {
      source = field($0, "source")
      cacheHit = field($0, "cacheHit")
      origin = field($0, "origin")
      doc = field($0, "doc")
      visible = field($0, "visible")
      owner = field($0, "owner")
      pending = field($0, "pendingPrefetch")
      activeDownload = field($0, "activeDownload")
      activeShort = field($0, "activeShort")
      activeFeed = field($0, "activeFeed")
      tier = field($0, "tier")
      bytes = field($0, "bytes") + 0

      segment_count += 1
      total_bytes += bytes
      add_bytes("source:" source, bytes)
      add_bytes("origin:" origin, bytes)
      add_bytes("owner:" owner, bytes)
      add_bytes("tier:" tier, bytes)
      add_bytes("visible:" visible, bytes)
      add_bytes("cacheHit:" cacheHit, bytes)
      add_bytes("activeFeed:" activeFeed, bytes)
      add_bytes("activeShort:" activeShort, bytes)
      add_bytes("activeDownload:" activeDownload, bytes)
      add_bytes("pendingPrefetch:" pending, bytes)

      if (cacheHit == "false") {
        network_bytes += bytes
        add_bytes("networkOrigin:" origin, bytes)
        add_replay_network(doc, field($0, "segment"), bytes, origin, source)
      }
      if (visible == "false" && cacheHit == "false") {
        hidden_network_bytes += bytes
        add_bytes("hiddenNetworkOrigin:" origin, bytes)
      }
      if (visible == "false" && cacheHit == "false" && activeFeed != "true" && activeShort != "true") {
        background_suspect_bytes += bytes
        add_bytes("backgroundSuspectOrigin:" origin, bytes)
      }
      if (doc != "") {
        doc_bytes[doc] += bytes
        doc_count[doc] += 1
      }
      next
    }

    /\[HlsSegmentServe\]/ {
      doc = field($0, "doc")
      segment = field($0, "segment")
      cacheHit = field($0, "cacheHit")
      bytes = field($0, "bytes") + 0
      key = doc "|" segment

      served_count += 1
      served_bytes += bytes
      add_bytes("serveCacheHit:" cacheHit, bytes)
      if (cacheHit == "false") {
        served_network_count += 1
        served_network_bytes += bytes
        add_replay_network(doc, segment, bytes, "serve", "serve")
        served_network_count_by_key[key] += 1
        served_network_bytes_by_key[key] += bytes
        if (served_network_count_by_key[key] > 1) {
          served_repeated_network_count += 1
          served_repeated_network_bytes += bytes
        }
      } else {
        served_cache_count += 1
        served_cache_bytes += bytes
      }
      next
    }

    /\[FeedReplayTrace\]/ {
      stage = field($0, "stage")
      doc = field($0, "doc")
      add_count("feedReplayTrace:" stage)
      if (stage == "manual_replay_start" ||
          stage == "completed_no_ad_autoreplay" ||
          stage == "completed_ad_autoreplay_after_delay") {
        mark_replay_start(doc, stage)
      }
      next
    }

    /\[PlaybackStopTrace\]/ {
      source = field($0, "source")
      action = field($0, "action")
      add_count("stopSource:" source)
      add_count("stopAction:" action)
      playback_stop_count += 1
      next
    }

    /\[HLSAdapterControl\]/ {
      command = field($0, "command")
      stopped = field($0, "isStopped")
      primaryFeed = field($0, "primaryFeedSurface")
      feedStyle = field($0, "feedStyleSurface")
      add_count("adapterCommand:" command)
      add_count("adapterStopped:" stopped)
      add_count("adapterPrimaryFeed:" primaryFeed)
      add_count("adapterFeedStyle:" feedStyle)
      adapter_signal_count += 1
      next
    }

    /\[TurqCdnProbe\]/ {
      signal = field($0, "signal")
      primaryFeed = field($0, "primaryFeed")
      isPlaying = field($0, "isPlaying")
      isLoading = field($0, "isLoading")
      softHeld = field($0, "softHeld")
      add_count("cdnSignal:" signal)
      add_count("cdnPrimaryFeed:" primaryFeed)
      add_count("cdnPlaying:" isPlaying)
      add_count("cdnLoading:" isLoading)
      add_count("cdnSoftHeld:" softHeld)
      cdn_probe_count += 1
      next
    }

    END {
      printf("[HLS_USAGE_SUMMARY] label=segments count=%d totalBytes=%d totalMB=%.2f networkBytes=%d networkMB=%.2f hiddenNetworkBytes=%d hiddenNetworkMB=%.2f backgroundSuspectBytes=%d backgroundSuspectMB=%.2f\n",
        segment_count, total_bytes, total_bytes / 1024 / 1024,
        network_bytes, network_bytes / 1024 / 1024,
        hidden_network_bytes, hidden_network_bytes / 1024 / 1024,
        background_suspect_bytes, background_suspect_bytes / 1024 / 1024)
      printf("[HLS_USAGE_SUMMARY] label=served count=%d bytes=%d mb=%.2f networkCount=%d networkBytes=%d networkMB=%.2f cacheCount=%d cacheBytes=%d cacheMB=%.2f repeatedNetworkCount=%d repeatedNetworkBytes=%d repeatedNetworkMB=%.2f\n",
        served_count, served_bytes, served_bytes / 1024 / 1024,
        served_network_count, served_network_bytes, served_network_bytes / 1024 / 1024,
        served_cache_count, served_cache_bytes, served_cache_bytes / 1024 / 1024,
        served_repeated_network_count, served_repeated_network_bytes,
        served_repeated_network_bytes / 1024 / 1024)
      printf("[HLS_USAGE_SUMMARY] label=replay starts=%d networkCount=%d networkBytes=%d networkMB=%.2f\n",
        replay_start_count, replay_network_count, replay_network_bytes,
        replay_network_bytes / 1024 / 1024)
      printf("[HLS_USAGE_SUMMARY] label=stops playbackStopTrace=%d adapterSignals=%d cdnProbeSignals=%d\n",
        playback_stop_count, adapter_signal_count, cdn_probe_count)

      for (bucket in bytes_by_bucket) {
        printf("[HLS_USAGE_SUMMARY] label=bytes bucket=%s count=%d bytes=%d mb=%.2f\n",
          bucket, count_by_bucket[bucket], bytes_by_bucket[bucket],
          bytes_by_bucket[bucket] / 1024 / 1024)
      }
      for (bucket in count_only) {
        printf("[HLS_USAGE_SUMMARY] label=count bucket=%s count=%d\n",
          bucket, count_only[bucket])
      }
      for (doc in doc_bytes) {
        printf("[HLS_USAGE_SUMMARY] label=doc doc=%s count=%d bytes=%d mb=%.2f\n",
          doc, doc_count[doc], doc_bytes[doc], doc_bytes[doc] / 1024 / 1024)
      }
      for (key in served_network_count_by_key) {
        if (served_network_count_by_key[key] <= 1) continue
        printf("[HLS_USAGE_SUMMARY] label=repeated_served_segment key=%s networkCount=%d networkBytes=%d networkMB=%.2f\n",
          key, served_network_count_by_key[key], served_network_bytes_by_key[key],
          served_network_bytes_by_key[key] / 1024 / 1024)
      }
      for (key in replay_network_count_by_key) {
        printf("[HLS_USAGE_SUMMARY] label=replay_network_segment key=%s networkCount=%d networkBytes=%d networkMB=%.2f\n",
          key, replay_network_count_by_key[key], replay_network_bytes_by_key[key],
          replay_network_bytes_by_key[key] / 1024 / 1024)
      }
    }
  ' | sort
}

case "${1:-sample}" in
  clear) clear_logcat ;;
  sample) sample_logs "${2:-}" ;;
  *) usage; exit 2 ;;
esac
