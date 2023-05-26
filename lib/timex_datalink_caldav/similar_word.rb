# frozen_string_literal: true

require "mdb"
require "text"  # import the text gem


class SimlarWord
    class WordNotFound < StandardError; end
    
    attr_accessor :database
    
    def initialize(database:)
        @database = database
    end
    
    def vocab_ids_for(*words)
        words.flat_map do |word|
            vocab = vocab_for_word(word)
            
            # If the word is not found, look for a similar sounding word
            if vocab.nil?
                word = find_similar_word(word)
                vocab = vocab_for_word(word)
            end
            
            raise(WordNotFound, "#{word} is not a valid word!") unless vocab
            
            vocab_links = vocab_links_for_vocab(vocab)
            
            vocab_links.map do |vocab_link|
                linked_vocab = vocab_for_vocab_link(vocab_link)
                
                linked_vocab[:"PC Index"].to_i
            end
        end
    end
    
    private
    
    def find_similar_word(word)
        word_metaphone = Text::Metaphone.double_metaphone(word)
      
        # Filter out words that start with '<' before finding the minimum distance
        filtered_vocab_table = vocab_table.reject { |vocab_word| vocab_word[:Label].start_with?('<') }
    
        similar_word = filtered_vocab_table.min_by do |vocab_word|
          distance = Text::Levenshtein.distance(
            Text::Metaphone.double_metaphone(vocab_word[:Label]).first, 
            word_metaphone.first
          )
          distance
        end
      
        if similar_word
            puts "Similar word for '#{word}' is '#{similar_word[:Label]}'"
            similar_word[:Label]
        else
            puts "No similar word found for '#{word}', using original word"
            word
        end
    end
    
    def mdb
        @mdb ||= Mdb.open(database)
    end
    
    def vocab_table
        @vocab_table ||= mdb["Vocab"]
    end
    
    def vocab_links_table
        @vocab_links_table ||= mdb["Vocab Links"]
    end
    
    def vocab_for_word(word)
        vocab_table.detect { |vocab| vocab[:Label].casecmp?(word) }
    end
    
    def vocab_links_for_vocab(vocab)
        links = vocab_links_table.select { |vocab_link| vocab_link[:"PC Index"] == vocab[:"PC Index"] }
        
        links.sort_by { |link| link[:Sequence].to_i }
    end
    
    def vocab_for_vocab_link(vocab_link)
        vocab_table.detect { |vocab| vocab[:"PC Index"] == vocab_link[:"eBrain Index"] }
    end
end
