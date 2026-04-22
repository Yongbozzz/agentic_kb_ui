<template>
  <div class="home-layout">
    <section class="chat-pane">
      <Chatqna />
    </section>

    <button
      v-if="!isMonitorOpen"
      class="monitor-trigger"
      type="button"
      :title="t('monitor.title')"
      @click="openMonitor"
    >
      <span class="monitor-trigger-icon">
        <BarChartOutlined />
      </span>
    </button>

    <aside class="monitor-pane" :class="{ open: isMonitorOpen }">
      <TokenSaving embedded embedded-closable @close="closeMonitor" />
    </aside>
  </div>
</template>

<script setup lang="ts">
import { BarChartOutlined } from "@ant-design/icons-vue";
import { useI18n } from "vue-i18n";
import TokenSaving from "@/components/TokenSaving.vue";
import { Chatqna } from "./components/index";

const { t } = useI18n();
const isMonitorOpen = ref(false);

const openMonitor = () => {
  isMonitorOpen.value = true;
};

const closeMonitor = () => {
  isMonitorOpen.value = false;
};
</script>
<style scoped lang="less">
.home-layout {
  position: relative;
  height: 100%;
  min-height: 0;
  display: flex;
  padding: 12px;
  overflow: hidden;
  background: var(--bg-content-color);
}

.chat-pane,
.monitor-pane {
  min-height: 0;
  height: 100%;
}

.chat-pane {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  border-radius: 24px;
  background: var(--bg-content-color);
  box-shadow: 0 8px 24px var(--bg-box-shadow);
  transition: width 0.24s ease;
}

.monitor-pane {
  position: relative;
  width: 0;
  min-width: 0;
  opacity: 0;
  overflow: hidden;
  pointer-events: none;
  transition:
    width 0.24s ease,
    opacity 0.2s ease;
}

.monitor-pane.open {
  width: 380px;
  opacity: 1;
  pointer-events: auto;
  margin-left: 12px;
}

.monitor-trigger {
  position: absolute;
  top: 50%;
  right: 0;
  transform: translateY(-50%);
  z-index: 20;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 68px;
  padding: 0;
  border: 1px solid var(--monitor-trigger-border);
  border-right: none;
  border-radius: 16px 0 0 16px;
  background: linear-gradient(
    180deg,
    var(--monitor-trigger-bg-start) 0%,
    var(--monitor-trigger-bg-end) 100%
  );
  color: var(--monitor-trigger-color);
  box-shadow: var(--monitor-trigger-shadow);
  backdrop-filter: blur(14px);
  cursor: pointer;
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease,
    color 0.2s ease,
    border-color 0.2s ease,
    background 0.2s ease;
}

.monitor-trigger::before {
  content: "";
  position: absolute;
  left: 0;
  top: 12px;
  bottom: 12px;
  width: 3px;
  border-radius: 999px;
  background: linear-gradient(
    180deg,
    var(--monitor-trigger-accent-start) 0%,
    var(--monitor-trigger-accent-end) 100%
  );
  opacity: 0.9;
}

.monitor-trigger:hover {
  transform: translateY(-50%) translateX(-4px);
  border-color: var(--monitor-trigger-hover-border);
  background: linear-gradient(
    180deg,
    var(--monitor-trigger-hover-bg-start) 0%,
    var(--monitor-trigger-hover-bg-end) 100%
  );
  color: var(--monitor-trigger-hover-color);
  box-shadow: var(--monitor-trigger-hover-shadow);
}

.monitor-trigger-icon {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  padding-left: 3px;
  font-size: 18px;
  line-height: 1;
}

@media (max-width: 1280px) {
  .home-layout {
    padding-right: 12px;
  }

  .monitor-pane {
    position: absolute;
    top: 12px;
    right: 12px;
    bottom: 12px;
    width: min(380px, calc(100vw - 24px));
    transform: translateX(calc(100% + 12px));
    opacity: 0;
    pointer-events: none;
    transition:
      transform 0.24s ease,
      opacity 0.2s ease;
  }

  .monitor-pane.open {
    width: min(380px, calc(100vw - 24px));
    transform: translateX(0);
    opacity: 1;
    pointer-events: auto;
  }

  .monitor-trigger {
    right: 0;
  }
}

@media (max-width: 768px) {
  .monitor-trigger {
    width: 38px;
    height: 62px;
  }
}
</style>
