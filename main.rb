require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
#require 'pry'

set :sessions, true

helpers do
	def display_card(card)
		"#{card[0]} of #{card[1]}"
	end

	def hand_value(hand)
      cardpoints = {"2"=>2,"3"=>3,"4"=>4,"5"=>5,"6"=>6,"7"=>7,"8"=>8,"9"=>9,"10"=>10,"J"=>10,"Q"=>10,"K"=>10,"A"=>11}
      arr = hand.map{|card| card[0]}
      value = 0
      arr.each{|x| value += cardpoints[x]}
      arr.select{|x| x == "A"}.count.times{value -= 10 if value > 21}
      return value    
	end

	# returns 0 - No Blackjack, 1 - Player Blackjack, 2 - Dealer Blackjack, 3 - Both Blackjack
	def check_blackjack
		player_total = hand_value(session[:player_hand])
		dealer_total = hand_value(session[:dealer_hand])
		ret_val = 0
		if player_total == 21 && dealer_total == 21
			ret_val = 3
		elsif player_total == 21 && dealer_total << 21
			ret_val = 1
		elsif player_total < 21 && dealer_total == 21
			ret_val = 2
		end
		return ret_val
	end

	before do
		@show_buttons = true
		@dealer_hide = true
	end
end

get '/' do
	if session[:username].nil?
		redirect '/set_username' 
	else
		redirect 'game'
	end
end

get '/game' do
	cardnumbers = %w[2 3 4 5 6 7 8 9 10 J Q K A]
	suits = %w[Spades Hearts Diamonds Clubs]
	session[:deck] = cardnumbers.product(suits).shuffle!
	session[:player_hand] = []
	session[:dealer_hand] = []
	session[:player_hand] << session[:deck].pop
	session[:dealer_hand] << session[:deck].pop
	session[:player_hand] << session[:deck].pop
	session[:dealer_hand] << session[:deck].pop

	#session[:player_hand] = []
	#session[:player_hand] << ['A','Hearts']
	#session[:dealer_hand] << ['A','Clubs']
	#session[:player_hand] << ['10','Diamonds']
	#session[:dealer_hand] << ['10','Hearts']

	case check_blackjack
		when 1 then @success = "You have Blackjack!. You win." 
		when 2 then @success = "Dealer has blackjack!. You lose." 
		when 3 then @success = "You and the dealer have Blackjack. It's a push."
	end
	if check_blackjack > 0
		@show_buttons = false
		@dealer_hide = false
	end

	erb :game
end

post '/playerhit' do
	session[:player_hand] << session[:deck].pop
	if hand_value(session[:player_hand]) > 21
		@show_buttons = false
		@error = "#{session[:username]} busted!!!"
	elsif hand_value(session[:player_hand]) == 21
		redirect '/dealerplay'
	end

	erb :game
end

post '/playerstay' do
	redirect '/dealerplay'
end

get '/dealerplay' do

	# Dealer hits until he has 17 or higher
	while hand_value(session[:dealer_hand]) < 17
		session[:dealer_hand] << session[:deck].pop
	end

	# Check if dealer busted, else compare hands
	if hand_value(session[:dealer_hand]) > 21
		@success = "The dealer has busted. #{session[:username]} wins!"
	else
		case hand_value(session[:player_hand]) <=> hand_value(session[:dealer_hand])
			when 1 then @success = "#{session[:username]} wins!"
			when -1 then @error = "#{session[:username]} loses."
			when 0 then @success = "It's a push."
		end
	end

	@show_buttons = false
	@dealer_hide = false
	erb :game
end

get '/set_username' do
	erb :set_username
end

post '/set_username' do
	puts params[:username]
	if !params[:username].empty?
		session[:username] = params[:username]
		redirect '/game'
	else
		@error = "Must enter username!"
		erb :set_username
	end
end