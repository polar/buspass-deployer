require "heroku-headless"

module HerokuHeadless
  def self.reset
    @@heroku = nil
  end
end