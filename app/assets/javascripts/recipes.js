document.addEventListener("turbolinks:load", function() {
  "use strict";
  if ($("#ingredients_table_wrapper").length == 0) {
    $('#ingredients_table').DataTable({
      "paging": false,
      "order": [[ 0, "desc" ]]
    });
  }
  if ($("#recipes_table_wrapper").length == 0) {
    $('#recipes_table').DataTable({
      "pageLength": 25,
      "order": [[ 1, "desc" ]],
      "columnDefs": [
        { "width": "250px", "targets": 0 },
        { "width": "80px", "targets": 1 }
      ]
    });
  }
})

function displayIngredientPieChart(ingredients) {
  var co2_sum = ingredients.reduce(function(a, b) { return a + b.value; }, 0);
  const threshold = co2_sum * 0.03;
  
  data = ingredients.filter(item => item.value > threshold);
  data.sort((a, b) => b.value - a.value);
  
  small_items = ingredients.filter(item => item.value <= threshold);
  if (small_items.length > 0) {
    collected_value = { 
        label: `Other ingredients (${small_items.length} items)`,
        value: small_items.reduce((accumulator, item) => accumulator + item.value, 0), 
        color: "rgb(0,142,9)"
    }
    data.push(collected_value);
  }
  
  // set the dimensions and margins of the graph
  var width = 800
      height = 450
      margin = 40

  // The radius of the pieplot is half the width or half the height (smallest one). I subtract a bit of margin.
  var radius = Math.min(width, height) / 2;
  
  var svg = d3.select("svg")
      .attr("width", width)
      .attr("height", height)
    .append("g")
      .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");
  
  svg.append("g")
	  .attr("class", "slices");
  svg.append("g")
	  .attr("class", "labels");
  svg.append("g")
	  .attr("class", "lines");
	
  var pie = d3.pie()
    .sort(null)
	  .value(function(d) {
		  return d.value;
	  });
  
  var key = function(d){ return d.data.label; };
  
  var arc = d3.arc()
	  .outerRadius(radius * 0.8)
	  .innerRadius(radius * 0.4);

  var outerArc = d3.arc()
	  .innerRadius(radius * 0.9)
	  .outerRadius(radius * 0.9);
	
  // Build the pie chart: Basically, each part of the pie is a path that we build using the arc function.
  var slice = svg.select(".slices").selectAll("path.slice")
    .data(pie(data), key)
    .enter()
    .append('path')
    .attr('d', arc)
    .attr('fill', function(d){ return(d.data.color) })
    .attr("stroke", "black")
    .style("stroke-width", "2px")
    .style("opacity", 0.7)
  
  var text = svg.select(".labels").selectAll("text")
		.data(pie(data), key);

	text.enter()
		.append("text")
		.attr("dy", ".35em")
		.text(function(d) {
			return d.data.label;
		})
		.attr("transform", function(t) {
				var pos = outerArc.centroid(t);
				pos[0] = radius * (midAngle(t) < Math.PI ? 1 : -1);
				return "translate("+ pos +")";
		})
	  .style("text-anchor", function(t) {
				return midAngle(t) < Math.PI ? "start":"end";
		});
  
  function midAngle(d){
		return d.startAngle + (d.endAngle - d.startAngle)/2;
	}
	
	var polyline = svg.select(".lines").selectAll("polyline")
		.data(pie(data), key);
	
	polyline.enter()
		.append("polyline")
		.attr('fill', "none")
    .attr("stroke", "black")
    .style("stroke-width", "2px")
    .style("opacity", 0.3)
		.attr("points", function(t) {
				var pos = outerArc.centroid(t);
				pos[0] = radius * 0.95 * (midAngle(t) < Math.PI ? 1 : -1);
				return [arc.centroid(t), outerArc.centroid(t), pos];
		});
}
