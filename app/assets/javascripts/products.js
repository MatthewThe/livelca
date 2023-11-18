var updateWiki;

$(document).ready(function () {
  "use strict";
  if ($("#products_table_wrapper").length == 0) {
    $('#products_table').DataTable({
      "pageLength": 10,
      "stateSave": true,
      "deferRender": true,
      "order": [[2, "desc"]],
      "oLanguage": {
        "search": "Search:"
      },
      "bLengthChange": false,
      "ajax": {
        "url": '/product_table.json',
        "cache": true,
      },
      "language": {
        "loadingRecords": "Please wait - loading products..."
      },
      "columnDefs": [
        { "width": "200px", "targets": 0 },
        { "width": "100px", "targets": 1 },
        { "type": 'num', "width": "30px", "targets": 2 }
      ]
    });
  }
  if ($("#product_graph_container").length == 0) {
    if ($("#product_graph").length > 0) {
      $.ajax({
        url: '/product_graph_json.json',
        type: 'GET',
        success: function (data) {
          d3.select('svg').select("#product_graph_loader").remove();

          displayProductGraph(data.tree, data.products, $("#content").width(), $("#content").width());
        }
      });
    }
  }

  initSourceTable();
  initRecipesTable();

  if ($("#editor").length > 0) {
    const editor = new toastui.Editor({
      el: document.querySelector('#editor'),
      height: '500px',
      initialEditType: 'markdown',
      previewStyle: 'vertical',
      usageStatistics: false
    });

    $('#wiki-editor').hide();
    editor.setMarkdown($('#wiki-editor').val())
    updateWiki = function () {
      $('#wiki-editor').val(editor.getMarkdown());
    }
  }
})

function initSourceTable() {
  if ($("#sources_table_wrapper").length == 0) {
    $('#sources_table').DataTable({
      "pageLength": 25,
      "responsive": true,
      "order": [[5, "desc"]],
      "columnDefs": [
        { "targets": 0, "responsivePriority": 1 },
        { "targets": 1, "className": "none" }, // notes
        { "targets": 2, "responsivePriority": 1 },
        { "targets": 5, "responsivePriority": 2 }
      ]
    });
  }
}

function initRecipesTable() {
  if ($("#product_recipes_table_wrapper").length == 0) {
    $('#product_recipes_table').DataTable({
      "pageLength": 10,
      "responsive": true,
      "oLanguage": {
        "sSearch": "Filter:"
      },
      "ajax": {
        "url": '/product_recipe_table.json',
        "data": function (d) {
          d.id = window.location.pathname.split("/").pop();
        }
      },
      "language": {
        "loadingRecords": "Please wait - loading recipes..."
      }
    });
  }
}

function getNodeColor(node) {
  return node.co2_equiv_color
}

function updateLink(link) {
  link.attr("x1", function (d) { return fixna(d.source.x); })
    .attr("y1", function (d) { return fixna(d.source.y); })
    .attr("x2", function (d) { return fixna(d.target.x); })
    .attr("y2", function (d) { return fixna(d.target.y); });
}

function updateNode(node) {
  node.attr("transform", function (d) {
    return "translate(" + fixna(d.x) + "," + fixna(d.y) + ")";
  })
    .attr("text-anchor", function (d) {
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

function displayProductGraph(tree, products, minWidth, maxWidth = 1200) {
  var nodes = [], rels = [], names = [];
  products.forEach(function (res, idx) {
    var pr = {
      id: res.product.name,
      idx: idx,
      label: 'product',
      size: 10,
      co2_equiv_color: res.product.co2_equiv_color,
      co2_equiv: res.product.co2_equiv,
      link: "/products/" + res.product.to_param
    };
    var target = _.findIndex(names, { id: res.product.name });
    nodes.push(pr);
    names.push({ id: res.product.name });
  });

  Array.from(tree).forEach(function (res) {
    var target = _.findIndex(names, { id: res.product.name });
    target = nodes[target];

    res.product.subcategories.forEach(function (subcategory) {
      var source = _.findIndex(names, { id: subcategory.name });
      source = nodes[source];

      //console.log(source, target);
      rels.push({ source: source, target: target })
    })
  });

  //console.log("#graph nodes: " + nodes.length);
  //console.log("#graph rels: " + rels.length);

  const widthEstimate = Math.ceil(Math.sqrt(nodes.length)) * 60;
  const width = Math.min(maxWidth, Math.max(minWidth, widthEstimate));
  const height = Math.min(width, window.innerHeight - 150); // 85 height of the header + 65 height of footer

  const svg = d3.select('#product_graph')
    .attr('width', width)
    .attr('height', height)

  var label = {
    'nodes': [],
    'links': []
  };

  nodes.forEach(function (d, i) {
    label.nodes.push({ node: d });
  });

  const simulation = d3.forceSimulation(nodes)
    .force("charge", d3.forceManyBody().strength(-90))
    .force("center", d3.forceCenter(width / 2, height / 2))
    .force("x", d3.forceX(width / 2).strength(0.01))
    .force("y", d3.forceY(height / 2).strength(0.01 * width / height))
    .force("link", d3.forceLink(rels).distance(5).strength(0.1))
    .force('collision', d3.forceCollide().radius(35))
    .on("tick", ticked);

  const dragDrop = d3.drag()
    .on('start', function (node) {
      node.fx = node.x
      node.fy = node.y
    })
    .on('drag', function (node) {
      simulation.alphaTarget(0.7).restart()
      node.fx = d3.event.x
      node.fy = d3.event.y
    })
    .on('end', function (node) {
      if (!d3.event.active) {
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
    .enter()
    .append('g')
    .attr("id", function (d) { return "label-node-" + d.idx; })
    .style("cursor", "move")
    .call(dragDrop)
    .on("mouseenter", function (d) {
      highlightNodeText(d);
    })
    .on("mouseleave", function (d) {
      unhighlightNodeText(d);
    })

  nodeElements.append('circle')
    .attr('r', 30)
    .attr('fill', getNodeColor)


  var labelTextNode = nodeElements
    .append("text")
    .text(function (d) { return d.id; })
    .attr("class", "wrapme")
    .attr("x", 0)
    .attr("y", 4)
    .attr("width", 60)
    .attr("id", function (d) { return "label-node-text-" + d.idx; })
    .style("font-family", "Arial")
    .style("font-size", 12)
    .style("fill", "#fff")
    .attr("text-anchor", "middle")
    .style("cursor", "pointer")
    .on("click", function (d) {
      var url = "/products?utf8=✓&search=" + d.id;
      window.location = url;
    });

  function wrap(text) {
    text.each(function () {
      var text = d3.select(this);
      var words = text.text().split(/\s+/).reverse();
      var lineHeight = 16;
      var width = parseFloat(text.attr('width'));
      var y = parseFloat(text.attr('y'));
      var x = text.attr('x');
      var anchor = text.attr('text-anchor');

      var tspan = text.text(null)
        .append('tspan')
        .attr('x', x)
        .attr('y', y)
        .attr('text-anchor', anchor);
      var lineNumber = 0;
      var lineOffset = 0;
      var line = [];
      var word = words.pop();

      while (word) {
        line.push(word);
        tspan.text(line.join(' '));
        if (tspan.node().getComputedTextLength() > width && line.length > 1) {
          lineNumber += 1;
          lineOffset = 1
          line.pop();
          tspan.text(line.join(' '));
          line = [word];
          tspan = text.append('tspan')
            .attr('x', x)
            .attr('dy', y + lineOffset * lineHeight)
            .attr('text-anchor', anchor)
            .text(word);
        }
        word = words.pop();
      }
      text.attr('dy', fixna(-0.5 * lineNumber * lineHeight));
    });
  }
  d3.selectAll('.wrapme').call(wrap)

  labelTextNode.append("tspan")
    .attr("id", function (d) { return "label-node-emissions-" + d.idx; })
    .text(function (d) { return d3.format(".1f")(d.co2_equiv) + " CO2e/kg"; })
    .attr("x", 0)
    .attr("dx", 0)
    .attr("dy", function (d) { return 20 + d3.select("#label-node-" + d.idx).attr('dy'); })
    .attr("font-weight", "normal")
    .style("font-size", 12)
    .style("visibility", "hidden");

  function highlightNodeText(node) {
    var label = d3.select("#label-node-text-" + node.idx)
      .selectAll("tspan")
      .attr("font-weight", "bold")
      .style("font-size", 16)
      .style("opacity", 1.0);

    d3.select("#label-node-emissions-" + node.idx).style("visibility", "visible");

    var bbox = d3.select("#label-node-text-" + node.idx).node().getBBox();
    d3.select("#label-node-" + node.idx)
      .append("rect")
      .lower()
      .attr("id", function (d) { return "label-node-rect-" + d.idx; })
      .attr('fill', function (d) { return getNodeColor(d) })
      .attr('stroke', 'white')
      .attr("rx", 6)
      .attr("ry", 6)
      .attr("x", -1 * bbox.width / 2 - 7)
      .attr("y", -1 * bbox.height / 2 - 5)
      .attr('stroke-width', 1)
      .attr("stroke", "rgba(20, 20, 20, 0.3)")
      .style("width", bbox.width + 14)
      .style("height", bbox.height + 10)
      .style("cursor", "pointer")
      .on("click", function (d) {
        var url = "/products?utf8=✓&search=" + d.id;
        window.location = url;
      });

    d3.select("#label-node-text-" + node.idx).select("tspan").attr('y', -4);

    d3.select("#label-node-" + node.idx).raise();
    d3.select("#label-node-rect-" + node.idx).raise();
    d3.select("#label-node-text-" + node.idx).raise();

  }

  function unhighlightNodeText(node) {
    d3.select("#label-node-text-" + node.idx)
      .selectAll("tspan")
      .attr("font-weight", "normal")
      .attr('stroke-width', 0)
      .style("font-size", 12);

    d3.select("#label-node-text-" + node.idx)
      .select("tspan")
      .attr('y', 4)

    d3.select("#label-node-emissions-" + node.idx)
      .style("visibility", "hidden");

    d3.select("#label-node-rect-" + node.idx)
      .remove()
  }

  svg.call(
    d3.zoom()
      .scaleExtent([.1, 4])
      .on("zoom", function () { container.attr("transform", d3.event.transform); })
  );

  function ticked() {
    nodeElements.call(updateNode);
    linkElements.call(updateLink);
  }

  var decay = 0;
  simulation.alphaDecay(decay);
  simulation.tick(400);

  nodeElements.call(updateNode);
  linkElements.call(updateLink);

  decay = 1 - Math.pow(0.001, 1 / 100);

  simulation.alphaDecay(decay);
}
