require 'json'
require 'open-uri'

class WordsController < ApplicationController
  def game
    @grid = generate_grid(10)
  end

  def score
    @attempt = params[:attempt]
    @grid = params[:grid].split("")
    # Changer start et end time
    @end_time = Time.now
    @start_time = Time.parse(params[:start_time])

    api_url = 'http://api.wordreference.com/0.8/80143/json/enfr/' + @attempt

    defattempt = nil
    score = 0

    open(api_url) do |stream|
      sense = JSON.parse(stream.read)
      if sense.count > 2
        defattempt = sense['term0']['PrincipalTranslations']['0']['FirstTranslation']['term']
      end
    end

    if defattempt
      # si defattempt non nil tester les lettres. sinon pas la peine c'est pas bon.
      hashofattempt = arraytohashofletters(@attempt.upcase.split(""))

      hashofgrid = arraytohashofletters(@grid)

      # if attempt.upcase.split("").all? { |letter| grid.include?(letter) }
      if hashofattempt.all? { |key, value| hashofgrid[key] && value <= hashofgrid[key] }
        message = "Well done!"
        score = [(((@attempt.length.fdiv @grid.size) * 200) - (@end_time - @start_time)).round, 0].max
      else
        message = "Not in the grid!"
      end
    else
      message = "Not an english word!"
      defattempt = "nothing!"
    end


    @score = score
    @translation = defattempt
    @message = message

    if session[:number_of_attemps]
      session[:number_of_attemps] += 1
    else
      session[:number_of_attemps] = 0
    end
    @attemps = session[:number_of_attemps]

    if session[:allscores]
      session[:allscores] << @score.to_i
    else
      session[:allscores] = []
    end

    @allscores = session[:allscores].reverse
    @mean = (( session[:allscores].inject{ |sum, el| sum + el }.to_f ) / session[:allscores].size).round

  end

end




  private

  def generate_grid(grid_size)
    # TODO: generate random grid of letters

    grid = []

    grid_size.times do
      grid << [*'A'..'Z'].sample
    end

    return grid
  end

  # p generate_grid(4)

  def arraytohashofletters(array)
    hash = {}
    array.each do |letter|
      if hash[letter]
        hash[letter] += 1
      else
        hash[letter] = 1
      end
    end
    return hash
  end
