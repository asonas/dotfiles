#! /usr/bin/env ruby
# coding: utf-8
require "JSON"
require "open-uri"

class JojoAsbTrain
  STATION_HASH = {
    1 => "東京",
    2 => "有楽町",
    3 => "新橋",
    4 => "浜松町",
    5 => "田町",
    6 => "品川",
    7 => "大崎",
    8 => "五反田",
    9 => "目黒",
    10 => "恵比寿",
    11 => "渋谷",
    12 => "原宿",
    13 => "代々木",
    14 => "新宿",
    15 => "新大久保",
    16 => "高田馬場",
    17 => "目白",
    18 => "池袋",
    19 => "大塚",
    20 => "巣鴨",
    21 => "駒込",
    22 => "田端",
    23 => "西日暮里",
    24 => "日暮里",
    25 => "鶯谷",
    26 => "上野",
    27 => "御徒町",
    28 => "秋葉原",
    29 => "神田"
  }

  def initialize
    @data = JSON.parse open("http://jojoasbtrain.jp/api/getTrainInfo").read
    @message = @data["data"]["news"]
  end

  def where_are_you?
    if running?
      "現在%s付近を走行中ッ!!" % STATION_HASH[@data["data"]["station"].to_i]
    else
      @data["data"]["news"]
    end
  end

  private

  def running?
    @message =~ /走行中/? true : false
  end
end

jojo_train = JojoAsbTrain.new
puts jojo_train.where_are_you?
