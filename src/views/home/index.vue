<template>
  <div class="home-layout">
    <section class="chat-pane">
      <Chatqna />
    </section>
    <aside class="monitor-pane">
      <TokenSaving embedded />
    </aside>
  </div>
</template>

<script setup lang="ts">
import TokenSaving from "@/components/TokenSaving.vue";
import { Chatqna } from "./components/index";
</script>
<style scoped lang="less">
.home-layout {
  height: 100%;
  min-height: 0;
  display: grid;
  grid-template-columns: minmax(0, 1fr) 380px;
  gap: 12px;
  padding: 12px;
  align-items: stretch;
  overflow: hidden;
  background: var(--bg-content-color);
}

.chat-pane,
.monitor-pane {
  min-height: 0;
  height: 100%;
}

.chat-pane {
  overflow: hidden;
  border-radius: 24px;
  background: var(--bg-content-color);
  box-shadow: 0 8px 24px var(--bg-box-shadow);
}

.monitor-pane {
  display: flex;
  overflow: hidden;
}

@media (max-width: 1280px) {
  .home-layout {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
