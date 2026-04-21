<template>
  <div
    :class="[
      embedded ? 'inline-assistant-root' : 'floating-assistant-root',
      { 'is-embedded': embedded },
    ]"
  >
    <button
      v-if="!embedded && !isOpen"
      class="floating-trigger flex-left"
      type="button"
      @click="openPanel"
    >
      <span class="trigger-icon-wrap vertical-center">
        <BarChartOutlined class="trigger-icon" />
      </span>
      <span class="trigger-copy">
        <span class="trigger-title">{{ t("monitor.title") }}</span>
      </span>
    </button>

    <div
      v-if="embedded || isOpen"
      ref="panelRef"
      class="assistant-panel"
      :class="{
        'is-dragging': isDragging,
        'is-pinned': isPinned,
        'is-embedded': embedded,
      }"
      :style="embedded ? undefined : panelStyle"
      @mouseenter="embedded ? undefined : handlePanelEnter"
      @mouseleave="embedded ? undefined : handlePanelLeave"
    >
      <div v-if="!embedded" class="pin-rail">
        <button
          class="rail-button vertical-center"
          :class="{ active: isPinned }"
          type="button"
          :title="t('monitor.pin')"
          @click="togglePinned"
        >
          <PushpinOutlined class="pin-icon" />
        </button>
      </div>

      <div class="panel-shell" :class="{ embedded }">
        <div class="panel-header flex-between" @mousedown="startDrag">
          <div class="header-brand flex-left">
            <span class="brand-icon vertical-center">
              <BarChartOutlined />
            </span>
            <div class="header-copy">
              <div class="eyebrow">{{ t("monitor.eyebrow") }}</div>
              <div class="panel-title">{{ t("monitor.title") }}</div>
            </div>
          </div>

          <div class="header-actions flex-left">
            <a-tooltip :title="t('monitor.refresh')">
              <button
                class="action-button vertical-center"
                type="button"
                @click="handleManualRefresh"
              >
                <SyncOutlined
                  class="action-icon"
                  :class="{ spinning: isRefreshing }"
                />
              </button>
            </a-tooltip>
            <a-tooltip :title="t('monitor.resetStats')">
              <button
                class="action-button action-danger vertical-center"
                type="button"
                :disabled="isRefreshing || isResetting"
                @click="handleReset"
              >
                <RedoOutlined
                  class="action-icon"
                  :class="{ spinning: isResetting }"
                />
              </button>
            </a-tooltip>
            <button
              v-if="!embedded"
              class="close-button vertical-center"
              type="button"
              :title="t('monitor.close')"
              @click="closePanel"
            >
              <CloseOutlined />
            </button>
          </div>
        </div>

        <div class="panel-scroll" :class="{ embedded }">
          <section class="cloud-panel section-card">
            <div class="section-heading compact-gap flex-between">
              <div>
                <div class="section-title">
                  {{ t("monitor.cloudProvider") }}
                </div>
              </div>
            </div>

            <div class="compression-dashboard">
              <div class="compression-metrics-row">
                <div class="metric-card token-consumption-card">
                  <span class="metric-card-label">{{
                    t("monitor.tokenConsumption")
                  }}</span>
                  <span class="metric-card-value">{{
                    tokenConsumptionText
                  }}</span>
                </div>

                <div class="metric-card saved-token-card">
                  <span class="metric-card-label">
                    {{ t("monitor.savedTokenNoCostMain") }}
                    <span class="metric-card-label-sub">
                      {{ t("monitor.noCost") }}
                    </span>
                  </span>
                  <span class="metric-card-value">{{
                    savedTokenNoCostText
                  }}</span>
                </div>
              </div>

              <div class="compression-ring-card inline-chart">
                <div class="compression-ring-wrap">
                  <svg
                    class="compression-ring"
                    viewBox="0 0 120 120"
                    aria-hidden="true"
                  >
                    <circle
                      class="compression-ring-track"
                      cx="60"
                      cy="60"
                      r="46"
                    />
                    <circle
                      class="compression-ring-progress"
                      cx="60"
                      cy="60"
                      r="46"
                      :stroke-dasharray="ringCircumference"
                      :stroke-dashoffset="ringDashOffset"
                    />
                  </svg>
                  <div class="compression-ring-center">
                    <span class="compression-ring-value">{{
                      compressionRateText
                    }}</span>
                    <span class="compression-ring-caption">{{
                      t("monitor.saved")
                    }}</span>
                  </div>
                </div>
                <div class="total-token">
                  {{ t("common.total") }}:
                  <div class="total-value">
                    {{ originalTokensText }}
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section class="local-panel section-card">
            <div class="section-heading compact-gap flex-between">
              <div>
                <div class="section-title">{{ t("monitor.localTotals") }}</div>
              </div>
            </div>

            <div class="local-card">
              <div class="local-card-head">
                <span class="totals-dot local"></span>
                <span class="local-card-label">{{
                  t("monitor.tokenConsumption")
                }}</span>
              </div>
              <div class="local-card-value">{{ localTotalText }}</div>
            </div>
          </section>

          <section class="overall-panel section-card">
            <div class="section-heading compact-gap flex-between">
              <div>
                <div class="section-title">
                  {{ t("monitor.overallTotals") }}
                </div>
              </div>
            </div>

            <div class="overall-card enhanced">
              <div class="overall-copy">
                <span class="overall-label">
                  <span class="totals-dot overall"></span>
                  {{ t("monitor.overallTotals") }}
                </span>
                <span class="overall-value">{{ overallTotalText }}</span>
              </div>
              <div class="overall-stack">
                <div class="overall-stack-track enhanced">
                  <div
                    class="overall-segment local"
                    :style="{ width: `${localShareOfOverall}%` }"
                  ></div>
                  <div
                    class="overall-segment cloud"
                    :style="{ width: `${cloudShareOfOverall}%` }"
                  ></div>
                </div>
                <div class="overall-legend">
                  <span class="legend-chip local">
                    <span class="legend-chip-label">{{
                      t("monitor.localShort")
                    }}</span>
                    <span class="legend-chip-value">{{ localShareText }}</span>
                  </span>
                  <span class="legend-chip cloud">
                    <span class="legend-chip-label">{{
                      t("monitor.cloudShort")
                    }}</span>
                    <span class="legend-chip-value">{{ cloudShareText }}</span>
                  </span>
                </div>
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import {
  BarChartOutlined,
  CloseOutlined,
  PushpinOutlined,
  RedoOutlined,
  SyncOutlined,
} from "@ant-design/icons-vue";
import { computed, onBeforeUnmount, onMounted, ref } from "vue";
import { useI18n } from "vue-i18n";
import { getTokenStats, requestTokenRest } from "@/api/knowledgeBase";

const props = withDefaults(
  defineProps<{
    embedded?: boolean;
  }>(),
  {
    embedded: false,
  },
);

interface TotalInputMetrics {
  original_tokens: number;
  compressed_tokens: number;
  save_pct: number;
  rest_pct: number;
}

interface SystemAndToolsMetrics {
  original_tokens: number;
  compressed_tokens: number;
  saved_tokens: number;
  rest_pct: number;
}

interface TokenMetrics {
  total_tokens: number;
}

interface CompressionMetrics {
  total_input: TotalInputMetrics;
  system_and_tools: SystemAndToolsMetrics;
}

interface MonitorData {
  token_metrics: {
    local_model: TokenMetrics;
    cloud_model: TokenMetrics;
    overall: TokenMetrics;
  };
  compression: CompressionMetrics;
}

const POLL_INTERVAL = 3000;
const { t, locale } = useI18n();
const embedded = computed(() => props.embedded);

const createDefaultMonitorData = (): MonitorData => ({
  token_metrics: {
    local_model: { total_tokens: 0 },
    cloud_model: { total_tokens: 0 },
    overall: { total_tokens: 0 },
  },
  compression: {
    total_input: {
      original_tokens: 0,
      compressed_tokens: 0,
      save_pct: 0,
      rest_pct: 0,
    },
    system_and_tools: {
      original_tokens: 0,
      compressed_tokens: 0,
      saved_tokens: 0,
      rest_pct: 0,
    },
  },
});

const monitorData = ref<MonitorData>(createDefaultMonitorData());
const isOpen = ref(false);
const isPinned = ref(false);
const isDragging = ref(false);
const isRefreshing = ref(false);
const isResetting = ref(false);
const panelRef = ref<HTMLElement | null>(null);

const PANEL_WIDTH = 488;
const PANEL_MIN_HEIGHT = 560;

const getInitialPosition = () => ({
  x: Math.max(16, window.innerWidth - PANEL_WIDTH - 24),
  y: Math.max(16, Math.round((window.innerHeight - PANEL_MIN_HEIGHT) / 2)),
});

const position = ref(getInitialPosition());

let dragOffsetX = 0;
let dragOffsetY = 0;
let pollTimer: number | undefined;
let closeTimer: number | undefined;

const numberFormatter = computed(
  () =>
    new Intl.NumberFormat(locale.value.startsWith("zh") ? "zh-CN" : "en-US"),
);

const formatNumber = (value: number) => numberFormatter.value.format(value);
const formatCompactDecimal = (
  value: number,
  divisor: number,
  suffix: string,
) => {
  const compactValue = value / divisor;
  const roundedValue = Math.round(compactValue * 10) / 10;

  return `${roundedValue.toFixed(1)}${suffix}`;
};

const formatCompactNumber = (value: number) => {
  const absValue = Math.abs(value);

  if (absValue >= 1000000000) {
    return formatCompactDecimal(value, 1000000000, "G");
  }

  if (absValue >= 1000000) {
    return formatCompactDecimal(value, 1000000, "M");
  }

  if (absValue >= 1000) {
    return formatCompactDecimal(value, 1000, "K");
  }

  return formatNumber(value);
};
const formatPercent = (value: number) => `${value.toFixed(1)}%`;

const normalizeNumber = (value: unknown, fallback = 0) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const normalizeTokenMetrics = (metrics: any): TokenMetrics => ({
  total_tokens: normalizeNumber(metrics?.total_tokens),
});

const normalizeCompressionMetrics = (compression: any): CompressionMetrics => ({
  total_input: {
    original_tokens: normalizeNumber(compression?.total_input?.original_tokens),
    compressed_tokens: normalizeNumber(
      compression?.total_input?.compressed_tokens,
    ),
    save_pct: normalizeNumber(compression?.total_input?.save_pct),
    rest_pct: normalizeNumber(compression?.total_input?.rest_pct),
  },
  system_and_tools: {
    original_tokens: normalizeNumber(
      compression?.system_and_tools?.original_tokens,
    ),
    compressed_tokens: normalizeNumber(
      compression?.system_and_tools?.compressed_tokens,
    ),
    saved_tokens: normalizeNumber(compression?.system_and_tools?.saved_tokens),
    rest_pct: normalizeNumber(compression?.system_and_tools?.rest_pct),
  },
});

const normalizeMonitorData = (payload: any): MonitorData => {
  const stats =
    payload?.data && typeof payload.data === "object" ? payload.data : payload;

  return {
    token_metrics: {
      local_model: normalizeTokenMetrics(stats?.token_metrics?.local_model),
      cloud_model: normalizeTokenMetrics(stats?.token_metrics?.cloud_model),
      overall: normalizeTokenMetrics(stats?.token_metrics?.overall),
    },
    compression: normalizeCompressionMetrics(stats?.compression),
  };
};
const fetchStats = async (showRefreshing = false) => {
  if (showRefreshing) {
    isRefreshing.value = true;
  }

  try {
    const response = await getTokenStats();
    monitorData.value = normalizeMonitorData(response);
  } finally {
    isRefreshing.value = false;
  }
};

const startPolling = () => {
  stopPolling();
  pollTimer = window.setInterval(() => {
    void fetchStats();
  }, POLL_INTERVAL);
};

const stopPolling = () => {
  if (!pollTimer) {
    return;
  }

  window.clearInterval(pollTimer);
  pollTimer = undefined;
};

const localTotal = computed(
  () => monitorData.value.token_metrics.local_model.total_tokens,
);
const compressedInputTotal = computed(
  () => monitorData.value.compression.total_input.compressed_tokens,
);
const overallTotal = computed(
  () => localTotal.value + compressedInputTotal.value,
);

const localTotalText = computed(() => formatCompactNumber(localTotal.value));
const overallTotalText = computed(() =>
  formatCompactNumber(overallTotal.value),
);

const localShareOfOverall = computed(() => {
  if (overallTotal.value <= 0) {
    return 0;
  }

  return (localTotal.value / overallTotal.value) * 100;
});

const cloudShareOfOverall = computed(() => {
  if (overallTotal.value <= 0) {
    return 0;
  }

  return (compressedInputTotal.value / overallTotal.value) * 100;
});

const localShareText = computed(() => formatPercent(localShareOfOverall.value));
const cloudShareText = computed(() => formatPercent(cloudShareOfOverall.value));
const originalTokensText = computed(() =>
  formatCompactNumber(
    monitorData.value.compression.total_input.original_tokens,
  ),
);
const tokenConsumptionText = computed(() =>
  formatCompactNumber(
    monitorData.value.compression.total_input.compressed_tokens,
  ),
);
const savedTokenNoCostText = computed(() =>
  formatCompactNumber(
    monitorData.value.compression.system_and_tools.saved_tokens,
  ),
);
const compressionRateValue = computed(() => {
  const savePct = monitorData.value.compression.total_input.save_pct;

  if (savePct > 0) {
    return savePct;
  }

  return Math.max(0, 100 - monitorData.value.compression.total_input.rest_pct);
});
const compressionRateText = computed(() =>
  formatPercent(compressionRateValue.value),
);
const ringRadius = 46;
const ringCircumference = 2 * Math.PI * ringRadius;
const ringDashOffset = computed(
  () => ringCircumference * (1 - compressionRateValue.value / 100),
);

const panelStyle = computed(() => ({
  left: `${position.value.x}px`,
  top: `${position.value.y}px`,
}));

const clampPosition = (x: number, y: number) => {
  const panelWidth = panelRef.value?.offsetWidth ?? PANEL_WIDTH;
  const panelHeight = panelRef.value?.offsetHeight ?? PANEL_MIN_HEIGHT;
  const maxX = Math.max(16, window.innerWidth - panelWidth - 16);
  const maxY = Math.max(16, window.innerHeight - panelHeight - 16);

  position.value = {
    x: Math.min(Math.max(16, x), maxX),
    y: Math.min(Math.max(16, y), maxY),
  };
};

const handleManualRefresh = async () => {
  if (isRefreshing.value || isResetting.value) {
    return;
  }

  await fetchStats(true);
};

const handleReset = async () => {
  if (isRefreshing.value || isResetting.value) {
    return;
  }

  isResetting.value = true;
  try {
    await requestTokenRest();
    await fetchStats(true);
  } finally {
    isResetting.value = false;
  }
};

const openPanel = () => {
  if (embedded.value) {
    return;
  }

  clearCloseTimer();

  if (!isPinned.value) {
    position.value = getInitialPosition();
  }

  isOpen.value = true;
  clampPosition(position.value.x, position.value.y);
};

const closePanel = () => {
  if (embedded.value) {
    return;
  }

  isPinned.value = false;
  isOpen.value = false;
  stopDrag();
};

const clearCloseTimer = () => {
  if (!closeTimer) {
    return;
  }

  window.clearTimeout(closeTimer);
  closeTimer = undefined;
};

const scheduleClose = () => {
  if (embedded.value) {
    return;
  }

  if (isPinned.value) {
    return;
  }

  clearCloseTimer();
  closeTimer = window.setTimeout(() => {
    isOpen.value = false;
    stopDrag();
  }, 140);
};

const handlePanelEnter = () => {
  clearCloseTimer();
};

const handlePanelLeave = () => {
  scheduleClose();
};

const togglePinned = () => {
  if (embedded.value) {
    return;
  }

  isPinned.value = !isPinned.value;
  clearCloseTimer();
};

const handleDragMove = (event: MouseEvent) => {
  if (!isDragging.value) {
    return;
  }

  clampPosition(event.clientX - dragOffsetX, event.clientY - dragOffsetY);
};

const stopDrag = () => {
  if (embedded.value) {
    return;
  }

  isDragging.value = false;
  window.removeEventListener("mousemove", handleDragMove);
  window.removeEventListener("mouseup", stopDrag);
};

const startDrag = (event: MouseEvent) => {
  if (embedded.value) {
    return;
  }

  if (!isPinned.value) {
    return;
  }

  if ((event.target as HTMLElement | null)?.closest("button")) {
    return;
  }

  isDragging.value = true;
  dragOffsetX = event.clientX - position.value.x;
  dragOffsetY = event.clientY - position.value.y;
  window.addEventListener("mousemove", handleDragMove);
  window.addEventListener("mouseup", stopDrag);
};

const handleResize = () => {
  if (embedded.value) {
    return;
  }

  clampPosition(position.value.x, position.value.y);
};

onMounted(() => {
  window.addEventListener("resize", handleResize);
  void fetchStats(true);
  startPolling();
});

onBeforeUnmount(() => {
  clearCloseTimer();
  stopPolling();
  stopDrag();
  window.removeEventListener("resize", handleResize);
});
</script>

<style scoped lang="less">
.inline-assistant-root {
  width: 100%;
  height: 100%;
  min-height: 0;
}

.floating-assistant-root {
  position: fixed;
  inset: 0;
  pointer-events: none;
  z-index: 1200;
}

.floating-trigger,
.assistant-panel {
  pointer-events: auto;
}

.floating-trigger {
  position: fixed;
  right: 0;
  top: 60%;
  gap: 10px;
  width: 74px;
  height: 68px;
  padding: 10px 14px 10px 12px;
  border: 1px solid var(--monitor-border-accent);
  border-right: none;
  border-radius: 20px 0 0 20px;
  background: var(--monitor-surface);
  color: var(--font-main-color);
  box-shadow: var(--monitor-panel-shadow);
  cursor: pointer;
  overflow: hidden;
  transform: translateY(-50%);
  transition:
    width 0.22s ease,
    transform 0.2s ease,
    box-shadow 0.2s ease,
    border-color 0.2s ease,
    background 0.2s ease;
}

.floating-trigger::before {
  content: "";
  position: absolute;
  inset: 0;
  background: var(--monitor-primary-soft);
  opacity: 0.42;
  pointer-events: none;
}

.floating-trigger:hover,
.floating-trigger:focus-visible {
  width: 180px;
  transform: translateY(-50%);
  border-color: var(--monitor-primary);
  box-shadow: var(--monitor-panel-shadow-hover);
  outline: none;
}

.trigger-icon-wrap {
  position: relative;
  z-index: 1;
  flex: 0 0 44px;
  width: 44px;
  height: 44px;
  border-radius: 14px;
  background: var(--monitor-primary-soft);
  color: var(--monitor-primary);
  box-shadow: inset 0 0 0 1px var(--monitor-border-accent);
}

.trigger-icon {
  font-size: 20px;
}

.trigger-copy {
  position: relative;
  z-index: 1;
  min-width: 0;
  overflow: hidden;
}

.trigger-title {
  font-size: 14px;
  font-weight: 700;
  line-height: 1;
  color: var(--font-main-color);
  white-space: nowrap;
  opacity: 0;
  transform: translateX(12px);
  transition:
    opacity 0.18s ease,
    transform 0.22s ease;
}

.floating-trigger:hover .trigger-title,
.floating-trigger:focus-visible .trigger-title {
  opacity: 1;
  transform: translateX(0);
}

.assistant-panel {
  position: fixed;
  display: flex;
  width: 520px;
  max-width: calc(100vw - 24px);
  min-height: 560px;
  animation: panel-enter 0.22s ease;
}

.assistant-panel.is-embedded {
  position: relative;
  display: flex;
  width: 100%;
  height: 100%;
  max-width: none;
  min-height: 0;
}

.pin-rail {
  width: 40px;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 82px;
}

.rail-button {
  width: 30px;
  height: 68px;
  border: 1px solid var(--monitor-border);
  border-right: none;
  border-radius: 16px 0 0 16px;
  background: var(--monitor-surface);
  color: var(--font-tip-color);
  box-shadow: var(--monitor-card-shadow);
  cursor: pointer;
  transition: all 0.2s ease;
}

.rail-button.active {
  color: var(--monitor-primary);
  border-color: var(--monitor-border-accent);
  background: var(--monitor-primary-soft);
}

.pin-icon {
  font-size: 15px;
  transform: rotate(45deg);
}

.panel-shell {
  flex: 1;
  display: flex;
  flex-direction: column;
  border: 1px solid var(--monitor-border);
  border-radius: 24px;
  background: var(--monitor-surface);
  box-shadow: none;
  overflow: hidden;
  backdrop-filter: blur(14px);
}

.panel-shell.embedded {
  flex: 0 0 380px;
  width: 380px;
  height: 100%;
  border-radius: 20px;
}

.panel-header {
  align-items: flex-start;
  gap: 14px;
  padding: 16px;
  background: var(--monitor-surface-soft);
  border-bottom: 1px solid var(--monitor-border);
  cursor: default;
}

.assistant-panel.is-pinned .panel-header {
  cursor: move;
}

.header-brand {
  align-items: flex-start;
  gap: 12px;
}

.brand-icon {
  width: 40px;
  height: 40px;
  border-radius: 14px;
  background: var(--monitor-primary-soft);
  color: var(--monitor-primary);
  font-size: 20px;
}

.header-copy {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.eyebrow {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--font-tip-color);
}

.header-actions {
  gap: 8px;
}

.action-button,
.close-button {
  width: 34px;
  height: 34px;
  border: 1px solid var(--monitor-border);
  border-radius: 12px;
  background: var(--monitor-surface);
  color: var(--font-text-color);
  cursor: pointer;
  transition: all 0.2s ease;
}

.action-button:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

.action-danger {
  color: color-mix(
    in srgb,
    var(--monitor-cloud) 74%,
    var(--font-text-color) 26%
  );
  border-color: color-mix(
    in srgb,
    var(--monitor-cloud) 24%,
    var(--monitor-border) 76%
  );
  background: color-mix(
    in srgb,
    var(--monitor-cloud-soft) 56%,
    var(--monitor-surface) 44%
  );
}

.action-button:hover:not(:disabled),
.close-button:hover {
  transform: translateY(-1px);
  border-color: var(--monitor-border-soft);
}

.action-icon.spinning {
  animation: spin 0.9s linear infinite;
}

.panel-scroll {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-height: 620px;
  padding: 12px 14px 16px;
  overflow-y: auto;
}

.panel-scroll.embedded {
  flex: 1;
  min-height: 0;
  max-height: none;
  gap: 10px;
  padding: 8px 10px 10px;
  overflow: auto;
}

.assistant-panel.is-embedded .panel-header {
  padding: 12px;
}

.assistant-panel.is-embedded .header-brand {
  gap: 8px;
}

.assistant-panel.is-embedded .brand-icon {
  width: 32px;
  height: 32px;
  font-size: 16px;
  border-radius: 10px;
}

.assistant-panel.is-embedded .header-copy {
  gap: 2px;
}

.assistant-panel.is-embedded .eyebrow {
  font-size: 10px;
}

.assistant-panel.is-embedded .panel-title {
  font-size: 14px;
}

.assistant-panel.is-embedded .action-button {
  width: 28px;
  height: 28px;
  border-radius: 10px;
}

.assistant-panel.is-embedded .header-actions {
  gap: 6px;
}

.assistant-panel.is-embedded .section-card {
  padding: 10px;
  border-radius: 16px;
}

.assistant-panel.is-embedded .local-card {
  padding: 12px 14px;
}

.assistant-panel.is-embedded .overall-card {
  grid-template-columns: 122px minmax(0, 1fr);
  gap: 8px;
}

.assistant-panel.is-embedded .overall-value {
  font-size: 24px;
}

.assistant-panel.is-embedded .compression-dashboard {
  gap: 10px;
}

.assistant-panel.is-embedded .compression-ring-card {
  padding: 6px 12px;
}

.assistant-panel.is-embedded .compression-ring-wrap {
  min-height: 135px;
}

.assistant-panel.is-embedded .section-heading {
  margin-bottom: 8px;
}

.assistant-panel.is-embedded .section-heading.compact-gap {
  margin-bottom: 6px;
}

.assistant-panel.is-embedded .section-title {
  font-size: 13px;
}

.assistant-panel.is-embedded .overall-copy {
  gap: 4px;
}

.assistant-panel.is-embedded .overall-stack {
  gap: 8px;
}

.assistant-panel.is-embedded .overall-legend {
  gap: 8px;
}

.assistant-panel.is-embedded .legend-chip {
  padding: 8px 10px;
  gap: 4px;
}

.assistant-panel.is-embedded .legend-chip-label {
  font-size: 10px;
}

.assistant-panel.is-embedded .legend-chip-value {
  font-size: 18px;
}

.section-card {
  padding: 14px;
  border-radius: 20px;
  background: var(--monitor-surface);
  border: 1px solid var(--monitor-border);
}

.section-heading {
  gap: 10px;
  margin-bottom: 12px;
}

.section-heading.compact-gap {
  margin-bottom: 10px;
}

.section-title {
  font-size: 14px;
  font-weight: 700;
  color: var(--font-main-color);
}

.cloud-panel {
  background: linear-gradient(
    180deg,
    color-mix(
        in srgb,
        var(--monitor-primary-soft-alt) 52%,
        var(--monitor-surface) 48%
      )
      0%,
    var(--monitor-surface) 100%
  );
}

.totals-label-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
}

.totals-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
}

.totals-dot.local {
  background: var(--monitor-primary);
}

.totals-dot.cloud {
  background: var(--monitor-cloud);
}

.totals-dot.overall {
  background: var(--color-primary-deep);
}

.totals-bar-track {
  height: 8px;
  overflow: hidden;
  border-radius: 999px;
  background: var(--monitor-track);
}

.totals-bar-fill {
  height: 100%;
  border-radius: inherit;
}

.totals-bar-fill.local {
  background: var(--monitor-primary);
}

.totals-bar-fill.cloud {
  background: var(--monitor-cloud);
}

.overall-card {
  display: grid;
  grid-template-columns: 156px minmax(0, 1fr);
  gap: 14px;
  padding: 14px;
  border-radius: 18px;
  border: 1px solid
    color-mix(
      in srgb,
      var(--monitor-border-soft) 64%,
      var(--monitor-border) 36%
    );
  background: linear-gradient(
    180deg,
    color-mix(
        in srgb,
        var(--monitor-surface) 84%,
        var(--monitor-primary-soft) 16%
      )
      0%,
    color-mix(
        in srgb,
        var(--monitor-surface) 90%,
        var(--monitor-cloud-soft) 10%
      )
      100%
  );
  box-shadow:
    0 8px 18px rgba(15, 23, 42, 0.05),
    0 2px 5px rgba(15, 23, 42, 0.035),
    inset 0 1px 0 rgba(255, 255, 255, 0.32);
}

.overall-card.enhanced {
  border-color: color-mix(
    in srgb,
    var(--monitor-border-soft) 76%,
    var(--monitor-border) 24%
  );
  box-shadow:
    0 12px 26px rgba(15, 23, 42, 0.05),
    0 2px 6px rgba(15, 23, 42, 0.03),
    inset 0 1px 0 rgba(255, 255, 255, 0.38);
}

.overall-copy {
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 6px;
}

.overall-label {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: var(--font-text-color);
  font-weight: 600;
}

.overall-value {
  font-size: 34px;
  font-weight: 700;
  line-height: 1;
  letter-spacing: -0.03em;
  color: var(--color-primary-deep);
}

.overall-stack {
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 14px;
}

.overall-stack-track {
  display: flex;
  height: 14px;
  overflow: hidden;
  border-radius: 999px;
  border: 1px solid
    color-mix(
      in srgb,
      var(--monitor-border-soft) 70%,
      var(--monitor-border) 30%
    );
  background: linear-gradient(
    90deg,
    color-mix(
        in srgb,
        var(--monitor-surface) 80%,
        var(--monitor-primary-soft) 20%
      )
      0%,
    color-mix(
        in srgb,
        var(--monitor-surface) 84%,
        var(--monitor-cloud-soft) 16%
      )
      100%
  );
  box-shadow: inset 0 1px 4px rgba(15, 23, 42, 0.08);
}

.overall-stack-track.enhanced {
  height: 14px;
  box-shadow:
    inset 0 1px 4px rgba(15, 23, 42, 0.08),
    0 1px 0 rgba(255, 255, 255, 0.48);
}

.overall-segment {
  height: 100%;
  border-radius: 0;
}

.overall-segment.local {
  border-radius: 999px 0 0 999px;
  background: linear-gradient(
    90deg,
    var(--monitor-primary) 0%,
    color-mix(in srgb, var(--monitor-primary) 72%, var(--color-white) 28%) 100%
  );
}

.overall-segment.cloud {
  border-radius: 0 999px 999px 0;
  background: linear-gradient(
    90deg,
    color-mix(
        in srgb,
        var(--monitor-cloud) 88%,
        var(--color-warning-strong) 12%
      )
      0%,
    color-mix(in srgb, var(--monitor-cloud) 72%, var(--color-white) 28%) 100%
  );
}

.overall-legend {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.legend-chip {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 6px;
  min-width: 0;
  padding: 12px 14px;
  border-radius: 16px;
  border: 1px solid transparent;
  font-size: 11px;
  font-weight: 600;
}

.legend-chip.local {
  color: var(--monitor-primary);
  background: color-mix(
    in srgb,
    var(--monitor-primary-soft) 78%,
    var(--monitor-surface) 22%
  );
  border-color: color-mix(
    in srgb,
    var(--monitor-primary) 22%,
    var(--monitor-border) 78%
  );
}

.legend-chip.cloud {
  color: var(--monitor-cloud);
  background: color-mix(
    in srgb,
    var(--monitor-cloud-soft) 86%,
    var(--monitor-surface) 14%
  );
  border-color: color-mix(
    in srgb,
    var(--monitor-cloud) 22%,
    var(--monitor-border) 78%
  );
}

.legend-chip-label {
  font-size: 11px;
  line-height: 1;
  opacity: 0.84;
}

.legend-chip-value {
  font-size: 24px;
  line-height: 1;
  font-weight: 700;
  letter-spacing: -0.03em;
}

.local-panel {
  background: linear-gradient(
    180deg,
    color-mix(
        in srgb,
        var(--monitor-primary-soft) 54%,
        var(--monitor-surface) 46%
      )
      0%,
    var(--monitor-surface) 100%
  );
}

.overall-panel {
  background: linear-gradient(
    180deg,
    color-mix(
        in srgb,
        var(--monitor-surface-soft) 72%,
        var(--monitor-surface) 28%
      )
      0%,
    var(--monitor-surface) 100%
  );
}

.local-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 14px 16px;
  border-radius: 18px;
  border: 1px solid
    color-mix(in srgb, var(--monitor-primary) 20%, var(--monitor-border) 80%);
  background: linear-gradient(
    180deg,
    color-mix(
        in srgb,
        var(--monitor-primary-soft) 76%,
        var(--monitor-surface) 24%
      )
      0%,
    color-mix(
        in srgb,
        var(--monitor-surface) 90%,
        var(--monitor-primary-soft) 10%
      )
      100%
  );
}

.local-card-head {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.local-card-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--font-text-color);
}

.local-card-value {
  flex-shrink: 0;
  font-size: 32px;
  line-height: 1;
  font-weight: 700;
  letter-spacing: -0.04em;
  color: var(--monitor-primary);
}

.local-card-track {
  height: 12px;
  overflow: hidden;
  border-radius: 999px;
  background: color-mix(
    in srgb,
    var(--monitor-primary-soft) 40%,
    var(--monitor-track) 60%
  );
}

.local-card-fill {
  height: 100%;
  border-radius: inherit;
  background: linear-gradient(
    90deg,
    var(--monitor-primary) 0%,
    color-mix(in srgb, var(--monitor-primary) 72%, var(--color-white) 28%) 100%
  );
}

.compression-dashboard {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.compression-metrics-row {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.metric-card {
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-width: 0;
  padding: 14px 16px;
  border-radius: 18px;
  border: 1px solid var(--monitor-border);
}

.metric-card-label {
  font-size: 13px;
  font-weight: 600;
}

.metric-card-label-sub {
  font-size: 11px;
  font-weight: 500;
  opacity: 0.72;
}

.metric-card-value {
  font-size: 32px;
  line-height: 1;
  font-weight: 700;
  letter-spacing: -0.04em;
}

.token-consumption-card {
  border-color: color-mix(
    in srgb,
    var(--monitor-cloud) 22%,
    var(--monitor-border) 78%
  );
  background: color-mix(
    in srgb,
    var(--monitor-cloud-soft) 76%,
    var(--monitor-surface) 24%
  );
  color: var(--monitor-cloud);
}

.saved-token-card {
  border-color: color-mix(
    in srgb,
    var(--monitor-success) 22%,
    var(--monitor-border) 78%
  );
  background: color-mix(
    in srgb,
    var(--monitor-success-soft) 82%,
    var(--monitor-surface) 18%
  );
  color: var(--monitor-success);
}

.compression-ring-card {
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 12px;
  min-width: 0;
  padding: 16px 14px;
  border-radius: 20px;
  border: 1px solid
    color-mix(in srgb, var(--monitor-success) 20%, var(--monitor-border) 80%);
  background: linear-gradient(
    180deg,
    color-mix(
        in srgb,
        var(--monitor-success-soft) 82%,
        var(--monitor-surface) 18%
      )
      0%,
    color-mix(
        in srgb,
        var(--monitor-surface) 92%,
        var(--monitor-success-soft) 8%
      )
      100%
  );
}

.compression-ring-card.inline-chart {
  display: grid;
  place-items: center;
  flex: 1 1 0;
  width: auto;
  min-width: 0;
  height: 100%;
  position: relative;
  .total-token {
    position: absolute;
    right: 16px;
    top: 16px;
    color: var(--font-tip-color);
    display: flex;
    font-size: 12px;
    .total-value {
      color: var(--font-main-color);
      padding-left: 4px;
    }
  }
}

.compression-ring-wrap {
  position: relative;
  display: grid;
  place-items: center;
  width: 120px;
  min-height: 160px;
  cursor: pointer;
  margin: 0 auto;
}

.compression-ring {
  width: 120px;
  height: 120px;
  transform: rotate(-90deg);
}

.compression-ring-track,
.compression-ring-progress {
  fill: none;
  stroke-width: 10;
}

.compression-ring-track {
  stroke: var(--monitor-cloud);
}

.compression-ring-progress {
  stroke: var(--monitor-success);
  stroke-linecap: round;
  transition: stroke-dashoffset 0.35s ease;
  filter: drop-shadow(0 6px 10px rgba(34, 197, 94, 0.18));
}

.compression-ring-center {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  text-align: center;
}

.compression-ring-value {
  font-size: 22px;
  line-height: 1;
  font-weight: 700;
  letter-spacing: -0.04em;
  color: var(--monitor-success);
}

.compression-ring-caption {
  max-width: 84px;
  font-size: 12px;
  font-weight: 600;
  line-height: 1.3;
  color: var(--font-main-color);
}

@keyframes panel-enter {
  from {
    opacity: 0;
    transform: translateY(16px) scale(0.98);
  }

  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }

  to {
    transform: rotate(360deg);
  }
}
</style>
