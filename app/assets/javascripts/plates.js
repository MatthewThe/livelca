// adapted from https://www.freecodecamp.org/news/d3-and-canvas-in-3-steps-8505c8b27444/
function drawDailyBudgetPlates(val) {
  var data = [];
  if (val == 0) {
    val = 2.7;
  }
  var numBlocks = Math.ceil(2.7 / val);
  d3.range(numBlocks).forEach(function(el) {
    data.push({ value: el }); 
  });
  
  var width = 280;
  
  var groupSpacing = 10; 
  var cellSpacing = 1; 
  var numGroupsPerRow = 2;
  var numBlocksPerGroup = 3;
  var numGroupsPerGrid = 4;
  
  var numBlocksPerRow = numGroupsPerRow * numBlocksPerGroup;
  var numGroupsPerRow = numBlocksPerRow / numBlocksPerGroup;
  var numBlocksPerGrid = numGroupsPerGrid * numBlocksPerGroup
  var cellSize = Math.floor((width - (numGroupsPerRow + 1) * groupSpacing) / numBlocksPerRow) - cellSpacing;
  var outerRadius = cellSize / 2;
  
  var vertGroups = Math.floor(numBlocks / numBlocksPerGrid);
  var vertWithinGroups = Math.floor(((numBlocks % numBlocksPerGrid) - 1) / numBlocksPerRow) + 1;
  var height = groupSpacing * vertGroups + (cellSpacing + cellSize) * (vertWithinGroups + vertGroups * (numGroupsPerGrid / numGroupsPerRow));
  
  var maxBlocksPerRow = Math.min(numBlocks, numBlocksPerRow)
  var maxGroupsPerRow = Math.ceil(maxBlocksPerRow / numBlocksPerGroup)
  var trueWidth = maxBlocksPerRow * (cellSpacing + cellSize) + groupSpacing * (maxGroupsPerRow - 1)
  
  var el = d3.select('.daily-budget-chart')  
  
  var custom = el.append('svg').attr('width', trueWidth).attr('height', height);
  
  var join = custom.selectAll('rect.plate')
    .data(data);
    
  function compute_translation(d, i) {    
      var groupOffset = Math.floor(i / numBlocksPerGroup) % numGroupsPerRow;
      var withinGroupOffset = Math.floor(i % numBlocksPerGroup);
      var x = groupSpacing * groupOffset + (cellSpacing + cellSize) * (withinGroupOffset + groupOffset * numBlocksPerGroup) + outerRadius;
      
      var vertGroupOffset = Math.floor(i / numBlocksPerGrid);
      var vertWithinGroupOffset = Math.floor(i % numBlocksPerGrid / numBlocksPerRow);
      var y = groupSpacing * vertGroupOffset + (cellSpacing + cellSize) * (vertWithinGroupOffset + vertGroupOffset * (numGroupsPerGrid / numGroupsPerRow)) + outerRadius; 
      return "translate(" + x + "," + y + ")"; 
  }
  
  function compute_angle(d, i) {
      return 2*Math.PI*(1 - Math.min((2.7 / val) - i, 1));
  }
  var enterSel = join.enter()
    .append("path")
    .attr("transform", compute_translation)
    .attr("d", d3.arc()
      .innerRadius( 0 )
      .outerRadius( outerRadius )
      .startAngle( compute_angle )
      .endAngle( Math.PI*2 )
      )
    .attr('stroke', 'none')
    .attr('fill', 'rgb(210,210,210)');
  
  var enterSel2 = join.enter()
    .append("path")
    .attr("transform", compute_translation)
    .attr("d", d3.arc()
      .innerRadius( 0 )
      .outerRadius( outerRadius * 29 / 30 )
      .startAngle( compute_angle )
      .endAngle( Math.PI*2 )
      )
    .attr('stroke', 'white')
    .attr('fill', 'rgb(180,180,180)');
  
  var enterSel3 = join.enter()
    .append("path")
    .attr("transform", compute_translation)
    .attr("d", d3.arc()
      .innerRadius( 0 )
      .outerRadius( outerRadius * 2 / 3 )
      .startAngle( compute_angle )
      .endAngle( Math.PI*2 )
      )
    .attr('stroke', 'white')
    .attr('fill', 'rgb(210,210,210)');
}
