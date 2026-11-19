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

          initProductGraphSearch(displayProductGraph(data));
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

/**
 * Product graph: collapsible tidy tree (d3 v5) of products and their
 * subcategories, coloured by CO2e. Clicking a node with hidden subcategories
 * loads and shows all of them, clicking it again hides them.
 *
 * The products graph page shows a radial tree. A product page (data with a
 * `current` node) shows a horizontal tree: its supercategories on the left,
 * its subcategories on the right.
 *
 * data: nested { name, co2_equiv, co2_equiv_color, to_param, children_count,
 * children?, current? } as built by Product#graph_tree. The radial tree's
 * centre is { virtual: true }, joining the root categories.
 *
 * Returns { reveal(productId) }, which opens the path to a product and
 * highlights it, as the current product of a product page is.
 */
const GRAPH = {
  ringDistance: 110,  // radial: radius per tree level
  leafSpacing: 14,    // radial: minimum arc length between neighbouring leaves
  rowHeight: 18,      // horizontal: height per leaf
  levelWidth: [60, 200], // horizontal: min and max distance between levels
  nodeRadius: 4.5,
  currentNodeRadius: 7,
  labelOffset: 8,
  fontSize: 11,
  padding: 10,
  duration: 300,
};

function displayProductGraph(data) {
  const root = d3.hierarchy(data);
  const current = root.descendants().find(function (d) { return d.data.current; });
  let highlighted = current;
  let highlightedPath = new Set(current ? current.ancestors() : []);
  const formatCo2 = d3.format('.2f');

  const svg = d3.select('#product_graph')
    .attr('width', '100%')
    .attr('font-family', 'sans-serif')
    .attr('font-size', GRAPH.fontSize);
  const container = svg.append('g').attr('id', 'product_graph_container');
  const gLink = container.append('g').attr('fill', 'none');
  const gNode = container.append('g');
  const tooltip = d3.select('body').selectAll('div.product-graph-tooltip').data([null])
    .join('div').attr('class', 'product-graph-tooltip');
  const shape = current ? horizontalTree(root, svgWidth) : radialTree(root);

  const zoom = d3.zoom().scaleExtent([0.2, 8]).on('zoom', function () {
    container.attr('transform', d3.event.transform);
  });
  // The wheel scrolls a product page's graph, so it zooms only with ctrl there.
  if (current) zoom.filter(function () { return d3.event.type === 'wheel' ? d3.event.ctrlKey : !d3.event.button; });
  svg.call(zoom).on('dblclick.zoom', null);

  root.x0 = 0;
  root.y0 = 0;
  const initialView = update(root, 0);

  // Bring the product into view when its graph scrolls.
  if (current) {
    const box = svg.node().parentNode;
    box.scrollTop = (current.x - initialView.y0) * initialView.scale - box.clientHeight / 2;
  }

  return { reveal: reveal };

  function update(source, duration) {
    const t = svg.transition().duration(duration);

    const node = gNode.selectAll('g').data(root.descendants(), function (d) { return d.data.to_param; });

    const nodeEnter = node.enter().append('g')
      .attr('transform', function (d) { return shape.transform(source.x0, source.y0, d); })
      .attr('opacity', 0)
      .on('mouseenter', showTooltip)
      .on('mousemove', moveTooltip)
      .on('mouseleave', hideTooltip);

    nodeEnter.append('circle')
      .attr('r', nodeRadius)
      .attr('fill', function (d) { return d.data.virtual ? '#bbb' : d.data.co2_equiv_color; })
      .attr('stroke-width', 1.5)
      .attr('aria-label', function (d) { return d.data.virtual ? null : d.data.name + ', ' + formatCo2(d.data.co2_equiv) + ' kg CO2e/kg'; })
      .on('click', toggle)
      .on('keydown', function (d) {
        if (d3.event.key !== 'Enter' && d3.event.key !== ' ') return;
        d3.event.preventDefault();
        toggle(d);
      });

    nodeEnter.append('a')
      .attr('href', function (d) { return d.data.virtual ? null : '/products/' + d.data.to_param; })
      .append('text')
      .attr('dy', '0.31em')
      .attr('fill', '#333')
      .attr('stroke', 'white')
      .attr('stroke-width', 3)
      .attr('paint-order', 'stroke')
      .text(function (d) { return d.data.virtual ? '' : d.data.name; });

    const nodeUpdate = node.merge(nodeEnter);

    // Labels are measured before the layout, which needs their widths.
    nodeUpdate.select('text')
      .attr('font-weight', function (d) { return d === highlighted ? 'bold' : null; })
      .each(function (d) { d.labelWidth = this.getComputedTextLength(); });

    shape.layout();
    nodeUpdate.transition(t)
      .attr('transform', function (d) { return shape.transform(d.x, d.y, d); })
      .attr('opacity', 1);

    nodeUpdate.select('circle')
      .attr('r', nodeRadius)
      .attr('stroke', function (d) { return hasHidden(d) ? '#333' : 'white'; })
      .attr('cursor', function (d) { return canToggle(d) ? 'pointer' : null; })
      .attr('tabindex', function (d) { return canToggle(d) ? 0 : null; })
      .attr('role', function (d) { return canToggle(d) ? 'button' : null; })
      .attr('aria-expanded', function (d) { return canToggle(d) ? !hasHidden(d) : null; });

    shape.positionLabels(nodeUpdate.select('text'));

    node.exit().transition(t).remove()
      .attr('transform', function (d) { return shape.transform(source.x, source.y, d); })
      .attr('opacity', 0);

    const link = gLink.selectAll('path').data(root.links(), function (d) { return d.target.data.to_param; });

    const linkEnter = link.enter().append('path')
      .attr('d', collapsedLink(source.x0, source.y0));

    link.merge(linkEnter)
      .attr('stroke', function (d) { return highlightedPath.has(d.target) ? '#555' : '#999'; })
      .attr('stroke-opacity', function (d) { return highlightedPath.has(d.target) ? 0.9 : 0.5; })
      .attr('stroke-width', function (d) { return highlightedPath.has(d.target) ? 2.5 : 1.2; })
      .transition(t)
      .attr('d', shape.link);

    link.exit().transition(t).remove()
      .attr('d', collapsedLink(source.x, source.y));

    const view = fitView();
    (duration ? svg.transition(t) : svg).attr('height', view.height).attr('viewBox', view.viewBox);

    root.eachBefore(function (d) {
      d.x0 = d.x;
      d.y0 = d.y;
    });
    return view;
  }

  // Fits the nodes and their labels into the SVG width, without enlarging them.
  function fitView() {
    const boxes = root.descendants().map(function (d) { return shape.bounds(d, nodeRadius(d)); });
    const x0 = d3.min(boxes, function (b) { return b[0]; }) - GRAPH.padding;
    const y0 = d3.min(boxes, function (b) { return b[1]; }) - GRAPH.padding;
    const w = d3.max(boxes, function (b) { return b[2]; }) + GRAPH.padding - x0;
    const h = d3.max(boxes, function (b) { return b[3]; }) + GRAPH.padding - y0;
    const width = svgWidth();
    const scale = Math.min(1, width / w, shape.maxHeight() / h);
    const viewWidth = width / scale;
    const box = [x0 - (viewWidth - w) / 2, y0, viewWidth, h];
    return { height: h * scale, y0: y0, scale: scale, box: box, viewBox: box.join(' ') };
  }

  function svgWidth() {
    return svg.node().getBoundingClientRect().width;
  }

  function nodeRadius(d) {
    if (d.data.virtual) return GRAPH.nodeRadius / 2;
    return d === highlighted ? GRAPH.currentNodeRadius : GRAPH.nodeRadius;
  }

  function canToggle(d) {
    return d.data.children_count > 0 && !d.data.virtual;
  }

  function addChild(parent, data) {
    const child = d3.hierarchy(data);
    child.parent = parent;
    child.depth = parent.depth + 1;
    return child;
  }

  // Opens the path from the centre to the product, adding only the nodes on it.
  function reveal(productId) {
    $.getJSON('/products/' + encodeURIComponent(productId) + '/path.json', function (path) {
      let source = null;

      function step(node, i) {
        if (i === path.length) return show(node, source || node);
        const onPath = function (c) { return c.data.to_param === path[i]; };
        const shown = (node.children || []).find(onPath);
        if (shown) return step(shown, i + 1);

        source = source || node;
        // Kept in _children (collapsed), which a click then shows in full.
        const loaded = (node._children || []).find(onPath);
        if (loaded) {
          node.children = (node.children || []).concat(loaded);
          return step(loaded, i + 1);
        }
        $.getJSON('/products/' + node.data.to_param + '/subcategories.json', function (subcategories) {
          const data = subcategories.find(function (c) { return c.to_param === path[i]; });
          if (!data) return;
          node.data.children_count = subcategories.length;
          const child = addChild(node, data);
          node.children = (node.children || []).concat(child);
          step(child, i + 1);
        });
      }

      step(root, root.data.virtual ? 0 : 1);
    });
  }

  function show(d, source) {
    highlighted = d;
    highlightedPath = new Set(d.ancestors());
    const view = update(source, GRAPH.duration);

    // Centre the product, at the scale where labels have their font size on screen.
    const p = shape.point(d);
    const k = 1 / view.scale;
    const cx = view.box[0] + view.box[2] / 2;
    const cy = view.box[1] + view.box[3] / 2;
    svg.transition().duration(750)
      .call(zoom.transform, d3.zoomIdentity.translate(cx - k * p[0], cy - k * p[1]).scale(k));
  }

  function toggle(d) {
    if (!canToggle(d)) return;
    hideTooltip();

    if (!hasHidden(d)) {
      d._children = d.children;
      d.children = null;
      return update(d, GRAPH.duration);
    }
    if (d._children && d._children.length === d.data.children_count) {
      d.children = d._children;
      d._children = null;
      return update(d, GRAPH.duration);
    }

    // Not loaded yet, or only partly (supercategories of a product page).
    $.getJSON('/products/' + d.data.to_param + '/subcategories.json', function (subcategories) {
      const loaded = new Map((d.children || []).concat(d._children || []).map(function (c) { return [c.data.to_param, c]; }));
      d.children = subcategories.map(function (data) {
        return loaded.get(data.to_param) || addChild(d, data);
      });
      d._children = null;
      d.data.children_count = subcategories.length;
      update(d, GRAPH.duration);
    });
  }

  function showTooltip(d) {
    if (d.data.virtual) return;
    tooltip.html('').style('display', 'block');
    tooltip.append('strong').text(d.data.name);
    tooltip.append('div').text(formatCo2(d.data.co2_equiv) + ' kg CO2e/kg');
    moveTooltip();
  }

  function moveTooltip() {
    tooltip.style('left', (d3.event.pageX + 12) + 'px').style('top', (d3.event.pageY + 12) + 'px');
  }

  function hideTooltip() {
    tooltip.style('display', 'none');
  }

  function collapsedLink(x, y) {
    return function () {
      const o = { x: x, y: y };
      return shape.link({ source: o, target: o });
    };
  }
}

// Search box of the products graph page: picking a product reveals it in the graph.
function initProductGraphSearch(graph) {
  $('#product-graph-search').autocomplete({
    source: '/product_autocomplete',
    autoFocus: true,
    response: function (event, ui) {
      if (ui.content.length === 0) ui.content.push({ label: 'No products found', value: '' });
    },
    focus: function () { return false; },
    select: function (event, ui) {
      if (ui.item.value) {
        this.value = ui.item.label;
        graph.reveal(ui.item.value);
      }
      return false;
    }
  });
}

function hasHidden(d) {
  return (d.children ? d.children.length : 0) < d.data.children_count;
}

/*
 * Tree shapes. In both, d.x is the position across the levels (angle or row)
 * and d.y the distance from the root, as d3.tree lays them out.
 * bounds(d, r) is the box [x0, y0, x1, y1] covering a node of radius r and its label.
 */

function radialTree(root) {
  // Labels of nodes with visible children point inwards, the others outwards.
  function outward(d) { return !d.children; }
  function onLeft(d) {
    const angle = ((d.x % (2 * Math.PI)) + 2 * Math.PI) % (2 * Math.PI);
    return angle > Math.PI;
  }

  return {
    link: d3.linkRadial().angle(function (d) { return d.x; }).radius(function (d) { return d.y; }),

    maxHeight: function () { return window.innerHeight - 150; },

    point: function (d) { return d.depth === 0 ? [0, 0] : d3.pointRadial(d.x, d.y); },

    // Leaves get leafSpacing on the outer ring, so a narrow tree is a fan
    // pointing up instead of a full circle.
    layout: function () {
      const maxDepth = d3.max(root.descendants(), function (d) { return d.depth; }) || 1;
      const leaves = root.leaves().length;
      const radius = Math.max(maxDepth * GRAPH.ringDistance, leaves * GRAPH.leafSpacing / (2 * Math.PI));
      const span = Math.min(2 * Math.PI, leaves * GRAPH.leafSpacing / radius);

      d3.tree()
        .size([span, radius])
        .separation(function (a, b) { return (a.parent === b.parent ? 1 : 2) / a.depth; })(root);
      root.each(function (d) { d.x -= span / 2; });
    },

    transform: function (x, y, d) {
      return d.depth === 0 ? null : 'rotate(' + (x * 180 / Math.PI - 90) + ') translate(' + y + ',0)';
    },

    positionLabels: function (text) {
      text
        .attr('x', function (d) { return d.depth === 0 ? 0 : (outward(d) === onLeft(d) ? -1 : 1) * GRAPH.labelOffset; })
        .attr('y', function (d) { return d.depth === 0 ? 2 * GRAPH.labelOffset : 0; })
        .attr('text-anchor', function (d) {
          if (d.depth === 0) return 'middle';
          return outward(d) === onLeft(d) ? 'end' : 'start';
        })
        .attr('transform', function (d) { return d.depth > 0 && onLeft(d) ? 'rotate(180)' : null; });
    },

    bounds: function (d) {
      if (d.depth === 0) return [-d.labelWidth / 2, 0, d.labelWidth / 2, 3 * GRAPH.labelOffset];
      const p = d3.pointRadial(d.x, d.y);
      const q = d3.pointRadial(d.x, d.y + (outward(d) ? GRAPH.labelOffset + d.labelWidth : 0));
      return [Math.min(p[0], q[0]), Math.min(p[1], q[1]), Math.max(p[0], q[0]), Math.max(p[1], q[1])];
    },
  };
}

function horizontalTree(root, width) {
  // Labels of nodes with visible children sit above them, clear of their links.
  function above(d) { return !!d.children; }

  return {
    link: d3.linkHorizontal().x(function (d) { return d.y; }).y(function (d) { return d.x; }),

    maxHeight: function () { return Infinity; }, // scrolls instead, see .product-graph-scroll

    point: function (d) { return [d.y, d.x]; },

    // The levels share the width left after the root's and the leaves' labels.
    layout: function () {
      const nodes = root.descendants();
      const maxDepth = d3.max(nodes, function (d) { return d.depth; }) || 1;
      const leafLabel = d3.max(nodes, function (d) { return above(d) ? 0 : GRAPH.labelOffset + d.labelWidth; });
      const free = width() - 2 * GRAPH.padding - root.labelWidth / 2 - leafLabel;
      const levelWidth = Math.max(GRAPH.levelWidth[0], Math.min(GRAPH.levelWidth[1], free / maxDepth));

      // An extra row next to nodes with a label above them.
      d3.tree()
        .nodeSize([GRAPH.rowHeight, levelWidth])
        .separation(function (a, b) { return above(a) || above(b) ? 2 : 1; })(root);
    },

    transform: function (x, y) {
      return 'translate(' + y + ',' + x + ')';
    },

    positionLabels: function (text) {
      text
        .attr('x', function (d) { return above(d) ? 0 : GRAPH.labelOffset; })
        .attr('y', function (d) { return above(d) ? -(GRAPH.currentNodeRadius + GRAPH.labelOffset) : 0; })
        .attr('text-anchor', function (d) { return above(d) ? 'middle' : 'start'; })
        .attr('transform', null);
    },

    bounds: function (d, r) {
      const h = GRAPH.rowHeight / 2;
      if (above(d)) return [d.y - d.labelWidth / 2, d.x - GRAPH.currentNodeRadius - GRAPH.labelOffset - h, d.y + d.labelWidth / 2, d.x + r];
      return [d.y - r, d.x - h, d.y + GRAPH.labelOffset + d.labelWidth, d.x + h];
    },
  };
}
