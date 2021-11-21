// adapted from https://www.freecodecamp.org/news/d3-and-canvas-in-3-steps-8505c8b27444/
function drawDailyBudget(val) {
  var data = [];
  if (val == 0) {
    val = 27.0;
  }
  var numBlocks = Math.ceil(2.7 / val / 0.1);
  d3.range(numBlocks).forEach(function(el) {
    data.push({ value: el }); 
  });
  
  var width = 280;
  
  var groupSpacing = 4; 
  var cellSpacing = 2; 
  var numGroupsPerRow = 2;
  var numBlocksPerGroup = 10;
  var numGroupsPerGrid = 10;
  
  var numBlocksPerRow = numGroupsPerRow * numBlocksPerGroup;
  var numGroupsPerRow = numBlocksPerRow / numBlocksPerGroup;
  var numBlocksPerGrid = numGroupsPerGrid * numBlocksPerGroup
  var cellSize = Math.floor((width - (numGroupsPerRow + 1) * groupSpacing) / numBlocksPerRow) - cellSpacing;
  
  var vertGroups = Math.floor(numBlocks / numBlocksPerGrid);
  var vertWithinGroups = Math.floor(numBlocks % numBlocksPerGrid / numBlocksPerRow) + 1;
  var height = groupSpacing * vertGroups + (cellSpacing + cellSize) * (vertWithinGroups + vertGroups * (numGroupsPerGrid / numGroupsPerRow));
  
  var maxBlocksPerRow = Math.min(numBlocks, numBlocksPerRow)
  var maxGroupsPerRow = Math.ceil(maxBlocksPerRow / numBlocksPerGroup)
  var trueWidth = maxBlocksPerRow * (cellSpacing + cellSize) + groupSpacing * (maxGroupsPerRow + 1)
  
  var el = d3.select('.daily-budget-chart')  
  
  var custom = el.append('svg').attr('width', trueWidth).attr('height', height);
  
  var join = custom.selectAll('rect.rect')
    .data(data);
    
  var enterSel = join.enter()
    .append('rect')
    .attr('class', 'rect')  
    .attr("x", function(d, i) {    
      var groupOffset = Math.floor(i / numBlocksPerGroup) % numGroupsPerRow;
      var withinGroupOffset = Math.floor(i % numBlocksPerGroup);
      return groupSpacing * groupOffset + (cellSpacing + cellSize) * (withinGroupOffset + groupOffset * numBlocksPerGroup); 
    })  
    .attr("y", function(d, i) {  
      var vertGroupOffset = Math.floor(i / numBlocksPerGrid);
      var vertWithinGroupOffset = Math.floor(i % numBlocksPerGrid / numBlocksPerRow);
      return groupSpacing * vertGroupOffset + (cellSpacing + cellSize) * (vertWithinGroupOffset + vertGroupOffset * (numGroupsPerGrid / numGroupsPerRow)); 
    })  
    .attr('width', 0)  
    .attr('height', 0);
  
  join.merge(enterSel)
    .transition()  
    .attr('width', cellSize)  
    .attr('height', cellSize)  
    .attr('fill', '#999');
}
