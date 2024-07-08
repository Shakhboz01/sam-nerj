$(document).on('turbo:load', function() {
  $("input").focus(function() {
    $(this).select();
  });
  $(function(){$(".datepicker").datepicker({dateFormat: 'dd-mm-yy'})});
  $('#searchInput').focus()
});
