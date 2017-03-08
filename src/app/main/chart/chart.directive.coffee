angular.module 'oekoKostenrechner'
  .directive 'chart', (DynamicInput, MAIN, $translate)->
    'ngInject'
    restrict: 'EA'
    scope:
      x: "="
      y: "="
      vehicles: "="
      type: "="
      processor: "="
    link: (scope, element, attr)->
      new class Chart
        TRANSITION_DURATION: 600
        DEFAULT_CONFIG: c3.chart.internal.fn.getDefaultConfig()
        bindWatchers: ->
          # Deep watch vehicles
          scope.$watch '[x, y, vehicles, type]', @updateChart, yes
          scope.$watch ( -> $translate.use() ), @updateChart
        updateChart: =>
          # New data columns
          cols = do @generateColumns
          # Columns to load or unload
          toUnload = _.difference _.map(@chart.data(), 'id'), _.map(cols, 0)
          # Load new data
          @chart.load
            type: scope.type
            columns: cols
            # Refresh colors and groups
            colors: do @generateColors
            # Previous data column (only the one that disapeared)
            unload: toUnload
            # Enhance the chart with d3
            done: @enhanceChart
            categories: _.map(do @getXValues, @formatTick)
          # Update axis
          @chart.axis.labels y: @generateYAxis(cols).label.text
          @chart.axis.min y: @generateYAxis(cols).min
          # Groups are loaded separetaly
          @chart.groups( @generateGroups cols )
          # Show or hide the legend
          do @chart.legend[ if @hasLegend() then 'show' else 'hide' ]

        getMinBarY: (cols)->
          values = [0, 0]
          for col in cols.slice(1)
            for i in [1..2]
              if col[i] < 0
                values[i - 1] += col[i]
          _.min values

        getTooltipContents: =>
          # Only spline chart has special display
          if scope.type isnt 'bar'
            if scope.y is 'TCO'
              arguments[0] = _.chain(arguments[0])
                # TCO display must only show mittel value
                .filter (datum)-> datum.id.indexOf('-mittel') > -1
                .each (datum)=>
                  # Find vehicle id from row id
                  id = datum.id.replace('-mittel', '')
                  vehicle = _.find scope.vehicles, id: id
                  # Extract vehicle name
                  datum.name = @getVehicleTranslation vehicle
                # Return the new values
                .value()
            else if scope.y is 'CO2'
              arguments[0] = _.chain(arguments[0])
                .each (datum)=>
                  # Find vehicle id from row id
                  id = datum.id.replace('vehicle-', '')
                  vehicle = _.find scope.vehicles, id: id
                  # Extract vehicle name
                  datum.name = @getVehicleTranslation vehicle
                # Return the new values
                .value()
          c3.chart.internal.fn.getTooltipContent.apply(@chart.internal, arguments)
        getVehicleDisplay: (vehicle)->
          if scope.type is 'bar'
            vehicle.TCO_simplified
          else
            display = scope.processor.findDisplay xaxis: scope.x, yaxis: scope.y
            # Extract display for this vehicle
            if display? then vehicle[display.name] else {}
        getVehicleTranslation: (vehicle)->
          $translate.instant "vehicle_name_striped",
            energy_type: $translate.instant vehicle.energy_type
            car_type: $translate.instant vehicle.car_type
        getXValues: =>
          if scope.type is 'bar'
            # One tick translated by vehicle
            @getVehicleTranslation vehicle for vehicle in scope.vehicles
          # Unkown range, we get it from the input value
          else
            setting = scope.processor.getSettingsBy(name: scope.x)[0]
            input = new DynamicInput setting
            input.getValues().range
        getVehicleValues: (vehicle, component)=>
          # Use xValues to fill empty tick
          xValues = do @getXValues
          # Find the value for this vehicle
          display = @getVehicleDisplay vehicle
          # Iterate over xValues' ticks
          for tick in xValues
            # This vehicle's values are divided into components
            if component?
              display[component][tick]?.total_cost or null
            else
              display[tick] or null
        getRefYear: =>
          refYear = null
          # Collect displays for each vehicle
          displays = ( @getVehicleDisplay vehicle for vehicle in scope.vehicles )
          # We have to find the first common year of the vehicle.
          # First we collect every years in the 'mittel' field of every vehicle.
          years = _.concat.apply(null, _.chain(displays).map('mittel').map(_.keys).value() )
          # Then we find the first year that appear twice
          # so we count the time every year appear.
          countByYear = _.chain(years).map(Number).sort().countBy().value()
          # Look into the count by year to find out.
          for year of countByYear
            # The current year appears as many times as there is vehicles
            if countByYear[year] is scope.vehicles.length
              # So we can take it as referencial
              refYear = year
              # Because the countBy is sorted, we stop asap
              break
          refYear
        generateColumns: =>
          series = [ _.concat(['x'], do @getXValues) ]
          # Spline chart is divided in 3 groups
          if scope.type is 'spline'
            # For each vehicle...
            for vehicle in scope.vehicles
              # Get value by components and year
              if scope.y is 'TCO'
                # Draw the 3 components of a vehicle
                for component in ['contra', 'pro', 'mittel']
                  values = @getVehicleValues vehicle, component
                  series.push(_.concat [vehicle.id + '-' + component], values)
              # Get value by year
              else
                values = @getVehicleValues vehicle
                # Draw a serie by vehicle
                series.push( _.concat ['vehicle-' + vehicle.id], values)
          # Bar chart...
          else
            refYear = do @getRefYear
            values  = {}
            # For this year, we collect variables for each vehicles
            for vehicle in scope.vehicles
              if display = @getVehicleDisplay(vehicle)
                # We enclose this part of the code to be able to
                # call it recursivly with variable within an object
                fn = (obj)->
                  # Now we collect values!
                  for n of obj
                    # Skip 'total' variables
                    continue if n.indexOf('total') is 0
                    # Literal value are taken instantaneously
                    if typeof obj[n] isnt 'object'
                      # Create the array where you'll stores the values for this variable
                      values[n] = [] unless values[n]?
                      values[n].push obj[n]
                    # Recursive lookup to flatten variable object
                    else fn obj[n]
                fn display
            # Create a serie line for each value
            series = series.concat( _.concat [n], values[n] for n of values)
            # Change series order
            order = ['x', 'net_cost', 'charging_infrastructure', 'fixed_costs', 'variable_costs', 'energy_costs']
            series = _.sortBy series, (s)-> order.indexOf(s[0])
            # Translate series names
            series = _.each series, (s)-> s[0] = $translate.instant(s[0])
          series
        formatTick: (d)=>
          # Format function according to the current chart type and x axis
          if scope.x is 'holding_time' or scope.type is 'bar'
            return d
          else
            return @formatNumber d
        formatNumber: (d)->
          # Available format method
          format = de: 'formatDeDe', en: 'formatEnUs'
          # Choose format according to the current language
          d3_format[ format[do $translate.use]  ].format(',') d
        generateXAxis: (cols)=>
          # Return a configuration objects
          type: 'categories'
          categories: do @getXValues
          tick:
            outer: false
            centered: yes
            culling:
              max: 10
            multiline: no
        generateYAxis: (cols)=>
          # Return a configuration objects
          tick:
            format: @formatNumber
          # Chart might be scale from 0 when they are not bar chart
          min: if scope.type is 'bar' then @getMinBarY(cols) else 0
          padding:
            bottom: 0
          label:
            position: 'outer-middle'
            text: $translate.instant(if scope.y is 'CO2' then 'kg_unit' else 'cost_unit')
        generateColors: (cols)=>
          colors = {}
          if scope.y is 'CO2'
            for v in scope.vehicles
              colors['vehicle-' + v.id] = v.color
          else if scope.y is 'TCO' and scope.type is 'spline'
            for v in scope.vehicles
              for c in ['contra', 'pro']
                colors[v.id + '-' + c] = v.color
              colors[v.id + '-mittel'] = d3.rgb(v.color).toString()
          else
            # Do we received data cols?
            cols = do @generateColumns unless cols?
            cols = angular.copy cols
            # One color by key
            for key, idx in _.map(cols.splice(1), 0)
              colors[key] = MAIN.COLORS[idx % MAIN.COLORS.length]
          colors
        generateGroups: (cols)=>
          if scope.type is 'bar'
            # Do we received data cols?
            cols = do @generateColumns unless cols?
            cols = angular.copy cols
            # Every dataset but 'x'
            [ _.map(cols.splice(1), 0) ]
          else
            []
        generateTooltip: =>
          show: true
          format:
            # Translate labels
            name: (v)-> $translate.instant v
            # Format numbers and add units
            value: (v)=>
              units = TCO: '€', CO2: ' kg CO₂'
              @formatNumber(v) + units[scope.y]
          # Special function to generate tooltip contents
          contents: @getTooltipContents
          # Fix tooltip position
          position: (data, width)=>
            maxLeft = element.width() - width
            top: 0, left: Math.min(@chart.internal.x(data[0].x), maxLeft)
        getLabelsFormat: (v, id)->
          # The id of the serie doesn't contain number
          v if not /\d/.test(id) and v > 0
        # Override the given function
        getYForText: (fn)->
          (points, d, textElement)->
            # Special Y for bar chart
            if scope.type is 'bar'
              box  = textElement.getBoundingClientRect()
              ypos = points[0][1] + (points[1][1] - points[0][1])/2
              ypos += box.height * 0.3
            # Call the original function
            else fn.call this, points, d, textElement
        hasLegend: -> scope.type is 'bar'
        hasTooltip: -> scope.type isnt 'bar'
        generateChart: =>
          columns = do @generateColumns
          window.c = @chart = c3.generate
            # Enhance the chart with d3
            onrendered: @enhanceChart
            bindto: element[0]
            size:
              height: 400
            interaction:
              enabled: yes
            padding:
              top: 20
            legend:
              position: 'right'
              show: @hasLegend()
            point:
              show: no
            line:
              connectNull: yes
            transition:
              duration: @TRANSITION_DURATION
            axis:
              x: @generateXAxis columns
              y: @generateYAxis columns
            grid:
              y:
                show: yes
            tooltip: do @generateTooltip
            data:
              labels:
                format: @getLabelsFormat
              selection:
                enabled: no
              x: 'x'
              type: scope.type
              columns: columns
              order: null
              # We generate those options according to the columns
              colors: @generateColors columns
              groups: @generateGroups columns
          # Overide default text position (to center labels)
          @chart.internal.getYForText = @getYForText @chart.internal.getYForText
        setupAreas: =>
          # First time we create areas
          if not @svg? or not @areasGroup?
            # Create a D3 elemnt
            @svg = d3.select(element[0]).select('svg')
            # Select the existing c3 chart
            @areasGroup = @svg.select '.c3-chart'
              # Create a group
              .insert 'g', '.c3-chart-lines'
              # Name it accordingly
              .attr 'class', 'd3-chart-areas'
        getArea: =>
          d3.svg.area()
            .x  (d)=> @chart.internal.x d.x
            .y0 (d)=> @chart.internal.y d.pro
            .y1 (d)=> @chart.internal.y d.contra
        enhanceChart: =>
          # Chart must be ready
          return unless @chart?
          # Prepare areas
          do @setupAreas
          # Disabled areas on bar chart
          vehicles = if scope.type is 'spline' and scope.y is 'TCO' then scope.vehicles else []
          # Within the same group... append a path
          areas = @areasGroup.selectAll('path.d3-chart-area').data vehicles
          areas.enter()
            .append 'path'
            # Name the path after the current group
            .attr 'class', (d)-> 'd3-chart-area d3-chart-area-' + d.id
          # And bind values to the group
          areas.datum( (d)=>
            datum = []
            # Value from chart's data
            pro    = (@chart.data d.id + "-pro")[0]?.values
            contra = (@chart.data d.id + "-contra")[0]?.values
            # Merge data into an array
            for i of pro
              # Without null values
              if pro[i].value?
                # Each spline of the array contains data for both groups
                # and the value on x
                datum.push pro: pro[i].value, contra: contra[i].value, x: pro[i].x
            datum
          # Colorize area using the current vehicle's color
          ).style
            fill: (d, i)-> vehicles[i].color
            opacity: 1
          # Update old elements
          areas.transition()
            .duration @TRANSITION_DURATION
            # Bind area object to the path
            .attr 'd', do @getArea
          # Remove useless element
          areas.exit()
            .transition()
              .duration @TRANSITION_DURATION
              .style 'opacity', 0
              .remove()

        constructor: ->
          # Bind watcher on scope attributes
          do @bindWatchers
          # Generate the chart
          do @generateChart
