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
import * as ecStat from "echarts-stat"

let hooks = {}
hooks.chart = {
    mounted() {
        echarts.registerTransform(ecStat.transform.regression);

        var chart = echarts.init(this.el, null, {renderer: 'svg'});

        // Draw the chart
        var option = {
            legend: {
                left: 'left'
            },
            tooltip: {
                show: true,
            },
            xAxis: {
                type: 'time'
            },
            yAxis: {
                //type: 'log'
            },
            series: [{
                name: 'Earnings',
                type: 'line',
                datasetIndex: 0,
            }],
            dataset: [{
                source: []
            }]
        };

        chart.setOption(option)

        this.handleEvent("data", (data) => {
            var earnings = []
            data.data.forEach((item) => {
                earnings.push([item.date, item.earnings])
            })

            var option = chart.getOption()

            option.dataset[0].source = earnings

            chart.setOption(option)
        })
    }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: hooks})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
>> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

