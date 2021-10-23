$( document ).ready(function() {
  "use strict";
  if ($("#ingredients_table_wrapper").length == 0) {
    $('#ingredients_table').DataTable({
      "order": [[ 0, "desc" ]],
      "paging": false,
      "searching": false
    });
  }
  if ($("#recipes_table_wrapper").length == 0) {
    $('#recipes_table').DataTable({
      "pageLength": 25,
      "order": [[ 1, "desc" ]],
      "stateSave": true,
      "deferRender": true,
      "oLanguage": {
         "sSearch": "Filter:"
      },
      "ajax": {
        "url":'/recipe_table.json',
        "cache": true,
      },
      "language": {
         "loadingRecords": "Please wait - loading recipes..."
      },
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
  
  data = ingredients.filter(function(item) { return item.value > threshold });
  data.sort(function(a, b) { return b.value - a.value });
  
  small_items = ingredients.filter(function(item) { return item.value <= threshold && item.value > 0 });
  if (small_items.length > 0) {
    collected_value = { 
        label: "Other (" + small_items.length + " items)",
        value: small_items.reduce(function(accumulator, item) { return accumulator + item.value }, 0), 
        color: "rgb(0,142,9)"
    }
    data.push(collected_value);
  }
  
  // set the dimensions and margins of the graph
  var width = 1000 - 280
      height = 450
      margin = 40

  // The radius of the pieplot is half the width or half the height (smallest one). I subtract a bit of margin.
  var radius = Math.min(width, height) / 2;
  
  var svg_frame = d3.select("svg#ingredient_pie_chart")
      .attr("width", width)
      .attr("height", height)
  
  svg_frame.select('g').remove()
  
  var svg = svg_frame.append("g")
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
		.style("font-size", '13px')
		.style("font-family", "'DM Sans', sans-serif")
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

function initRecipe(numIngredients) {
  for (let i = 0; i < numIngredients; i++) {
    ingredients.push({})
  }
  calculateRecipeCO2e()
}

function allIngredientsInitialized() {
  var numIngredients = ingredients.length;
  var numInitializedIngredients = 0
  for (let i = 0; i < numIngredients; i++) {
    if (ingredients[i].value) {
      numInitializedIngredients += 1
    }
  }
  return numIngredients == numInitializedIngredients
}

function addIngredient() {
  var elem = $("#product-row-0").clone().appendTo("#product-rows");
  var idx = ingredients.length
  fixIds(elem, idx)
  elem.show()
  ingredients.push({})
  
  $('[id^="product-autocomplete"]').autocomplete({
    source: '/product_autocomplete_name',
    autoFocus: true,
    select: function (event, ui) { this.value = ui.item.label; this.onchange(); return true; }
  })
  
  updateIngredient(idx)
}

function removeIngredient(idx) {
  ingredients[idx] = {}
  var elem = $("#product-row-" + idx.toString())
  elem.hide()
  fixIds(elem, idx)
  updateIngredient(idx)
}

function fixIds(elem, cntr) {
  $(elem).find("[id]").add(elem).each(function() {
      this.id = this.id.replace(/\d+$/, "") + cntr;
      if (this.id.includes('weight')) {
        this.value = 0;
      } else {
        this.value = "";
      }
  })
}

function calculateRecipeCO2e() {
  var numIngredients = ingredients.length;
  var update = false
  for (let i = 0; i < numIngredients; i++) {
    var idx = i.toString()
    updateIngredient(idx, update)
  }
}

function updateIngredient(idx, update = true) {
  $.getJSON("ingredient_json", { 
      "idx" : idx,
      "weight" : $("#product_weight_" + idx).val(), 
      "name" : $("#product-autocomplete-" + idx).val(), 
      "servings" : $("#recipe_servings").val() 
  })
  .done(function( data ) {
    $("#product-co2e-" + data.idx).html(data.value).css('background-color', data.color)
    ingredients[data.idx] = data
    if (update || allIngredientsInitialized()) {
      updateRecipeTotalCO2e()
    }
  })
}

function updateRecipeTotalCO2e() {
  var totalCO2e = 0.0
  for (let i = 0; i < ingredients.length; i++) {
    if (ingredients[i].value) {
      totalCO2e += ingredients[i].value;
    }
  }
  var perServingCO2e = totalCO2e / parseFloat($("#recipe_servings").val());
  $(".recipe-co2e-per-serving").html(perServingCO2e.toFixed(2));
  $(".recipe-co2e-total").html(totalCO2e.toFixed(2));
  
  $.getJSON("recipe_color_json", { 
      "co2_equiv_kg" : perServingCO2e
  })
  .done(function( data ) {
    $(".gauge").remove();
    drawGauge(perServingCO2e, data.color);
    $("#co2_cell_gauge").css('background-color', data.color)
    $("#co2_cell_daily_budget").html((2.7 / perServingCO2e).toFixed(2)).css('background-color', data.color)
    
    displayIngredientPieChart(ingredients)
    
    $(".daily-budget-chart").children('svg').remove();
    drawDailyBudget(perServingCO2e);
  })
}

function saveAsPDF() {
  var source = document.body;
  source.classList.add('print');
  html2pdf(source, {
       filename: $(document).find("title").text(),
       image: { type: 'jpeg', quality: 1 },
       html2canvas: { scale: 2 },
       jsPDF: { unit: 'mm', format: 'A4', orientation: 'landscape', putOnlyUsedFonts: true }
  }).then(function(){
       source.classList.remove('print');
  });
}
