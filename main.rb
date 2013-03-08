require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
#require 'pry'

set :sessions, true

helpers do
	def init_deck
		cardnumbers = %w[2 3 4 5 6 7 8 9 10 J Q K A]
		suits = %w[Spades Hearts Diamonds Clubs]
		session[:deck] = (cardnumbers.product(suits)*1).shuffle!
	end

	def deal_card
		if session[:deck].size == 0
			init_deck
		end
		session[:deck].pop
	end

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

	def get_card_url(card)
		cardnum = case card[0]
			when 'J' then 'jack'
			when 'Q' then 'queen'
			when 'K' then 'king'
			when 'A' then 'ace'
			else card[0]
		end
		"<img src='/images/cards/#{card[1].downcase}_#{cardnum}.jpg' class='card_image'>"
	end

	# returns 0 - No Blackjack, 1 - Player Blackjack, 2 - Dealer Blackjack, 3 - Both Blackjack
	def check_blackjack
		player_total = hand_value(session[:player_hand])
		dealer_total = hand_value(session[:dealer_hand])
		ret_val = 0
		if player_total == 21 && dealer_total == 21
			session[:player_money] += bet
			ret_val = 3
		elsif player_total == 21 && dealer_total << 21
			session[:player_money] += 2.5 * bet
			ret_val = 1
		elsif player_total < 21 && dealer_total == 21
			ret_val = 2
		end
		ret_val
	end

	def evaluate_outcome

	end

	def get_user
		session[:username]
	end

	def bet
		session[:current_bet]
	end

	def display_bet
		'$' + '%.2f' % session[:current_bet]
	end

	def player_money
		session[:player_money]
	end

	def display_player_money
		'$' + '%.2f' % session[:player_money]
	end

	def player_hand
		session[:player_hand]
	end

	def dealer_hand
		session[:dealer_hand]
	end

	before do
		@show_hit_stay_btn = true
		@show_dealer_hit_btn = false
		@dealer_hide = true
	end
end

get '/' do
	if session[:username].nil?
		redirect '/start_new_game' 
	else
		redirect '/bet'
	end
end

get '/start_new_game' do
	#Deal and shuffle new deck
	session[:username] = nil
	session[:player_money] = 1000
	session[:current_bet] = 0
	init_deck
	redirect '/set_username'
end

get '/bet' do
	erb :place_bet
end

post '/game' do
	#binding.pry
	# validate bet
	session[:current_bet] = params[:bet_amt].to_f
	session[:player_money] -= bet
	

	#init_deck
	session[:player_hand] = []
	session[:dealer_hand] = []
	session[:player_hand] << deal_card
	session[:dealer_hand] << deal_card
	session[:player_hand] << deal_card
	session[:dealer_hand] << deal_card

	#session[:player_hand] = []
	#session[:player_hand] << ['A','Hearts']
	#session[:dealer_hand] << ['A','Clubs']
	#session[:player_hand] << ['10','Diamonds']
	#session[:dealer_hand] << ['10','Hearts']

	case check_blackjack
		when 1 then @success = "#{get_user} has Blackjack!. #{get_user} wins. #{get_user} now has #{display_player_money}." 
		when 2 then @error = "Dealer has blackjack!. #{get_user} loses. #{get_user} now has #{display_player_money}" 
		when 3 then @success = "#{get_user} and the dealer have Blackjack. It's a push. #{get_user} now has #{display_player_money}"
	end
	if check_blackjack > 0
		@show_hit_stay_btn = false
		@dealer_hide = false
	end

	erb :game
end

post '/playerhit' do
	session[:player_hand] << deal_card
	player_total = hand_value(session[:player_hand])
	if player_total > 21
		@show_hit_stay_btn = false
		@error = "#{get_user} busted!!! #{get_user} now has #{display_player_money}."
	elsif player_total == 21
		redirect '/dealerplay'
	end

	erb :game
end

post '/playerstay' do
	redirect '/dealerplay'
end

get '/dealerplay' do
	@show_hit_stay_btn = false
	@dealer_hide = false
	
	dealer_total = hand_value(dealer_hand)
	player_total = hand_value(player_hand)
	# Dealer hits if he has 17 or higher
	if dealer_total < 17
		@show_dealer_hit_btn = true
	# Check if dealer busted, else compare hands
	elsif dealer_total > 21
		session[:player_money] += 2 * bet
		@success = "The dealer has busted. #{get_user} wins! #{get_user} now has #{display_player_money}."
	else
		case player_total <=> dealer_total
			when 1
				session[:player_money] += 2 * bet
				@success = "#{get_user} wins! #{get_user} now has #{display_player_money}"
			when -1
				@error = "#{get_user} loses. #{get_user} now has #{display_player_money}"
			when 0
				session[:player_money] += bet
				@success = "It's a push. #{get_user} now has #{display_player_money}"
		end
	end

	erb :game
end

post '/dealerhit' do
	session[:dealer_hand] << deal_card
	redirect '/dealerplay'
end

get '/set_username' do
	erb :set_username
end

post '/set_username' do
	if params[:username].empty?
		@error = "Must enter username!"
		halt erb(:set_username)
	end

	session[:username] = params[:username]
	redirect '/bet'

end