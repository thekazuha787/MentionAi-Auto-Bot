#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'
require 'colorize'
require 'io/console'

# Load environment variables from .env file
Dotenv.load

# --- Configuration ---
BASE_URL = 'https://api.mention.network'
BACKEND_API_URL = 'https://backend.buildpicoapps.com/aero/run/llm-api?pk=v1-Z0FBQUFBQm5IZkJDMlNyYUVUTjIyZVN3UWFNX3BFTU85SWpCM2NUMUk3T2dxejhLSzBhNWNMMXNzZlp3c09BSTR6YW1Sc1BmdGNTVk1GY0liT1RoWDZZX1lNZlZ0Z1dqd3c9PQ=='
MAX_QUESTIONS = 15
MAX_RETRIES = 3
RETRY_DELAY_BASE = 10
DELAY_BETWEEN_CYCLES = 10
WAIT_TIME_HOURS = 24

# --- Banner ---
BANNER = <<~BANNER
 ███╗  ███╗███████╗███╗  ██╗████████╗██╗ ██████╗ ███╗  ██╗
 ████╗ ████║██╔════╝████╗ ██║╚══██╔══╝██║██╔═══██╗████╗ ██║
 ██╔████╔██║█████╗  ██╔██╗ ██║  ██║   ██║██║  ██║██╔██╗ ██║
 ██║╚██╔╝██║██╔══╝  ██║╚██╗██║  ██║   ██║██║  ██║██║╚██╗██║
 ██║ ╚═╝ ██║███████╗██║ ╚████║  ██║   ██║╚██████╔╝██║ ╚████║
 ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝  ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
BANNER

# --- Helper Functions ---
def clean_response(text)
  text.downcase.gsub(/\s+/, ' ').strip
end

def delay(seconds)
  sleep(seconds)
end

def display_banner
  puts BANNER.colorize(:magenta)
  puts '     LETS FUCK THIS TESTNET CREATED BY KAZUHA787      '.colorize(:magenta)
  puts '==========================================='.colorize(:magenta)
end

def ask_question(prompt)
  print prompt.colorize(:cyan)
  gets.chomp
end

def run_countdown(hours)
  seconds = hours * 3600
  while seconds > 0
    h = seconds / 3600
    m = (seconds % 3600) / 60
    s = seconds % 60
    print "\r" + "Waiting: #{h.to_s.rjust(2, '0')}:#{m.to_s.rjust(2, '0')}:#{s.to_s.rjust(2, '0')}".colorize(:yellow)
    sleep(1)
    seconds -= 1
  end
  puts "\r" + "Countdown finished. Resuming operations...".colorize(:green)
end

def spinner_message(message, status = :info)
  case status
  when :info
    print "[*] #{message}...".colorize(:cyan)
  when :success
    puts "\r[+] #{message}".colorize(:green)
  when :warning
    puts "\r[!] #{message}".colorize(:yellow)
  when :error
    puts "\r[-] #{message}".colorize(:red).bold
  end
end

# --- Accounts Loader ---
def load_accounts
  accounts = []
  idx = 1
  loop do
    token = ENV["AUTH_TOKEN_#{idx}"]
    user  = ENV["USER_ID_#{idx}"]
    break unless token && user
    accounts << { token: token, user_id: user.to_i }
    idx += 1
  end
  accounts
end

ACCOUNTS = load_accounts

# --- Account Pickers ---
def pick_random_account
  ACCOUNTS.sample
end

def pick_round_robin(cycle_count)
  ACCOUNTS[(cycle_count - 1) % ACCOUNTS.length]
end

# --- Core Functions ---
def fetch_questions(account)
  spinner_message("Fetching up to #{MAX_QUESTIONS} questions")
  
  uri = URI("#{BASE_URL}/questions/random-list")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Get.new(uri)
  request['accept'] = 'application/json'
  request['authorization'] = "Bearer #{account[:token]}"
  request['user-agent'] = 'Mozilla/5.0'
  
  begin
    response = http.request(request)
    data = JSON.parse(response.body)
    questions = data['data'] || []
    
    if questions.any?
      limited_questions = questions.first(MAX_QUESTIONS)
      spinner_message("Fetched #{limited_questions.length} questions", :success)
      return limited_questions.map { |q| { 'text' => q['text'] } }
    else
      spinner_message('No questions found', :warning)
      return []
    end
  rescue => e
    spinner_message("Failed to fetch questions: #{e.message}", :error)
    return []
  end
end

def ask_backend_ai(question_text, retry_count = 0)
  retry_msg = retry_count > 0 ? " (Retry #{retry_count})" : ""
  spinner_message("Generating AI response#{retry_msg}")
  
  uri = URI(BACKEND_API_URL)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = { prompt: question_text }.to_json
  
  begin
    response = http.request(request)
    
    if response.code == '429' && retry_count < MAX_RETRIES
      delay_seconds = RETRY_DELAY_BASE * (2 ** retry_count)
      spinner_message("Rate limit hit, retrying in #{delay_seconds}s", :warning)
      delay(delay_seconds)
      return ask_backend_ai(question_text, retry_count + 1)
    end
    
    data = JSON.parse(response.body)
    
    if data['status'] == 'success'
      text = clean_response(data['text'] || '')
      spinner_message('AI response generated', :success)
      return text
    else
      spinner_message("Backend did not return success", :warning)
      return ''
    end
  rescue => e
    spinner_message("Error asking backend: #{e.message}", :error)
    return ''
  end
end

def save_questions(questions)
  spinner_message('Saving questions')
  
  begin
    content = questions.map { |q| q['text'].strip }.join("\n") + "\n"
    File.write('questions.txt', content)
    spinner_message("Saved #{questions.length} questions to questions.txt", :success)
  rescue => e
    spinner_message("Failed to save questions: #{e.message}", :error)
    raise e
  end
end

def save_responses(responses)
  spinner_message('Saving responses')
  
  begin
    content = responses.map { |r| clean_response(r || '') }.join("\n") + "\n"
    File.write('response.txt', content)
    spinner_message("Saved #{responses.length} responses to response.txt", :success)
  rescue => e
    spinner_message("Failed to save responses: #{e.message}", :error)
    raise e
  end
end

def search_ai_model(query, account)
  spinner_message("Searching for model: #{query}")
  
  uri = URI("#{BASE_URL}/api/ai-models/search")
  uri.query = URI.encode_www_form({ query: query })
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{account[:token]}"
  
  begin
    response = http.request(request)
    model_data = JSON.parse(response.body)
    
    if model_data.is_a?(Hash)
      if model_data['data'] && model_data['data'].is_a?(Hash) && model_data['data']['data']
        data = model_data['data']['data']
      elsif model_data['data'] && model_data['data'].is_a?(Array)
        data = model_data['data']
      elsif model_data['success'] && model_data['data']
        data = model_data['data']
      else
        data = []
      end
      
      data = [data] unless data.is_a?(Array)
      
      if data.any? && data[0].is_a?(Hash) && data[0]['id']
        spinner_message("Model search successful: #{data[0]['id']}", :success)
        return data[0]['id']
      else
        spinner_message('No models found in response', :error)
        return nil
      end
    else
      spinner_message('Invalid model search response format', :error)
      return nil
    end
  rescue => e
    spinner_message("Error during model search: #{e.message}", :error)
    return nil
  end
end

def log_interaction(account, model_id, request_text, response_text, idx)
  uri = URI("#{BASE_URL}/interactions")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Post.new(uri)
  request['Authorization'] = "Bearer #{account[:token]}"
  request['Content-Type'] = 'application/json'
  
  payload = {
    userId: account[:user_id],
    modelId: model_id,
    requestText: request_text,
    responseText: clean_response(response_text || '')
  }
  
  request.body = payload.to_json
  
  begin
    # Display question and response
    truncated_question = request_text.length > 50 ? "#{request_text[0..49]}..." : request_text
    truncated_response = payload[:responseText].length > 80 ? "#{payload[:responseText][0..79]}..." : payload[:responseText]
    
    puts "\n[#{idx}] Q: #{truncated_question}".colorize(:blue).bold
    puts "    A: #{truncated_response}".colorize(:magenta)
    
    spinner_message("Submitting interaction #{idx}")
    response = http.request(request)
    data = JSON.parse(response.body)
    spinner_message('Submission successful', :success)
    puts "---".colorize(:yellow)
    return data
  rescue => e
    spinner_message("Error logging interaction: #{e.message}", :error)
    return nil
  end
end

def run_cycle(cycle_count, total_cycles, mode)
  # Pick an account for this cycle based on the mode
  account = mode == :round_robin ? pick_round_robin(cycle_count) : pick_random_account
  puts "\n[*] Using account USER_ID=#{account[:user_id]}".colorize(:yellow)
  
  puts "\n-----------------------------------------------------".colorize(:blue)
  puts "Starting Cycle ##{cycle_count}/#{total_cycles} | #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}".colorize(:blue)
  puts "-----------------------------------------------------".colorize(:blue)

  # Step 1: Fetch and save questions
  questions = fetch_questions(account)
  if questions.empty?
    puts '[-] No questions fetched. Skipping cycle.'.colorize(:red).bold
    return false
  end

  save_questions(questions)

  # Step 2: Generate and save AI responses
  responses = []
  puts "\n[*] Generating Responses".colorize(:blue).bold
  
  questions.each_with_index do |question, i|
    truncated = question['text'].length > 50 ? "#{question['text'][0..49]}..." : question['text']
    puts "[#{i + 1}/#{questions.length}] #{truncated}".colorize(:white)
    
    ai_response = ask_backend_ai(question['text'])
    responses << (ai_response || '')
    delay(6)
  end

  save_responses(responses)

  # Step 3: Submit questions and responses
  retrieved_model_id = search_ai_model('gpt-3-5', account)
  
  if retrieved_model_id
    puts "\n[*] Model ID: #{retrieved_model_id}".colorize(:blue).bold

    # Load questions and responses
    begin
      questions_text = File.read('questions.txt').split("\n").reject(&:empty?)
      puts "[+] Loaded #{questions_text.length} questions".colorize(:green)
    rescue => e
      puts "[-] 'questions.txt' not found.".colorize(:red).bold
      return false
    end

    begin
      responses_text = File.read('response.txt').split("\n").reject(&:empty?)
      puts "[+] Loaded #{responses_text.length} responses".colorize(:green)
    rescue => e
      puts "[-] 'response.txt' not found.".colorize(:red).bold
      return false
    end

    # Submit pairs
    pairs = [questions_text.length, responses_text.length].min
    
    if pairs == 0
      puts '[!] No matching question/response pairs to process.'.colorize(:yellow)
    else
      puts "\n[*] Submitting #{pairs} Interactions".colorize(:blue).bold
      
      pairs.times do |i|
        if responses_text[i] && !responses_text[i].empty?
          log_interaction(account, retrieved_model_id, questions_text[i], responses_text[i], i + 1)
        else
          puts "[!] Skipped: No valid response for interaction #{i + 1}".colorize(:yellow)
        end
        delay(1)
      end
      
      puts "\n[+] Cycle ##{cycle_count} completed successfully!".colorize(:green).bold
    end
  else
    puts '[-] Failed to retrieve model information.'.colorize(:red).bold
    return false
  end
  
  true
end

# --- Main Execution ---
begin
  display_banner

  if ACCOUNTS.empty?
    puts 'FATAL: No accounts found in .env file. Bot is stopping.'.colorize(:red).bold
    exit(1)
  end

  # Get user input for number of cycles
  total_cycles = nil
  while total_cycles.nil?
    input = ask_question('Enter the number of cycles to perform (e.g., 10): ')
    parsed_cycles = input.to_i
    if parsed_cycles > 0
      total_cycles = parsed_cycles
      puts "> Number of cycles set to #{total_cycles}.".colorize(:green)
    else
      puts '> Invalid input. Please enter a positive integer (e.g., 10).'.colorize(:red)
    end
  end
  
  # Get user input for mode
  mode = nil
  while mode.nil?
    input = ask_question('Select a mode (random or round-robin): ')
    if ['random', 'round-robin'].include?(input.downcase)
      mode = input.downcase.to_sym
      puts "> Mode set to #{mode}.".colorize(:green)
    else
      puts '> Invalid input. Please enter either "random" or "round-robin".'.colorize(:red)
    end
  end

  puts "> Wait time between full runs: #{WAIT_TIME_HOURS} hours.".colorize(:yellow)
  puts "> Connected to Mention API".colorize(:green)

  loop do
    (1..total_cycles).each do |cycle_count|
      begin
        success = run_cycle(cycle_count, total_cycles, mode)
        
        if cycle_count < total_cycles && success
          puts "\n[*] Waiting for #{DELAY_BETWEEN_CYCLES} seconds before the next cycle...".colorize(:cyan)
          delay(DELAY_BETWEEN_CYCLES)
          puts "[+] Wait complete. Starting next cycle.".colorize(:green)
        end
      rescue => e
        puts "\nERROR occurred during cycle ##{cycle_count}:".colorize(:red).bold
        puts "> Message: #{e.message}".colorize(:red)
        puts "> Retrying in 20 seconds...".colorize(:yellow)
        delay(20)
        redo
      end
    end
    
    puts "\n[+] All #{total_cycles} cycles completed successfully!".colorize(:green).bold
    puts "\n[*] Waiting for #{WAIT_TIME_HOURS} hours before restarting the process...".colorize(:cyan)
    run_countdown(WAIT_TIME_HOURS)
    puts "[+] Wait complete. Restarting process...".colorize(:green)
  end

rescue Interrupt
  puts "\n[!] Process interrupted by user. Exiting gracefully...".colorize(:yellow)
  exit(0)
rescue => e
  puts "\nFATAL ERROR: #{e.message}".colorize(:red).bold
  puts e.backtrace.join("\n").colorize(:red)
  exit(1)
end
