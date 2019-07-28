require "cadmium"

text = File.read("test.txt")

def get_keywords(text, min_ratio = 0.001, max_ratio = 0.5)
  all_words = [] of String
  text.scan(/\b([a-z][a-z\-']*)\b/i).each do |match|
    word = match[0]
    all_words << word
  end

  number_of_words = all_words.size

  significant_words = Cadmium::PragmaticTokenizer.new(
    clean: true,
    remove_stop_words: true,
    punctuation: :none,
    downcase: true
  ).tokenize(text)

  frequencies = {} of String => Int32
  word_ratio = {} of String => Float64
  significant_words.each do |word|
    frequencies.has_key?(word) ? (frequencies[word] += 1) : (frequencies[word] = 1)
  end

  frequencies.keys.each do |word|
    ratio = frequencies[word].to_f / number_of_words
    word_ratio[word] = ratio unless (ratio < min_ratio || ratio > max_ratio)
  end

  word_ratio
end

# Gets sentence weight

def get_sentence_weight(sentence, keywords)
  words_in_sentence = sentence.split(' ')
  last_index = words_in_sentence.size - 1

  window_start = words_in_sentence.index { |word| keywords.includes?(word) }

  return 0 if window_start === nil

  window_end = words_in_sentence[last_index..0].index { |word| keywords.includes?(word) }

  return 0 if window_start.not_nil! > window_end.not_nil!

  window_size = window_end.not_nil! - 1 + window_start.not_nil!

  # Calculate number of keywords

  number_of_keywords = words_in_sentence.count { |word| keywords.includes?(word) }

  (number_of_keywords*number_of_keywords) / window_size
end

def summarize(text, max_num_sentences = 10)
  sentences = Cadmium::Util::Sentence.sentences(text)
  keywords = get_keywords(text)
  sentences.sort_by! { |sentence| -get_sentence_weight(sentence, keywords) }
  sentences[0..max_num_sentences].join("\n")
end

puts summarize(text, 5)
