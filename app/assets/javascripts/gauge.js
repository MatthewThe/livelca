// adapted from https://codepen.io/judy/pen/mPGmYq
function drawGauge(val, color) {
  var chart = {}
  chart.card = d3.select('.front');
  chart.data = [
    {
      value: val,
      max: 5.4 // 2x daily budget of 2.7 kg
    }
  ]
  var needle, barWidth, gauge, gaugeInset, degToRad, repaintGauge,
      height, margin, numSections, padRad, percToDeg, percToRad, 
      percent, radius, sectionIndx, svg, totalPercent, width;
  datapoint = chart.data[chart.data.length-1];
  percent = Math.min(1.0, datapoint.value / datapoint.max);
  
  numSections = 1;
  sectionPerc = 1 / numSections / 2;
  padRad = 0.01;
  gaugeInset = 10;

  // Orientation of gauge:
  totalPercent = .75;

  var el = chart.card.selectAll('.gauge').data(chart.data).enter().append('div').attr('class', 'gauge')
  
  margin = {
    right: 0,
    left: 0
  };
  
  if (!el.node()) { // turbolinks guard
    return
  }
  
  var svgWidth = el.node().offsetWidth
  width = svgWidth - margin.left - margin.right;
  height = el.node().offsetHeight;
  radius = width / 2;
  barWidth = 40 * width / 300;

  /*
    Utility methods 
  */
  percToDeg = function(perc) {return perc * 360}
  degToRad  =  function(deg) {return deg * Math.PI / 180}
  percToRad = function(perc) {return degToRad(percToDeg(perc))}

  // Create SVG element
  svg = el.append('svg').attr('width', svgWidth).attr('height', height);

  // Add layer for the panel
  gauge = svg.append('g').attr('transform', "translate(" + svgWidth / 2 + ", " + svgWidth / 2 + ")");
  gauge.append('path').attr('class', 'arc gauge-filled').attr('id', 'gauge-filled');
  gauge.append('path').attr('class', "arc gauge-empty");
  gauge.append('text')
    .attr('class', "value")
    .attr('x', '6')
    .attr('dy', '15')
    .append('textPath')
      .attr({'xlink:href': '#gauge-filled'})
  arc2 = d3.arc().outerRadius(radius - gaugeInset).innerRadius(radius - gaugeInset - barWidth)
  arc1 = d3.arc().outerRadius(radius - gaugeInset).innerRadius(radius - gaugeInset - barWidth)

  repaintGauge = function (perc) 
  {
    var next_start = totalPercent;
    arcStartRad = percToRad(next_start);
    arcEndRad = arcStartRad + percToRad(perc / 2);
    next_start += perc / 2;

    arc1.startAngle(arcStartRad).endAngle(arcEndRad);

    arcStartRad = percToRad(next_start);
    arcEndRad = arcStartRad + percToRad((1 - perc) / 2);

    arc2.startAngle(arcStartRad + padRad).endAngle(arcEndRad);

    gauge.select('text.value textpath').text(perc);
    gauge.select(".gauge-filled").attr('d', arc1).attr('fill', color);
    gauge.select(".gauge-empty").attr('d', arc2);
  }


  var Needle = (function() {

    /** 
      * Helper function that returns the `d` value
      * for moving the needle
    **/
    var recalcPointerPos = function(perc) {
      var centerX, centerY, leftX, leftY, rightX, rightY, thetaRad, topX, topY;
      thetaRad = percToRad(perc / 2);
      centerX = 0;
      centerY = 0;
      topX = centerX - this.len * Math.cos(thetaRad);
      topY = centerY - this.len * Math.sin(thetaRad);
      leftX = centerX - this.radius * Math.cos(thetaRad - Math.PI / 2);
      leftY = centerY - this.radius * Math.sin(thetaRad - Math.PI / 2);
      rightX = centerX - this.radius * Math.cos(thetaRad + Math.PI / 2);
      rightY = centerY - this.radius * Math.sin(thetaRad + Math.PI / 2);
      return "M " + leftX + " " + leftY + " L " + topX + " " + topY + " L " + rightX + " " + rightY;
    };

    function Needle(el) {
      this.el = el;
      this.len = width / 3;
      this.radius = this.len / 6;
    }

    Needle.prototype.render = function() {
      this.el.append('circle').attr('class', 'needle-center').attr('cx', 0).attr('cy', 0).attr('r', this.radius);
      return this.el.append('path').attr('class', 'needle').attr('d', recalcPointerPos.call(this, 0));
    };

    Needle.prototype.moveTo = function(perc) {
      var self,
          oldValue = this.perc || 0;

      this.perc = perc;
      self = this;

      // Reset pointer position
      this.el.transition().delay(100).ease(d3.easeQuad).duration(200).select('.needle').tween('reset-progress', function() {
        return function(percentOfPercent) {
          var progress = (1 - percentOfPercent) * oldValue;

          repaintGauge(progress);
          return d3.select(this).attr('d', recalcPointerPos.call(self, progress));
        };
      });

      this.el.transition().delay(300).ease(d3.easeBounce).duration(1500).select('.needle').tween('progress', function() {
        return function(percentOfPercent) {
          var progress = percentOfPercent * perc;

          repaintGauge(progress);
          return d3.select(this).attr('d', recalcPointerPos.call(self, progress));
        };
      });

    };

    return Needle;

  })();

  needle = new Needle(gauge);
  needle.render();

  needle.moveTo(percent);
}
