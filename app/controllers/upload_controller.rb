class UploadController < ApplicationController
  before_filter :load_trie
  after_filter :save_trie
  before_filter :load_delta
  after_filter :save_delta
  before_filter :load_output_history
  after_filter :save_output_history
	
  def show
	@list_of_words = nilc
	render :file => 'app/views/upload/upload_file.html.erb'
  end
  def index
	@list_of_words = nil
	render :file => 'app/views/upload/upload_file.html.erb'
  end
  def create
    list_of_words = []
	$index = 0
	
	if params[:upload] and params[:upload]["datafile"]
		t1 = Time.now
		datafile = params[:upload]["datafile"].read
		@trie = create_trie(datafile)
		t2 = Time.now
		@delta = "%.2f" %(((t2 - t1).to_f)*1000)
		save_delta
	else
		@trie = load_trie
		@delta = load_delta
	end
	
	@anagrams = nil
	
	if params[:upload] and params[:upload]["search_word"]
		@output_history = load_output_history
		if (@output_history == 0)
			@output_history = []
		end
		search_word = params[:upload]["search_word"]
		t1 = Time.now
		@anagrams = search_for_anagrams(search_word, @trie, [])
		t2 = Time.now
		temp_history = []
		temp_history.push(Time.now.strftime("%F %r"))
		if @anagrams == [] or @anagrams == ""
			temp_history.push("0 anagrams found for '" + search_word + "' in %.2f" %(((t2-t1).to_f)*1000) + " ms")
		else
			temp_history.push(@anagrams.length.to_s + " anagrams found for '" + search_word + "' in %.2f" %(((t2-t1).to_f)*1000) + " ms")
			temp_history.push("> " + @anagrams.join(", "))
		end
		@output_history.push(temp_history)
		save_output_history
	
	end

	render 'app/views/upload/upload_file.html.erb', @trie => @trie, @delta => @delta, @output_history => @output_history

  end
  
  private
	def load_trie
      @trie = session[:trie] || 0
    end

    def save_trie
      session[:trie] = @trie
    end
	
	def load_delta
      @delta = session[:delta] || 0
    end

    def save_delta
      session[:delta] = @delta
    end
	
	def load_output_history
      @output_history = session[:output_history] || 0
    end

    def save_output_history
      session[:output_history] = @output_history
    end
  
end

def create_word_trie(rest, key = nil, initial = false)
    checked = false
    if not key or key.length == 1
        key = rest[0..0]
        rest = rest[1..-1]
        checked = true
    end
    if rest.length == 0
        $index += 1
        if initial
            return [key, $index]
        else
            return {key => $index}
        end
    end
    if not checked
        key = rest[0..0]
        rest = rest[1..-1]
    end
    if initial
        return [key, create_word_trie(rest, key, initial = false)]
    else
        return {key => create_word_trie(rest, key, initial = false)}
    end
end

def create_trie(text)
    list_of_words = text.strip.split
    trie = {}
    for word in list_of_words
        t = trie
        i = 0
        while i < word.length
            if not t.kind_of?(Hash)
                break
            elsif t.has_key?(word[i..i])
                t = t[word[i..i]]
                i += 1
            else
                temp_trie = create_word_trie(word[i..-1], key = nil, initial = true)
                t[temp_trie[0]] = temp_trie[1]
            end
        end
        if not i
            temp_trie = create_word_trie(word, key = nil, initial = true)
            trie[temp_trie[0]] = temp_trie[1]
        end
    end
    return trie
end

def search_for_anagrams(word, trie, current_word)
	list = []
    if trie.kind_of?(Integer)
        if word.length == 0
            return current_word.join
        end
        return
    end
    for letter in word.chars.to_a.uniq
        new_current_word = Array.new(current_word)
        if trie[letter]
            new_word = word
            new_word = new_word.sub(letter, "")
            new_current_word.push(letter)
            anagram = search_for_anagrams(new_word, trie[letter], new_current_word)
			if anagram and anagram.length != 0
				if anagram.kind_of?(String)
					list << anagram
				else
					list.concat(anagram)
				end
			end
        end
    end
	return list
end