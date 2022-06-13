var MARGIN = 48;
var NODE_RADIUS = 24;

var width;
var height;
var orderingDirection;
var hardEdgeDirection;
var layout;

function onResize() {
  var MD_BREAKPOINT = 768;
  var BELOW_MD_HEIGHT = 500;
  var orderingDirections = {
    ASCENDING_UPWARD: -1,
    ASCENDING_DOWNWARD: 1
  }

  var container = document.querySelector("aside div");

  width = container.parentElement.clientWidth;
  if (window.innerWidth >= MD_BREAKPOINT) {
    height = BELOW_MD_HEIGHT;
    orderingDirection = orderingDirections.ASCENDING_UPWARD;
  } else {
    height = container.clientHeight;
    orderingDirection = orderingDirections.ASCENDING_DOWNWARD;
  }
  hardEdgeDirection = window.innerWidth >= MD_BREAKPOINT ? "top" : "bottom";
  layout && gravityForce(layout).alpha(1).restart();
}

function drawGraph(graph) {
  var SIMULATION_LENGTH = 500;
  var CHARGE_STRENGTH = -640;
  var LINK_DISTANCE = 75;

  var svg = d3.select("#force").append("svg")
    .attr("width", "100%")
    .attr("height", height);
  // draw plot background
  svg.append("rect")
    .attr("width", "100%")
    .attr("height", height)
    .style("fill", "rgba(0,0,0,0)");
  // create an area within svg for plotting graph
  var plot = svg.append("g")
    .attr("id", "plot");
  layout = d3.forceSimulation()
    .nodes(graph.nodes)
    .alphaDecay(1 - Math.pow(0.001, 1 / SIMULATION_LENGTH))
    .force("charge", d3.forceManyBody().strength(CHARGE_STRENGTH))
    .force("links", d3.forceLink(graph.links).distance(LINK_DISTANCE))
    .force("linearization", linearizationForce)
    .force("ordering", orderingForce)
    .force("hard-edge-constraint", hardEdgeConstraint);
  gravityForce(layout).restart();
  drawLinks(graph.links);
  drawNodes(graph.nodes);
  // add ability to drag and update layout
  d3.selectAll(".node")
    .call(d3.drag()
      .on("start", dragStart)
      .on("drag", drag)
      .on("end", dragEnd));
  d3.selectAll("text")
    .call(d3.drag()
      .on("start", dragStart)
      .on("drag", drag)
      .on("end", dragEnd));
  // https://github.com/mbostock/d3/wiki/Force-Layout#wiki-on
  layout.on("tick", function() {
    d3.selectAll(".link")
      .attr("x1", function(d) {
        return d.source.x;
      })
      .attr("y1", function(d) {
        return d.source.y;
      })
      .attr("x2", function(d) {
        return d.target.x;
      })
      .attr("y2", function(d) {
        return d.target.y;
      });
    d3.selectAll(".node")
      .attr("cx", function(d) {
        return d.x;
      })
      .attr("cy", function(d) {
        return d.y;
      });
    d3.selectAll("text")
      .attr("x", function(d) {
        return d.x;
      })
      .attr("y", function(d) {
        return d.y;
      });
  });
}

// Called when a node starts being dragged
function dragStart(d) {
  d.fx = d3.event.x;
  d.fy = d3.event.y;
}

// Called while a node is dragged
function drag(d) {
  d.fx = d3.event.x;
  d.fy = d3.event.y;
  layout.restart();
}

// Called when a node stops being dragged
function dragEnd(d) {
  d.x = d.fx;
  d.y = d.fy;
  d.fx = d.fy = null;
  layout.alpha(1); // must reset alpha to have simulation settle again
  layout.restart();
}

// Apply force to nodes to arrange them in a line from top-right to
// bottom-left
function linearizationForce(alpha) {
  var FULL_STRENGTH = 6.4;
  var THRESHOLD = 80;
  var MEASURE_DIVISOR = 150;

  var strength = FULL_STRENGTH * alpha;

  layout.nodes().forEach(function(node) {
    var measureFromDiagonal = node.x + node.y - width;
    // ----- reduce jittering along the diagonal
    if (Math.abs(measureFromDiagonal) < THRESHOLD) {
      return;
    }
    var force = strength * (-measureFromDiagonal / MEASURE_DIVISOR);
    // -----
    node.vx += force;
    node.vy += force;
  });
}

// Apply ordering force to arrange numbers from near hailstone sequence tree
// root (1) at top to leaves at bottom. Order reverses in wider layouts
// (>= MD_BREAKPOINT px).
function orderingForce(alpha) {
  var FULL_STRENGTH = 12.8;

  var strength = FULL_STRENGTH * alpha;

  layout.nodes().forEach(function(node) {
    var diff = node.index - layout.nodes().length / 2;
    if (diff < 0) {
      node.vy -= orderingDirection * strength;
      return;
    }
    node.vy += orderingDirection * strength;
  });
}

function gravityForce(layout) {
  var GRAVITY_STRENGTH = 0.125;
  return layout.force(
      "gravity-x",
      d3.forceX(width / 2).strength(GRAVITY_STRENGTH))
    .force(
      "gravity-y",
      d3.forceY(height / 2).strength(GRAVITY_STRENGTH));
}

// Prevent nodes from being clipped at the bottom edge because users will
// notice (top edge when screen width >= MD_BREAKPOINT px)
function hardEdgeConstraint() {
  layout.nodes().forEach(function(node) {
    if (hardEdgeDirection === 'bottom' &&
      node.y + NODE_RADIUS >= height - MARGIN) {
      node.y = height - MARGIN - NODE_RADIUS;
      return;
    }
    if (hardEdgeDirection === 'top' && node.y - NODE_RADIUS <= MARGIN) {
      node.y = NODE_RADIUS + MARGIN;
    }
  });
}

// Draws nodes on plot
function drawNodes(nodes) {
  // https://github.com/mbostock/d3/wiki/Force-Layout#wiki-nodes
  var g = d3.select("#plot").selectAll(".node")
    .data(nodes)
    .enter()
    .append("g");
  g.append("circle")
    .attr("class", "node")
    .attr("id", function(d, i) {
      return d.name;
    })
    .attr("cx", function(d, i) {
      return d.x;
    })
    .attr("cy", function(d, i) {
      return d.y;
    })
    .attr("r", NODE_RADIUS)
  g.append("text").text(function(d, i) {
      return d.name;
    })
    .attr("x", function(d, i) {
      return d.x;
    })
    .attr("y", function(d, i) {
      return d.y;
    })
    .attr("text-anchor", "middle")
    .attr("dominant-baseline", "central");
}

// Draws edges between nodes
function drawLinks(links) {
  d3.select("#plot").selectAll(".link")
    .data(links)
    .enter()
    .append("line")
    .attr("class", "link")
    .attr("x1", function(d) {
      return d.source.x;
    })
    .attr("y1", function(d) {
      return d.source.y;
    })
    .attr("x2", function(d) {
      return d.target.x;
    })
    .attr("y2", function(d) {
      return d.target.y;
    })
    .style("stroke-dasharray", function(d, i) {
      return (d.value <= 1) ? "2, 2" : "none";
    });
}

window.addEventListener("resize", onResize);
onResize();
d3.json("/assets/collatz.json").then(drawGraph);
