# frozen_string_literal: true

if ENV["HISTFILE"]
  hist_dir = ENV["HISTFILE"].sub(/\/[^\/]+$/, "")
  IRB.conf[:SAVE_HISTORY] = 100
  IRB.conf[:HISTORY_FILE] = File.join(hist_dir, ".irb_history")
end
