angular.module 'oekoKostenrechner'
  .controller 'MainChartController', ($scope, $state, $http, $window, processor, MAIN)->
    'ngInject'
    new class MainChartController
      constructor: ->
        $scope.$on '$stateChangeSuccess', =>
          # Change chart type according to the current param
          @type = $state.params.type or MAIN.CHART_TYPE
          @yAxis = if $state.is('main.chart.co2') then 'CO2' else MAIN.CHART_YAXIS
        # Shortcut to the vehicles created by the user
        @vehicles = $scope.$parent.main.vehicles
        # X-axis available options
        @xAxisOptions = do processor.getXAxisSettings
        # Get default X-axis value
        @xAxis     = MAIN.CHART_XAXIS
        @yAxis     = MAIN.CHART_YAXIS
        @type      = MAIN.CHART_TYPE
        # Always redirect to child state
        $state.go 'main.chart.tco', type: 'bar'
        # Generate a short permalink every time the vehicle array is upddated
        $scope.$watch 'chart.vehicles', @generateShortPermalink, yes
      print: -> do $window.print
      getXYears: ->
        y for y in [MAIN.FLOOR_YEAR..MAIN.CEIL_YEAR]
      getExplainer: ->
        # Bar chart always display the same explainer
        return 'expl5' if @type is 'bar'
        # For the other chart types we use the display helper
        display = processor.findDisplay xaxis: @xAxis, yaxis: @yAxis
        display?.explainer
      getPermalink: ->
        # Generate an absolute link to the chart
        $state.href 'main.permalink', { vehicles: do @getJsonVehicles }, absolute: yes
      getJsonVehicles: =>
        angular.toJson do @getSimplifiedVehicles
      # Turns vehicles list into a simplified one (that can be shared in the URL)
      getSimplifiedVehicles: =>
        names = do processor.getSettingsNames
        _.chain @vehicles
          .map (vehicle)->
            _.pick vehicle, names
          .value()
      generateShortPermalink: =>
        # Build request config
        config =
          cache: yes
          params: url: do @getPermalink
        # Temporary use the long permalink
        @permalink = config.params.url
        # We use an external service that received the view URL as param
        $http.get(MAIN.SHORTENER_INTERFACE, config).then (res)=>
          # Update the scope with the shortened url
          @permalink = res.data.id if res.data.id
