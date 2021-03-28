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
            tooltip: {
                trigger: 'axis',
                axisPointer: {
                    type: 'cross'
                },
                position: function (pos, params, el, elRect, size) {
                    var obj = {top: 10};
                    obj[['left', 'right'][+(pos[0] < size.viewSize[0] / 2)]] = 30;
                    return obj;
                }
            },
            axisPointer: {
                link: {xAxisIndex: 'all'}
            },
            toolbox: {
                feature: {
                    dataZoom: {
                        yAxisIndex: false
                    },
                    brush: {
                        type: ['lineX', 'clear']
                    }
                }
            },
            dataZoom: [
                {
                    type: 'inside',
                    start: 0,
                    end: 100,
                    minValueSpan: 10
                },
                {
                    show: true,
                    type: 'slider',
                    bottom: 60,
                    start: 98,
                    end: 100,
                    minValueSpan: 10
                }
            ],
            grid: {
                containLabel: true
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
            const tags = ["Earnings", "Sales", "Operating Cash Flow", "CapEx"]

            var option = chart.getOption()
            option.series = []
            option.dataset = []

            for (var i = 0; i < tags.length; i++) {
                option.series.push({name: tags[i], type: 'scatter', datasetIndex: i, smooth: true})
                option.dataset.push({source: []})
            }

            for (var i = 0; i < data.data.length; i++) {
                const item = data.data[i]
                const t = item["tag"]
                console.log(t)
                const tag_idx = tags.indexOf(t)
                console.log(tag_idx)
                option.dataset[tag_idx].source.push([item["end_date"], item["value"]])
            }

            console.log(option.dataset)
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

