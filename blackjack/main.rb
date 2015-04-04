require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'random_string' 

BLACKJACK = 21
DEALER_HIT = 17

helpers do
  def calculate_total(cards)
    arr = cards.map{|element| element[1]}

    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    arr.select{|element| element == 'A'}.count.times do
      break if total <= BLACKJACK
      total -= 10
    end

    total
  end
  
  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end
  
    value = case card[1]
      when 'J' then 'jack'
      when 'Q' then 'queen'
      when 'K' then 'king'
      when 'A' then 'ace'
      else card[1]
    end
    
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card'>"
  end
  
  def end_game
    if session[:player_money] <= 0
      session[:loser] = @loser
      redirect '/game_over'
    elsif session[:player_money] >= 500
      session[:winner] = @winner
      redirect '/game_win'
    end
  end
  
  def winner!(msg)
    session[:player_money] += session[:player_bet]
    @play_again = true
    @hit_or_stay_buttons = false
    @winner = "#{session[:player_name]} wins! #{msg} #{session[:player_name]} now has $#{session[:player_money]}."
    end_game
  end
  
  def loser!(msg)
    session[:player_money] -= session[:player_bet]
    @play_again = true
    @hit_or_stay_buttons = false
    @loser = "#{session[:player_name]} loses. #{msg} #{session[:player_name]} now has $#{session[:player_money]}."
    end_game
  end
  
  def tie!(msg)
    @play_again = true
    @hit_or_stay_buttons = false
    @winner = "#{session[:player_name]} and the dealer tied! #{msg} #{session[:player_name]} now has $#{session[:player_money]}."
  end
  
end

before do
  @hit_or_stay_buttons = true
end

get '/'do
  erb :intro
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  session[:player_money] = 200
  redirect '/place_bet'
end

get '/place_bet' do
  session[:place_bet] = nil
    erb :place_bet
end

post '/place_bet' do
  if params[:player_bet].to_i == 0 || params[:player_bet].nil?
    @error = "You must place a bet!"
    halt erb(:place_bet)
  elsif params[:player_bet].to_i > session[:player_money]
    @error = "You cannot bet more than you have!"
    halt erb(:place_bet)
  else
    session[:player_bet] = params[:player_bet].to_i
    redirect '/game'
  end
end

get '/game' do
  SUITS = ['D', 'H', 'C', 'S']
  FACES = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = SUITS.product(FACES).shuffle!
  
  session[:player_cards] = []
  
  session[:dealer_cards] = []
  
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop

  if calculate_total(session[:player_cards]) == BLACKJACK
    winner!("#{session[:player_name]} hit balckjack.")
    @hit_or_stay_buttons = false
  end
  
  session[:turn] = "player"
  
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  
  if player_total == BLACKJACK
    winner!("#{session[:player_name]} hit balckjack.")
  elsif player_total > BLACKJACK
    loser!("#{session[:player_name]} busted with #{player_total}.")
  end
  
  erb :game, layout: false
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} chose to stay"
  @hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @hit_or_stay_buttons = false
  
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK
    loser!("The dealer hit blackjack.")
  elsif dealer_total > BLACKJACK
    winner!("The dealer busted with #{dealer_total}.")
  elsif dealer_total >= DEALER_HIT
    redirect '/game/compare'
  else
    @dealer_hit_button = true
  end
    
  erb :game, layout: false
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @hit_or_stay_buttons = false
  
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  
  if player_total < dealer_total
    loser!("Final Score: #{session[:player_name]} - #{player_total}, Dealer - #{dealer_total}")
  elsif dealer_total < player_total
    winner!("Final Score: #{session[:player_name]} - #{player_total}, Dealer - #{dealer_total}")
  else
    tie!("Final Score: All - #{player_total}")
  end
  
  erb :game, layout: false
end

get '/game_over' do
  erb :game_over
end

get '/game_win' do
  erb :game_win
end