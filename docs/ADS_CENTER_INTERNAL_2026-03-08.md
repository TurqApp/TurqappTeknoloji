# Ads Center Internal Plan (Admin Only)

Date: 2026-03-08

## Scope
- Admin-only Ads Center enabled
- Public ad visibility disabled by default
- Delivery engine + simulation ready
- Feed/Shorts/Explore hooks prepared (no public render)

## Collections

### `system_flags/global`
```json
{
  "adsInfrastructureEnabled": true,
  "adsAdminPanelEnabled": true,
  "adsDeliveryEnabled": false,
  "adsPublicVisibilityEnabled": false,
  "adsPreviewModeEnabled": true,
  "updatedAt": 1772908800000
}
```

### `ads_campaigns/{campaignId}`
```json
{
  "advertiserId": "adv_123",
  "name": "Konya Feed Deneme",
  "status": "draft",
  "placementTypes": ["feed", "shorts"],
  "budgetType": "daily",
  "totalBudget": 10000,
  "dailyBudget": 500,
  "spentAmount": 0,
  "currency": "TRY",
  "startAt": 1772908800000,
  "endAt": 1773513600000,
  "targeting": {
    "countries": ["TR"],
    "cities": ["Konya"],
    "minAge": 18,
    "maxAge": 45,
    "devicePlatforms": ["ios"],
    "appVersions": ["1.1.4"]
  },
  "creativeIds": ["creative_1"],
  "bidType": "cpm",
  "bidAmount": 2.5,
  "priority": 10,
  "isTestCampaign": true,
  "deliveryEnabled": false,
  "frequencyCapPerDay": 3,
  "createdAt": 1772908800000,
  "updatedAt": 1772908800000,
  "createdBy": "admin_uid",
  "approvedBy": ""
}
```

### `ads_creatives/{creativeId}`
```json
{
  "campaignId": "campaign_1",
  "type": "hlsVideo",
  "storagePath": "ads/creatives/campaign_1/video.mp4",
  "mediaURL": "https://.../video.mp4",
  "hlsMasterURL": "https://cdn.../master.m3u8",
  "thumbnailURL": "https://.../thumb.jpg",
  "aspectRatio": 0.5625,
  "durationSec": 16,
  "headline": "Yeni Kampanya",
  "bodyText": "Özel içerik",
  "ctaText": "Hemen İncele",
  "destinationURL": "https://turqapp.com",
  "moderationStatus": "pending",
  "reviewNotes": "",
  "createdAt": 1772908800000,
  "updatedAt": 1772908800000
}
```

### `ads_advertisers/{advertiserId}`
```json
{
  "name": "TurqApp Internal",
  "contactEmail": "ads@turqapp.com",
  "contactPhone": "+90...",
  "active": true,
  "createdAt": 1772908800000,
  "updatedAt": 1772908800000
}
```

### `ads_targeting_index/{key}`
```json
{
  "key": "TR:Konya:18-45:feed",
  "campaignIds": ["campaign_1"],
  "updatedAt": 1772908800000
}
```

### `ads_impressions/{id}`
```json
{
  "campaignId": "campaign_1",
  "creativeId": "creative_1",
  "userId": "uid_x",
  "placement": "feed",
  "isPreview": true,
  "createdAt": 1772908800000
}
```

### `ads_clicks/{id}`
```json
{
  "campaignId": "campaign_1",
  "creativeId": "creative_1",
  "userId": "uid_x",
  "placement": "feed",
  "ctaTap": true,
  "destinationUrl": "https://turqapp.com",
  "isPreview": true,
  "createdAt": 1772908800000
}
```

### `ads_delivery_logs/{id}`
```json
{
  "userId": "uid_x",
  "placement": "feed",
  "country": "TR",
  "city": "Konya",
  "age": 28,
  "hasAd": true,
  "selectedCampaignId": "campaign_1",
  "selectedCreativeId": "creative_1",
  "decisions": [
    { "campaignId": "campaign_1", "eligible": true, "reasons": [] }
  ],
  "message": "eligible",
  "isPreview": true,
  "createdAt": 1772908800000
}
```

### `ads_daily_stats/{campaignId_day}`
```json
{
  "campaignId": "campaign_1",
  "date": 1772908800000,
  "totalImpressions": 120,
  "uniqueReach": 98,
  "clicks": 11,
  "ctr": 9.16,
  "spend": 35.5,
  "avgCpc": 3.22,
  "avgCpm": 295.83,
  "videoCompletionRate": 47.2,
  "updatedAt": 1772912400000
}
```

## Security
- `ads_*` collections: admin read/write only
- `ads_impressions`, `ads_clicks`, `ads_daily_stats`, `ads_delivery_logs` client write disabled
- Critical writes via Cloud Functions (`adsLogEvent`, `adsAggregateDailyStats`)

## Delivery behavior
- Eligible checks:
  - campaign status
  - date range
  - placement match
  - budget availability
  - targeting match (country/city/age/platform/version)
  - creative moderation
- Public injection still off unless:
  - `adsDeliveryEnabled=true`
  - `adsPublicVisibilityEnabled=true`

## Rollout
1. Keep `adsPublicVisibilityEnabled=false`
2. Run admin simulation + monitor logs
3. Validate stats and budget behavior
4. Gradually open flags after readiness
