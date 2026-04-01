export type PushTypeMap = {
  follow: boolean;
  comment: boolean;
  message: boolean;
  like: boolean;
  reshared_posts: boolean;
  shared_as_posts: boolean;
  posts: boolean;
};

export const defaultPushTypes: PushTypeMap = {
  follow: true,
  comment: true,
  message: true,
  like: true,
  reshared_posts: false,
  shared_as_posts: true,
  posts: true,
};

const interactionPushQuietWindowsMs: Record<string, number> = {
  like: 30 * 60 * 1000,
  comment: 2 * 60 * 1000,
  reshared_posts: 30 * 60 * 1000,
  shared_as_posts: 30 * 60 * 1000,
  posts: 30 * 60 * 1000,
};

const notificationPreferenceDefaults = {
  pauseAll: false,
  sleepMode: false,
  messagesOnly: false,
  messages: {
    directMessages: true,
  },
  posts: {
    posts: true,
    comments: true,
    likes: true,
    postActivity: true,
  },
  followers: {
    follows: true,
  },
  opportunities: {
    jobApplications: true,
    tutoringApplications: true,
    applicationStatus: true,
  },
};

type NotificationPreferences = typeof notificationPreferenceDefaults;

function normalizeNotificationType(type: string): string {
  const normalized = String(type || "").trim().toLowerCase();
  switch (normalized) {
    case "user":
      return "follow";
    case "chat":
      return "message";
    case "posts":
      return "posts";
    default:
      return normalized;
  }
}

function readBool(source: Record<string, unknown>, path: string): boolean {
  let current: unknown = source;
  for (const segment of path.split(".")) {
    if (!current || typeof current !== "object") return false;
    current = (current as Record<string, unknown>)[segment];
  }
  return current === true;
}

function deepMerge(
  base: Record<string, unknown>,
  override: Record<string, unknown>,
): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  const keys = new Set<string>([
    ...Object.keys(base || {}),
    ...Object.keys(override || {}),
  ]);

  for (const key of keys) {
    const baseValue = base?.[key];
    const overrideValue = override?.[key];
    if (
      baseValue &&
      typeof baseValue === "object" &&
      !Array.isArray(baseValue) &&
      overrideValue &&
      typeof overrideValue === "object" &&
      !Array.isArray(overrideValue)
    ) {
      result[key] = deepMerge(
        baseValue as Record<string, unknown>,
        overrideValue as Record<string, unknown>,
      );
    } else if (overrideValue !== undefined) {
      result[key] = overrideValue;
    } else {
      result[key] = baseValue;
    }
  }

  return result;
}

function normalizeLegacyPreferences(
  raw: Record<string, unknown>,
): Record<string, unknown> {
  const normalized = { ...raw };
  const posts = normalized.posts;
  if (posts && typeof posts === "object" && !Array.isArray(posts)) {
    const mappedPosts = { ...(posts as Record<string, unknown>) };
    const legacyPostActivity = mappedPosts.postActivity;
    if (typeof legacyPostActivity === "boolean") {
      if (mappedPosts.posts === undefined) {
        mappedPosts.posts = legacyPostActivity;
      }
      if (mappedPosts.likes === undefined) {
        mappedPosts.likes = legacyPostActivity;
      }
    }
    normalized.posts = mappedPosts;
  }
  return normalized;
}

export function interactionThrottleType(type: string): string {
  return normalizeNotificationType(type);
}

export function interactionQuietWindowMs(type: string): number | undefined {
  return interactionPushQuietWindowsMs[interactionThrottleType(type)];
}

export function isNotificationTypeEnabled(
  type: string,
  types: PushTypeMap,
): boolean {
  switch (normalizeNotificationType(type)) {
    case "follow":
      return types.follow;
    case "comment":
      return types.comment;
    case "message":
      return types.message;
    case "like":
      return types.like;
    case "reshared_posts":
      return types.reshared_posts;
    case "shared_as_posts":
      return types.shared_as_posts;
    case "posts":
      return types.posts;
    default:
      return true;
  }
}

export function notificationBodyFromType(type: string): string {
  switch (normalizeNotificationType(type)) {
    case "follow":
      return "seni takip etmeye başladı";
    case "message":
      return "sana mesaj gönderdi";
    case "comment":
      return "gönderine yorum yaptı";
    case "like":
      return "gönderini beğendi";
    case "reshared_posts":
      return "gönderini yeniden paylaştı";
    case "shared_as_posts":
      return "gönderini paylaştı";
    case "posts":
    default:
      return "gönderinle etkileşime geçti";
  }
}

function asPositiveInt(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.max(0, Math.floor(value));
  }
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return Math.max(0, Math.floor(parsed));
    }
  }
  return 0;
}

function isMilestoneCount(
  count: number,
  milestones: number[],
  repeatEvery: number,
): boolean {
  if (count <= 0) return false;
  if (milestones.includes(count)) return true;
  const lastMilestone = milestones[milestones.length - 1] || 0;
  return count > lastMilestone && repeatEvery > 0 && count % repeatEvery === 0;
}

export function shouldDispatchNotificationPush(
  type: string,
  payload: Record<string, unknown>,
): boolean {
  switch (normalizeNotificationType(type)) {
    case "like":
      return isMilestoneCount(
        asPositiveInt(payload.likeCount),
        [10, 25, 50, 100, 250, 500, 1000],
        1000,
      );
    case "reshared_posts":
      return false;
    case "shared_as_posts":
    case "comment_like":
      return false;
    case "posts":
      return payload.followedPostSubscriber === true;
    default:
      return true;
  }
}

export function mergeNotificationPreferences(
  raw: Record<string, unknown> | undefined,
): NotificationPreferences {
  return deepMerge(
    notificationPreferenceDefaults as unknown as Record<string, unknown>,
    normalizeLegacyPreferences(raw || {}),
  ) as NotificationPreferences;
}

export function isUserNotificationTypeEnabled(
  type: string,
  rawPrefs: Record<string, unknown> | undefined,
): boolean {
  const prefs = mergeNotificationPreferences(rawPrefs);
  const normalizedType = normalizeNotificationType(type);

  if (readBool(prefs as unknown as Record<string, unknown>, "pauseAll")) {
    return false;
  }

  if (readBool(prefs as unknown as Record<string, unknown>, "messagesOnly")) {
    return normalizedType === "message";
  }

  switch (normalizedType) {
    case "message":
      return readBool(
        prefs as unknown as Record<string, unknown>,
        "messages.directMessages",
      );
    case "comment":
      return readBool(
        prefs as unknown as Record<string, unknown>,
        "posts.comments",
      );
    case "like":
    case "comment_like":
      return (
        readBool(
          prefs as unknown as Record<string, unknown>,
          "posts.likes",
        ) ||
        readBool(
          prefs as unknown as Record<string, unknown>,
          "posts.postActivity",
        )
      );
    case "reshared_posts":
    case "shared_as_posts":
    case "posts":
      return (
        readBool(
          prefs as unknown as Record<string, unknown>,
          "posts.posts",
        ) ||
        readBool(
          prefs as unknown as Record<string, unknown>,
          "posts.postActivity",
        )
      );
    case "follow":
      return readBool(
        prefs as unknown as Record<string, unknown>,
        "followers.follows",
      );
    case "job_application":
    case "market_offer":
      return readBool(
        prefs as unknown as Record<string, unknown>,
        "opportunities.jobApplications",
      );
    case "tutoring_application":
      return readBool(
        prefs as unknown as Record<string, unknown>,
        "opportunities.tutoringApplications",
      );
    case "tutoring_status":
    case "market_offer_status":
      return readBool(
        prefs as unknown as Record<string, unknown>,
        "opportunities.applicationStatus",
      );
    default:
      return true;
  }
}
