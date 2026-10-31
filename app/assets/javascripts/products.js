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

/**
 * Product graph: force-directed D3 (v5) graph of products and their subcategories.
 *
 * External dependencies (expected to be defined globally, as before):
 *   - d3 (v5, uses d3.event)
 *   - getNodeColor(node)
 *   - updateNode(selection), updateLink(selection)
 */

const GRAPH_CONFIG = {
  svgSelector: '#product_graph',
  containerId: 'product_graph_container',
  headerFooterHeight: 150,      // 85px header + 65px footer
  widthPerNodeColumn: 60,

  node: {
    radius: 30,
    collisionRadius: 35,
    labelWidth: 60,
    labelY: 4,
    labelYHighlighted: -4,
    fontFamily: 'Arial',
    fontSize: 12,
    fontSizeHighlighted: 16,
    lineHeight: 16,
    emissionsOffset: 20,
  },

  highlight: {
    paddingX: 7,
    paddingY: 5,
    cornerRadius: 6,
    stroke: 'rgba(20, 20, 20, 0.3)',
  },

  link: {
    stroke: 'rgba(50, 50, 50, 0.2)',
    strokeWidth: 2,
  },

  forces: {
    charge: -90,
    centerStrength: 0.01,
    linkDistance: 5,
    linkStrength: 0.1,
  },

  simulation: {
    warmupTicks: 400,
    dragAlphaTarget: 0.7,
    finalAlphaDecay: 1 - Math.pow(0.001, 1 / 100),
  },

  zoomExtent: [0.1, 4],
};

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

function displayProductGraph(tree, products, minWidth, maxWidth = 1200) {
  const nodes = buildNodes(products);
  const links = buildLinks(tree, nodes);
  const { width, height } = computeDimensions(nodes.length, minWidth, maxWidth);

  const svg = d3.select(GRAPH_CONFIG.svgSelector)
    .attr('width', width)
    .attr('height', height);

  const container = svg.append('g').attr('id', GRAPH_CONFIG.containerId);

  const simulation = createSimulation(nodes, links, width, height);

  const linkElements = renderLinks(container, links);
  const nodeElements = renderNodes(container, nodes, createDragBehavior(simulation));

  simulation.on('tick', function () {
    positionElements(nodeElements, linkElements);
  });

  enableZoom(svg, container);
  warmUpSimulation(simulation, nodeElements, linkElements);
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

function buildNodes(products) {
  return products.map(function (res, idx) {
    const product = res.product;
    return {
      id: product.name,
      idx: idx,
      label: 'product',
      size: 10,
      co2_equiv_color: product.co2_equiv_color,
      co2_equiv: product.co2_equiv,
      link: '/products/' + product.to_param,
    };
  });
}

function buildLinks(tree, nodes) {
  const nodesById = new Map(nodes.map(function (n) { return [n.id, n]; }));
  const links = [];

  Array.from(tree).forEach(function (res) {
    const target = nodesById.get(res.product.name);
    if (!target) return;

    res.product.subcategories.forEach(function (subcategory) {
      const source = nodesById.get(subcategory.name);
      if (source) links.push({ source: source, target: target });
    });
  });

  return links;
}

function computeDimensions(nodeCount, minWidth, maxWidth) {
  const widthEstimate = Math.ceil(Math.sqrt(nodeCount)) * GRAPH_CONFIG.widthPerNodeColumn;
  const width = Math.min(maxWidth, Math.max(minWidth, widthEstimate));
  const height = Math.min(width, window.innerHeight - GRAPH_CONFIG.headerFooterHeight);
  return { width: width, height: height };
}

// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

function createSimulation(nodes, links, width, height) {
  const f = GRAPH_CONFIG.forces;
  return d3.forceSimulation(nodes)
    .force('charge', d3.forceManyBody().strength(f.charge))
    .force('center', d3.forceCenter(width / 2, height / 2))
    .force('x', d3.forceX(width / 2).strength(f.centerStrength))
    .force('y', d3.forceY(height / 2).strength(f.centerStrength * width / height))
    .force('link', d3.forceLink(links).distance(f.linkDistance).strength(f.linkStrength))
    .force('collision', d3.forceCollide().radius(GRAPH_CONFIG.node.collisionRadius));
}

/** Runs the layout synchronously so the graph appears settled, then lets it cool down. */
function warmUpSimulation(simulation, nodeElements, linkElements) {
  simulation.alphaDecay(0);
  simulation.tick(GRAPH_CONFIG.simulation.warmupTicks);
  positionElements(nodeElements, linkElements);
  simulation.alphaDecay(GRAPH_CONFIG.simulation.finalAlphaDecay);
}

function positionElements(nodeElements, linkElements) {
  nodeElements.call(updateNode);
  linkElements.call(updateLink);
}

function createDragBehavior(simulation) {
  return d3.drag()
    .on('start', function (node) {
      node.fx = node.x;
      node.fy = node.y;
    })
    .on('drag', function (node) {
      simulation.alphaTarget(GRAPH_CONFIG.simulation.dragAlphaTarget).restart();
      node.fx = d3.event.x;
      node.fy = d3.event.y;
    })
    .on('end', function (node) {
      if (!d3.event.active) simulation.alphaTarget(0);
      node.fx = null;
      node.fy = null;
    });
}

function enableZoom(svg, container) {
  svg.call(
    d3.zoom()
      .scaleExtent(GRAPH_CONFIG.zoomExtent)
      .on('zoom', function () { container.attr('transform', d3.event.transform); })
  );
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

function renderLinks(container, links) {
  return container.append('g')
    .attr('class', 'links')
    .selectAll('line')
    .data(links)
    .enter()
    .append('line')
    .attr('stroke-width', GRAPH_CONFIG.link.strokeWidth)
    .attr('stroke', GRAPH_CONFIG.link.stroke);
}

function renderNodes(container, nodes, dragBehavior) {
  const nodeElements = container.append('g')
    .attr('class', 'nodes')
    .selectAll('g')
    .data(nodes)
    .enter()
    .append('g')
    .attr('id', function (d) { return nodeGroupId(d); })
    .style('cursor', 'move')
    .call(dragBehavior)
    .on('mouseenter', highlightNode)
    .on('mouseleave', unhighlightNode);

  nodeElements.append('circle')
    .attr('r', GRAPH_CONFIG.node.radius)
    .attr('fill', getNodeColor);

  renderNodeLabels(nodeElements);
  return nodeElements;
}

function renderNodeLabels(nodeElements) {
  const cfg = GRAPH_CONFIG.node;

  const labels = nodeElements.append('text')
    .attr('id', function (d) { return nodeTextId(d); })
    .attr('x', 0)
    .attr('y', cfg.labelY)
    .attr('text-anchor', 'middle')
    .style('font-family', cfg.fontFamily)
    .style('font-size', cfg.fontSize)
    .style('fill', '#fff')
    .style('cursor', 'pointer')
    .text(function (d) { return d.id; })
    .on('click', navigateToProductSearch);

  labels.each(function () {
    wrapText(d3.select(this), cfg.labelWidth, cfg.lineHeight);
  });

  appendEmissionsLabel(labels);
}

/** Splits the text of an SVG <text> element into centred <tspan> lines. */
function wrapText(textSelection, maxWidth, lineHeight) {
  const words = textSelection.text().split(/\s+/).filter(Boolean);
  const x = textSelection.attr('x');
  const y = textSelection.attr('y');

  textSelection.text(null);

  let tspan = textSelection.append('tspan').attr('x', x).attr('y', y);
  let line = [];
  let lineCount = 1;

  words.forEach(function (word) {
    line.push(word);
    tspan.text(line.join(' '));

    if (tspan.node().getComputedTextLength() > maxWidth && line.length > 1) {
      line.pop();
      tspan.text(line.join(' '));
      line = [word];
      tspan = textSelection.append('tspan')
        .attr('x', x)
        .attr('dy', lineHeight)
        .text(word);
      lineCount += 1;
    }
  });

  // Shift the block up so multi-line labels stay vertically centred.
  textSelection.select('tspan').attr('dy', -0.5 * (lineCount - 1) * lineHeight);
}

function appendEmissionsLabel(labels) {
  labels.append('tspan')
    .attr('id', function (d) { return nodeEmissionsId(d); })
    .attr('class', 'emissions')
    .attr('x', 0)
    .attr('dy', GRAPH_CONFIG.node.emissionsOffset)
    .attr('font-weight', 'normal')
    .style('font-size', GRAPH_CONFIG.node.fontSize)
    .style('visibility', 'hidden')
    .text(function (d) { return d3.format('.1f')(d.co2_equiv) + ' CO2e/kg'; });
}

// ---------------------------------------------------------------------------
// Hover highlighting
// ---------------------------------------------------------------------------

function highlightNode(node) {
  const cfg = GRAPH_CONFIG.node;
  const group = d3.select('#' + nodeGroupId(node));
  const text = d3.select('#' + nodeTextId(node));

  setLabelStyle(text, 'bold', cfg.fontSizeHighlighted, cfg.labelYHighlighted);
  setEmissionsVisible(node, true);

  removeHighlightRect(group);           // never stack more than one rect
  appendHighlightRect(group, text.node().getBBox());

  group.raise();                        // node above its neighbours
  text.raise();                         // label above the highlight rect
}

function unhighlightNode(node) {
  const cfg = GRAPH_CONFIG.node;
  const text = d3.select('#' + nodeTextId(node));

  setLabelStyle(text, 'normal', cfg.fontSize, cfg.labelY);
  setEmissionsVisible(node, false);
  removeHighlightRect(d3.select('#' + nodeGroupId(node)));
}

function setLabelStyle(text, fontWeight, fontSize, firstLineY) {
  text.selectAll('tspan')
    .attr('font-weight', fontWeight)
    .style('font-size', fontSize);
  text.select('tspan').attr('y', firstLineY);
}

function setEmissionsVisible(node, visible) {
  d3.select('#' + nodeEmissionsId(node))
    .style('visibility', visible ? 'visible' : 'hidden');
}

function appendHighlightRect(group, bbox) {
  const h = GRAPH_CONFIG.highlight;
  group.append('rect')
    .attr('class', 'highlight-rect')
    .attr('fill', getNodeColor)
    .attr('stroke', h.stroke)
    .attr('stroke-width', 1)
    .attr('rx', h.cornerRadius)
    .attr('ry', h.cornerRadius)
    .attr('x', -bbox.width / 2 - h.paddingX)
    .attr('y', -bbox.height / 2 - h.paddingY)
    .attr('width', bbox.width + 2 * h.paddingX)
    .attr('height', bbox.height + 2 * h.paddingY)
    .style('cursor', 'pointer')
    .on('click', navigateToProductSearch);
}

function removeHighlightRect(group) {
  group.selectAll('rect.highlight-rect').remove();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function navigateToProductSearch(node) {
  window.location = '/products?utf8=✓&search=' + encodeURIComponent(node.id);
}

function nodeGroupId(node) { return 'label-node-' + node.idx; }
function nodeTextId(node) { return 'label-node-text-' + node.idx; }
function nodeEmissionsId(node) { return 'label-node-emissions-' + node.idx; }