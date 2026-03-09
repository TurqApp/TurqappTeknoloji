# Functions Drift Report (2026-03-09)

## Summary
- Live functions: **60**
- Local exported functions: **67**
- Matched (live + local): **60**
- Live only: **0**
- Local only: **7**

## Local Only Functions (Not Deployed)
| Function | Local Source |
|---|---|
| adsAggregateDailyStats | 19_adsCenter.ts |
| adsLogEvent | 19_adsCenter.ts |
| adsSimulateDelivery | 19_adsCenter.ts |
| generatePostTags | 04_tagSettings.ts |
| generateTagDetails | 04_tagSettings.ts |
| getTagSettings | 04_tagSettings.ts |
| writeTagIndex | 04_tagSettings.ts |

## Live Only Functions (Not Found in Local Exports)
| Function | Version | Region | Trigger | Runtime |
|---|---|---|---|---|
| - | - | - | - | - |

## Notes
- This report was generated from live output of `firebase functions:list --json`.
- Full machine-readable report: `docs/FUNCTIONS_DRIFT_REPORT_2026-03-09.json`.