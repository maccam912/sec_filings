// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"
import * as echarts from "echarts"

let hooks = {}
hooks.chart = {
    mounted() {
        var chart = echarts.init(this.el);
        // Draw the chart
        var option = {
            legend: {
                left: 'left',
                data: ['Earnings']
            },
            tooltip: {},
            xAxis: {
                data: []
            },
            yAxis: {name: 'Value', minorSplitLine: {show: true}, type: 'log'},
            //yAxis: {name: 'Value', min: 0, max: 1, minorSplitLine: {show: true}},
            series: [{
                name: 'Earnings',
                type: 'line',
                data: [],
                emphasis: {
                    focus: 'series'
                },
                smooth: true
            }]
        }

        option && chart.setOption(option)

        this.handleEvent("data", (data) => {
            var dates = []
            var values = []

            data.data.forEach((item) => {
                dates.push(item[0])
                values.push(item[1])
            })

            option.xAxis.data = dates.reverse()
            option.series[0].data = values.reverse()

            option.yAxis.max = Math.max(values)

            option && chart.setOption(option, true)
        })
    }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

