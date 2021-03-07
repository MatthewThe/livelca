$( document ).ready(function() {
  "use strict";
  if ($("#products_table_wrapper").length == 0) {
    $('#products_table').DataTable({
      "pageLength": 20,
      "lengthMenu": [[10, 20, 50], [10, 20, 50]],
      "stateSave": true,
      "deferRender": true,
      "order": [[ 2, "desc" ]],
      "oLanguage": {
         "sSearch": "Filter products:"
      },
      "ajax": {
        "url":'/product_table.json',
        "cache": true,
      },
      "language": {
         "loadingRecords": "Please wait - loading products..."
      },
      "columnDefs": [
        { "width": "250px", "targets": 0 },
        { "width": "80px", "targets": 1 },
        { "width": "80px", "targets": 2 }
      ]
    });
  }
  if ($("#product_graph_container").length == 0) {
    if ($("#product_graph").length > 0) {
      $.ajax({
        url: '/product_graph.json',
        type: 'GET',
        success: function(data) {
          d3.select('svg').select("#product_graph_loader").remove();
          
          displayProductGraph(data.tree, data.products, $("#content").width());
        }
      });
    }
  }
  if ($("#sources_table_wrapper").length == 0) {
    $('#sources_table').DataTable({
      "pageLength": 25,
      "stateSave": true,
      "columnDefs": [ 
        { "targets": 0, "orderable": false }
      ]
    });
  }
})

// adapted from https://codepen.io/judy/pen/mPGmYq
function drawGauge(val, color) {
  var chart = {}
  chart.card = d3.select('.front');
  chart.data = [
    {
      value: val,
      max: 5
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

function getNodeColor(node) {
  return node.co2_equiv
}

function updateLink(link) {
  link.attr("x1", function(d) { return fixna(d.source.x); })
      .attr("y1", function(d) { return fixna(d.source.y); })
      .attr("x2", function(d) { return fixna(d.target.x); })
      .attr("y2", function(d) { return fixna(d.target.y); });
}

function updateNode(node) {
  node.attr("transform", function(d) {
      return "translate(" + fixna(d.x) + "," + fixna(d.y) + ")";
  })
  .attr("text-anchor", function(d) {
    if (d.node) {
      if (d.x > d.node.x) {
        return "start"
      } else {
        return "end"
      }
    }
  });
}

function fixna(x) {
  if (isFinite(x)) return x;
  return 0;
}

function displayProductGraph(tree, products, minWidth) {
  var nodes = [], rels = [], names = [];
  products.forEach(function(res, idx) {
    var pr = {id: res.product.name, idx: idx, label: 'product', size: 10, co2_equiv: res.product.co2_equiv_color};
    var target = _.findIndex(names, {id: res.product.name});
    nodes.push(pr);
    names.push({id: res.product.name});
  });

  Array.from(tree).forEach(function(res) {
    var target = _.findIndex(names, {id: res.product.name});
    target = nodes[target];

    res.product.subcategories.forEach(function(subcategory) {
      var source = _.findIndex(names, {id: subcategory.name});
      source = nodes[source];
      
      //console.log(source, target);
      rels.push({source: source, target: target})
    })
  });
  
  //console.log("#graph nodes: " + nodes.length);
  //console.log("#graph rels: " + rels.length);

  const width = Math.max(Math.min(Math.ceil(Math.sqrt(nodes.length)) * 60, 960), minWidth);
  const height = width;

  const svg = d3.select('#product_graph')
    .attr('width', width)
    .attr('height', height)

  var label = {
      'nodes': [],
      'links': []
  };

  nodes.forEach(function(d, i) {
      label.nodes.push({node: d});
      label.nodes.push({node: d});
      label.links.push({
          source: i * 2,
          target: i * 2 + 1
      });
      //d.label = label.nodes.slice(-1)[0];
  });

  var labelLayout = d3.forceSimulation(label.nodes)
      .force("charge", d3.forceManyBody().strength(-10))
      .force("link", d3.forceLink(label.links).distance(5).strength(2));

  const simulation = d3.forceSimulation(nodes)
      .force("charge", d3.forceManyBody().strength(-30))
      .force("center", d3.forceCenter(width / 2, height / 2))
      .force("x", d3.forceX(width / 2).strength(0.01))
      .force("y", d3.forceY(height / 2).strength(0.01))
      .force("link", d3.forceLink(rels).distance(5).strength(0.1))
      .force('collision', d3.forceCollide().radius(20))
      .on("tick", ticked);

  const dragDrop = d3.drag()
    .on('start', function(node) {
      node.fx = node.x
      node.fy = node.y
    })
    .on('drag', function(node) {
      labelLayout.alphaTarget(0.7).restart()
      simulation.alphaTarget(0.7).restart()
      node.fx = d3.event.x
      node.fy = d3.event.y
    })
    .on('end', function(node) {
      if (!d3.event.active) {
        labelLayout.alphaTarget(0)
        simulation.alphaTarget(0)
      }
      node.fx = null
      node.fy = null
    })

  var container = svg.append("g").attr("id", "product_graph_container");

  var linkElements = container.append("g")
    .attr("class", "links")
    .selectAll("line")
    .data(rels)
    .enter().append("line")
      .attr("stroke-width", 2)
	    .attr("stroke", "rgba(50, 50, 50, 0.2)")

  var nodeElements = container.append('g')
    .selectAll('circle')
    .data(nodes)
    .enter().append('circle')
      .attr('r', 10)
      .attr('fill', getNodeColor)
      .call(dragDrop)
      .on("mouseover", function(d) {
        d3.select("#label-node-" + d.idx).attr("font-weight", "bold");
      })
      .on("mouseout", function(d) {
        d3.select("#label-node-" + d.idx).attr("font-weight", "normal");
      });
  
  var labelNode = container.append("g").attr("class", "labelNodes")
      .selectAll("text")
      .data(label.nodes)
      .enter().append("text")
        .attr("id", function(d, i) { return i % 2 == 0 ? "" : "label-node-" + d.node.idx; })
        .text(function(d, i) { return i % 2 == 0 ? "" : d.node.id; })
        .style("opacity", "0.6")
        .style("font-family", "Arial")
        .style("font-size", 12)
        .style("pointer-events", "none"); // to prevent mouseover/drag capture

  svg.call(
      d3.zoom()
          .scaleExtent([.1, 4])
          .on("zoom", function() { container.attr("transform", d3.event.transform); })
  );
      
  function ticked() {
    nodeElements.call(updateNode);
    linkElements.call(updateLink);
    
    labelNode.each(function(d, i) {
        if (i % 2 == 0) {
            d.x = d.node.x;
            d.y = d.node.y;
        } else {
            var b = this.getBBox();

            var diffX = d.x - d.node.x;
            var diffY = d.y - d.node.y;

            var dist = Math.sqrt(diffX * diffX + diffY * diffY);

            var shiftX = b.width * (diffX - dist) / (dist * 2);
            shiftX = Math.max(-b.width, Math.min(0, shiftX));
            var shiftY = 16;
            this.setAttribute("transform", "translate(" + shiftX + "," + shiftY + ")");
        }
    });
    labelNode.call(updateNode);
  }
  
  var decay = 0;
  simulation.alphaDecay(decay);
  
  simulation.tick(400);
  
  nodeElements.call(updateNode);
  linkElements.call(updateLink);
  labelNode.each(function(d, i) {
      d.x = d.node.x;
      d.y = d.node.y;
  });
  labelNode.call(updateNode);
  
  decay = 1 - Math.pow(0.001, 1 / 100);
  
  simulation.alphaDecay(decay);
  labelLayout.alphaDecay(decay);
}
