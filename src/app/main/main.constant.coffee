angular.module 'oekoKostenrechner'
  .constant 'MAIN',
    SHORTENER_INTERFACE: '//white-shortener.herokuapp.com'
    SHORTENER_PROVIDER: 'goo.gl',
    CHART_TYPE: 'bar'
    CHART_YAXIS: 'TCO'
    CHART_XAXIS: 'mileage'
    FLOOR_YEAR: 2014
    CEIL_YEAR: 2025
    COLORS: do ->
      base = ["#71BF44", "#00B7DD", "#9245bf", "#bf5545", "#ffcc00"]
      colors = []
      colors.push c for c in base
      colors.push d3.rgb(c).darker(1).toString() for c in base
      colors.push d3.rgb(c).darker(2).toString() for c in base
      colors
