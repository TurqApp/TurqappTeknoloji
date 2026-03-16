const String kMarketSchemaSeedJson = '''
{
  "version": 1,
  "generatedAt": 1742083200000,
  "source": {
    "projectId": "turqappteknoloji",
    "collection": "market",
    "docCount": 685
  },
  "cache": {
    "strategy": "cache-first",
    "recommendedKey": "market_schema_v1"
  },
  "ui": {
    "recommendedRoundMenu": [
      {"key": "create", "label": "İlan Ekle", "icon": "add_circle", "accent": "#111827"},
      {"key": "my_items", "label": "İlanlarım", "icon": "inventory_2", "accent": "#2563EB"},
      {"key": "saved", "label": "Beğendiklerim", "icon": "thumb_up", "accent": "#F59E0B"},
      {"key": "offers", "label": "Tekliflerim", "icon": "local_offer", "accent": "#16A34A"},
      {"key": "categories", "label": "Kategoriler", "icon": "apps", "accent": "#7C3AED"},
      {"key": "nearby", "label": "Yakınımdakiler", "icon": "near_me", "accent": "#DC2626"}
    ]
  },
  "categories": [
    {
      "key": "elektronik",
      "label": "Elektronik",
      "icon": "devices",
      "menuIcon": "phone",
      "accent": "#1D4ED8",
      "meta": {
        "supportsOffer": true,
        "supportsCart": false,
        "interactionMode": "message_offer",
        "contactModes": ["message_only", "phone"]
      },
      "children": [
        {
          "key": "telefon",
          "label": "Telefon",
          "icon": "phone_iphone",
          "menuIcon": "phone",
          "accent": "#2563EB"
        },
        {
          "key": "bilgisayar",
          "label": "Bilgisayar",
          "icon": "laptop_mac",
          "menuIcon": "computer",
          "accent": "#0F766E"
        },
        {
          "key": "oyun-elektronigi",
          "label": "Oyun Elektroniği",
          "icon": "sports_esports",
          "menuIcon": "joystick",
          "accent": "#7C3AED"
        }
      ]
    },
    {
      "key": "giyim",
      "label": "Giyim",
      "icon": "checkroom",
      "menuIcon": "style",
      "accent": "#DB2777",
      "meta": {
        "supportsOffer": true,
        "supportsCart": false,
        "interactionMode": "message_offer",
        "contactModes": ["message_only", "phone"]
      }
    },
    {
      "key": "ev-yasam",
      "label": "Ev & Yaşam",
      "icon": "chair",
      "menuIcon": "weekend",
      "accent": "#EA580C",
      "meta": {
        "supportsOffer": true,
        "supportsCart": false,
        "interactionMode": "message_offer",
        "contactModes": ["message_only", "phone"]
      }
    },
    {
      "key": "spor",
      "label": "Spor",
      "icon": "sports_soccer",
      "menuIcon": "exercise",
      "accent": "#16A34A",
      "meta": {
        "supportsOffer": true,
        "supportsCart": false,
        "interactionMode": "message_offer",
        "contactModes": ["message_only", "phone"]
      }
    },
    {
      "key": "emlak",
      "label": "Emlak",
      "icon": "home_work",
      "menuIcon": "apartment",
      "accent": "#1E40AF",
      "meta": {
        "supportsOffer": true,
        "supportsCart": false,
        "interactionMode": "message_offer",
        "contactModes": ["message_only", "phone"]
      }
    }
  ]
}
''';
