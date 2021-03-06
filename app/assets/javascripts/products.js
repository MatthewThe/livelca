var updateWiki;

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
        { "type": 'num', "width": "80px", "targets": 2 }
      ]
    });
  }
  if ($("#product_graph_container").length == 0) {
    if ($("#product_graph").length > 0) {
      $.ajax({
        url: '/product_graph_json.json',
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
    updateWiki = function() {
      $('#wiki-editor').val(editor.getMarkdown());
    }
  }
})

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
