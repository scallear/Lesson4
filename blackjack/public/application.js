$(document).ready(function() {
  player_hits();
  player_stays();
  dealer_hits();
});

function player_hits() {
  $(document).on('click', '#hit_form input', function() {

    $.ajax({
      type:"POST",
      url:"/game/player/hit"
    }).done(function(msg) {
      alert("Player Hit");
      $('#game').replaceWith(msg);
    });
    
    return false;
  });
}

function player_stays() {
  $(document).on('click', '#stay_form input', function() {
    
    $.ajax({
      type:'POST',
      url: '/game/player/stay'
    }).done(function(msg) {
      alert("Player Stays");
      $('#game').replaceWith(msg);
    });
    
    return false;
  });
}

function dealer_hits() {
  $(document).on('click', '#dealer_hit input', function() {
    
    $.ajax({
      type:'POST',
      url: '/game/dealer/hit'
    }).done(function(msg){
      alert("Dealer Hit");
      $('#game').replaceWith(msg);
    });
    
    return false;
  });
}