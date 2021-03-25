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

        var chart = echarts.init(this.el, null, {renderer: 'canvas'});

        // Draw the chart
        var option = {
            legend: {
                left: 'left'
            },
            grid: {
                containLabel: true
            },
            tooltip: {
                show: true,
            },
            xAxis: {
                type: 'time',
                boundaryGap: false,
            },
            yAxis: {
                //type: 'log'
            },
            series: [],
            dataset: []
        };

        chart.setOption(option)

        this.handleEvent("data", (data) => {
            const tags = ["Earnings", "Sales", "Operating Cash Flow", "CapEx", "Free Cash Flow"]

            var option = chart.getOption()
            option.series = []
            option.dataset = []

            for (var i = 0; i < tags.length; i++) {
                option.series.push({name: tags[i], type: 'line', datasetIndex: i, smooth: true})
                option.dataset.push({source: []})
            }

            for (const key in data.data) {
                for (var i = 0; i < tags.length; i++) {
                    const tag = tags[i]
                    option.dataset[i].source.push([key, data.data[key][tag]])
                }
            }

            for (var i = 0; i < option.dataset.length; i++) {
                option.dataset[i].source = option.dataset[i].source.sort((a, b) => Date.parse(a[0]) - Date.parse(b[0]))
            }

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

