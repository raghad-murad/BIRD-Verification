<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta name="Author" content="<username>"> <meta name="GENERATOR" content="urg/version [en] (platform name) [urg]">
<title>Unified Coverage Report :: Group :: bird_pkg::bird_coverage::cg_backpressure</title>
<link type="text/css" rel="stylesheet" href="css/.urg.css">
<link type="text/css" rel="stylesheet" href="css/.layout.css">
<link type="text/css" rel="stylesheet" href="css/.breadcrumb.css">
<script type="text/javascript" src="js/.jquery.js"></script>
<script type="text/javascript" src="js/.jquery-ui.js"></script>
<script type="text/javascript" src="js/.sortable.js"></script>
<script type="text/javascript" src="js/.layout.js"></script>
<script type="text/javascript" src="js/.breadcrumb.js"></script>
<script type="text/javascript">
var layout, westLayout, centerLayout;
$(document).ready(function () {
  if ($("#north-bread-crumb")) {
    $("#north-bread-crumb").jBreadCrumb({easing:'swing'})
  }
  layout = $("body").layout({ 
    resizable: true,
    spacing_open: 4,
    spacing_closed: 4,
    north: {
      size: 76
    },
    south: {
      size: 45,
      initClosed: true
    },
    west: {
      size: 500,
      resizable: true,
      initClosed: false
    }
  });
  centerLayout = $('div.ui-layout-center').layout({
    north__paneSelector: ".ui-layout-center-inner-north",
    center__paneSelector: ".ui-layout-center-inner-center", 
    north__size: 50,
    spacing_open: 4,
    spacing_closed: 4
  });
});
</script>
</head>
<body onLoad="initPage();"><div class="ui-layout-north">
<div class="logo"></div>
<center class="pagetitle">Group : bird_pkg::bird_coverage::cg_backpressure</center>
<div align="center"><a href="dashboard.html" ><b>dashboard</b></a> | hierarchy | modlist | <a href="groups.html" ><b>groups</b></a> | <a href="tests.html" ><b>tests</b></a> | asserts</div>

</div>
<div class="ui-layout-west">
<div>
<div class=modhdr>
<br clear=all>
<span class=titlename>Group : <a href="#"  onclick="showContent('bird_pkg::bird_coverage::cg_backpressure')">bird_pkg::bird_coverage::cg_backpressure</a></span>
<br clear=all>
<table align=left>
<tr class="sortablehead">
<td><b>SCORE</b></td><td>WEIGHT</td><td>GOAL</td><td>AT LEAST</td><td>AUTO BIN MAX</td><td>PRINT MISSING</td></tr><tr>
<td class="s10 cl rt">100.00</td>
<td class="wht cl rt">1     </td>
<td class="wht cl rt">100   </td>
<td class="wht cl rt">1     </td>
<td class="wht cl rt">64    </td>
<td class="wht cl rt">64    </td>
</tr></table><br clear=all>
<br clear=all>
<span class=repname>Source File(s) : </span>
<br clear=all>
<a href="javascript:void(0);"  onclick="openSrcFile('/home/st53/BIRD_1212214/verif/env/bird_coverage.sv')">/home/st53/BIRD_1212214/verif/env/bird_coverage.sv</a><br clear=all>
<br clear=all>
</div>
<hr>
<br clear=all>
<span class=repname>Summary for Group   bird_pkg::bird_coverage::cg_backpressure
</span>
<br clear=all>
<br clear=all>
<table align=left>
<tr class="sortablehead">
<td class="alfsrt">CATEGORY</td><td>EXPECTED</td><td>UNCOVERED</td><td>COVERED</td><td>PERCENT</td></tr><tr class="s10">
<td><a href="#var_tbl_bird_pkg::bird_coverage::cg_backpressure" >Variables</a></td>
<td class="rt">5</td>
<td class="rt">0</td>
<td class="rt">5</td>
<td class="rt">100.00</td>
</tr></table><br clear=all>
<br clear=all>
<span class="repname" id="var_tbl_bird_pkg::bird_coverage::cg_backpressure">Variables for Group  bird_pkg::bird_coverage::cg_backpressure
</span>
<br clear=all>
<table align=left class="sortable">
<tr class="sortablehead">
<td class="alfsrt">VARIABLE</td><td>EXPECTED</td><td>UNCOVERED</td><td>COVERED</td><td>PERCENT</td><td>GOAL</td><td>WEIGHT</td><td>AT LEAST</td><td>AUTO BIN MAX</td><td>COMMENT</td></tr><tr class="s10">
<td><a href="#inst_tag_bird_pkg::bird_coverage::cg_backpressure.cp_local_bp"  onclick="checkLink(this)" target="detailFrame">cp_local_bp</a></td>
<td class="rt">2</td>
<td class="rt">0</td>
<td class="rt">2</td>
<td class="rt">100.00</td>
<td class="rt">100</td>
<td class="rt">1</td>
<td class="rt">1</td>
<td class="rt">0</td>
<td></td>
</tr><tr class="s10">
<td><a href="#inst_tag_bird_pkg::bird_coverage::cg_backpressure.cp_remote_bp"  onclick="checkLink(this)" target="detailFrame">cp_remote_bp</a></td>
<td class="rt">2</td>
<td class="rt">0</td>
<td class="rt">2</td>
<td class="rt">100.00</td>
<td class="rt">100</td>
<td class="rt">1</td>
<td class="rt">1</td>
<td class="rt">0</td>
<td></td>
</tr><tr class="s10">
<td><a href="#inst_tag_bird_pkg::bird_coverage::cg_backpressure.cp_in_bp"  onclick="checkLink(this)" target="detailFrame">cp_in_bp</a></td>
<td class="rt">1</td>
<td class="rt">0</td>
<td class="rt">1</td>
<td class="rt">100.00</td>
<td class="rt">100</td>
<td class="rt">1</td>
<td class="rt">1</td>
<td class="rt">0</td>
<td></td>
</tr></table><br clear=all>
</div>
</div>
<div class="ui-layout-center">
<div class="ui-layout-center-inner-center">
<div>
<br clear=all>
<a name="inst_tag_bird_pkg::bird_coverage::cg_backpressure.cp_local_bp"></a><span class="repname" id="inst_tag_bird_pkg::bird_coverage::cg_backpressure.cp_local_bp">Summary for Variable cp_local_bp</span>
<br clear=all>
<br clear=all>
<table align=left>
<tr class="sortablehead">
<td class="alfsrt">CATEGORY</td><td>EXPECTED</td><td>UNCOVERED</td><td>COVERED</td><td>PERCENT</td></tr><tr class="s10">
<td>User Defined Bins</td>
<td class="rt">2</td>
<td class="rt">0</td>
<td class="rt">2</td>
<td class="rt">100.00</td>
</tr></table><br clear=all>
<br clear=all>
<span class=repname>User Defined Bins for cp_local_bp</span>
<br clear=all>
<br clear=all>
<span class=repname>Bins</span>
<br clear=all>
<table align=left class="sortable">
<tr class="sortablehead">
<td class="alfsrt">NAME</td><td>COUNT</td><td>AT LEAST</td></tr><tr class="s10">
<td>no_backpressure</td>
<td class="rt">67570</td>
<td class="rt">1</td>
</tr><tr class="s10">
<td>backpressure_seen</td>
<td class="rt">16</td>
<td class="rt">1</td>
</tr></table><br clear=all>
<hr>
<br clear=all>
<a name="inst_tag_bird_pkg::bird_coverage::cg_backpressure.cp_remote_bp"></a><span class="repname" id="inst_tag_bird_pkg::bird_coverage::cg_backpressure.cp_remote_bp">Summary for Variable cp_remote_bp</span>
<br clear=all>
<br clear=all>
<table align=left>
<tr class="sortablehead">
<td class="alfsrt">CATEGORY</td><td>EXPECTED</td><td>UNCOVERED</td><td>COVERED</td><td>PERCENT</td></tr><tr class="s10">
<td>User Defined Bins</td>
<td class="rt">2</td>
<td class="rt">0</td>
<td class="rt">2</td>
<td class="rt">100.00</td>
</tr></table><br clear=all>
<br clear=all>
<span class=repname>User Defined Bins for cp_remote_bp</span>
<br clear=all>
<br clear=all>
<span class=repname>Bins</span>
<br clear=all>
<table align=left class="sortable">
<tr class="sortablehead">
<td class="alfsrt">NAME</td><td>COUNT</td><td>AT LEAST</td></tr><tr class="s10">
<td>no_backpressure</td>
<td class="rt">67576</td>
<td class="rt">1</td>
</tr><tr class="s10">
<td>backpressure_seen</td>
<td class="rt">10</td>
<td class="rt">1</td>
</tr></table><br clear=all>
<hr>
<br clear=all>
<a name="inst_tag_bird_pkg::bird_coverage::cg_backpressure.cp_in_bp"></a><span class="repname" id="inst_tag_bird_pkg::bird_coverage::cg_backpressure.cp_in_bp">Summary for Variable cp_in_bp</span>
<br clear=all>
<br clear=all>
<table align=left>
<tr class="sortablehead">
<td class="alfsrt">CATEGORY</td><td>EXPECTED</td><td>UNCOVERED</td><td>COVERED</td><td>PERCENT</td></tr><tr class="s10">
<td>User Defined Bins</td>
<td class="rt">1</td>
<td class="rt">0</td>
<td class="rt">1</td>
<td class="rt">100.00</td>
</tr></table><br clear=all>
<br clear=all>
<span class=repname>User Defined Bins for cp_in_bp</span>
<br clear=all>
<br clear=all>
<span class=repname>Excluded/Illegal bins</span>
<br clear=all>
<table align=left>
<tr class="sortablehead">
<td class="alfsrt">NAME</td><td>COUNT</td><td class="alfsrt">STATUS</td></tr><tr class="wht">
<td>backpressure_seen</td>
<td class="rt">0</td>
<td>Excluded</td>
</tr></table><br clear=all>
<br clear=all>
<span class=repname>Covered bins</span>
<br clear=all>
<table align=left>
<tr class="sortablehead">
<td class="alfsrt">NAME</td><td>COUNT</td><td>AT LEAST</td></tr><tr class="s10">
<td>no_backpressure</td>
<td class="rt">67586</td>
<td class="rt">1</td>
</tr></table><br clear=all>
</div>
</div>
<div class="ui-layout-center-inner-north">
<div id="center-bread-crumb" class="breadCrumb module urg-margin-bottom">
  <ul>
    <li>
      <a href="#inst_tag_bird_pkg::bird_coverage::cg_backpressure.cp_local_bp">Variable : cp_local_bp</a>    </li>
    <li>
      <a href="#inst_tag_bird_pkg::bird_coverage::cg_backpressure.cp_remote_bp">Variable : cp_remote_bp</a>    </li>
    <li>
      <a href="#inst_tag_bird_pkg::bird_coverage::cg_backpressure.cp_in_bp">Variable : cp_in_bp</a>    </li>
  </ul>
</div>
</div>
</div>
<div class="ui-layout-south">
<table align=center><tr><td class="s0 cl">0%</td>
<td class="s1 cl">10%</td>
<td class="s2 cl">20%</td>
<td class="s3 cl">30%</td>
<td class="s4 cl">40%</td>
<td class="s5 cl">50%</td>
<td class="s6 cl">60%</td>
<td class="s7 cl">70%</td>
<td class="s8 cl">80%</td>
<td class="s9 cl">90%</td>
<td class="s10 cl">100%</td></tr></table></div>
</body>
</html>
