<template>
  <div style="width: 100%; height: 100%; background-color: #000;">
    <iframe id="vncFrame" ref="vncFrame" class="frame" frameBorder="0" v-show="true" scrolling="no"></iframe>
  </div>
</template>

<script>

export default {
  name: 'Vnc',
  components: {
  },
  data () {
    return {
      // stopped -> connected -> disconnected
      vncState: 'stopped',
      // toolbar
      config: {
        mode: 'vnc'
      },
      stateID: -1,
      // retry
      errorMessage: '',
      // vnc canvas size
      width: 0,
      height: 0,
      //
      stateErrorCount: 0,
      timerState: null
    }
  },
  created: function () {
    window.addEventListener('message', this.onMessage)
  },
  mounted: function () {
    this.update_status()
  },
  beforeDestroy: function () {
    clearTimeout(this.timerState)
    window.removeEventListener('message', this.onMessage)
  },
  methods: {
    update_status: async function () {
      const w = this.$refs.vncFrame.clientWidth
      const h = this.$refs.vncFrame.clientHeight
      const params = {
        'video': false,
        'id': this.stateID,
        'w': w,
        'h': h
      }
      try {
        const response = await this.$http.get('api/state', {params: params})
        const body = response.data
        if (body.code !== 200) {
          this.stateErrorCount += 1
          if (this.stateErrorCount > 10) {
            this.errorMessage = this.$t('serviceIsUnavailable')
            throw this.errorMessage
          }
        }

        // long polling
        this.stateID = body.data.id

        // adaptive resolution
        if (!body.data.config.fixedResolution && body.data.config.sizeChangedCount === 0) {
          const response = await this.$http.get('api/reset', {params: params})
          const body = response.data
          if (body.code !== 200) {
            this.stateErrorCount += 1
            if (this.stateErrorCount > 10) {
              this.errorMessage = this.$t('serviceIsUnavailable')
              throw this.errorMessage
            }
          }
        }

        if (this.vncState === 'stopped') {
          this.reconnect(false)
        }

        this.schedule_next_update_status()
      } catch (error) {
        this.stateErrorCount += 1
        if (this.stateErrorCount > 10) {
          this.errorMessage = this.$t('serviceIsUnavailable')
        } else {
          this.schedule_next_update_status()
        }
      }
    },
    schedule_next_update_status: function (afterMseconds = 1000) {
      if (this.timerState !== null) {
        return
      }
      this.timerState = setTimeout(() => {
        this.timerState = null
        this.update_status()
      }, afterMseconds)
    },
    reconnect: function (force = false) {
      this.errorMessage = ''
      let websockifyPath = 'websockify'
      if (force || this.vncState === 'stopped') {
        this.vncState = 'connecting'
        let hostname = window.location.hostname
        let port = window.location.port
        if (!port) {
          port = window.location.protocol[4] === 's' ? 443 : 80
        }
        let url = 'static/vnc.html?'
        url += 'autoconnect=1&'
        url += `host=${hostname}&port=${port}&`
        url += `path=${websockifyPath}&title=wellViz3D&`
        url += `logging=warn&`
        url += 'resize=scale&'
        url += 'reconnect=true&'
        url += 'reconnect_delay=1000'
        this.$refs.vncFrame.setAttribute('src', url)
      }
    },
    onMessage: function (message) {
      try {
        const data = JSON.parse(message.data)

        if (data.from === 'novnc' && data.state) {
            this.vncState = data.state
        }
      } catch (exc) {
        // SyntaxError if JSON pasrse error
      }
    }
  },
  computed: {
  },
  watch: {
  }
}
</script>

<style scoped>
body {
    margin: 0px;
}

iframe {
    border-width: 0px;
    width: 100%;
    height: 100%;
    position: absolute;
    left: 0px;
    top: 0px;
}
</style>
